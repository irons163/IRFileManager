//
//  IPFinderByUDP.m
//  udpbroadcast
//
//  Created by sniApp on 13/3/21.
//  Copyright (c) 2013年 sniApp. All rights reserved.
//

#import "IPFinderByUDP.h"

//#define FirstHeader  0x53 //S
//#define SecondHeader 0x43 //C
#ifdef MESSHUDrive
#define FirstHeader  0x46 //F
#define SecondHeader 0x4A //J
#else
#define FirstHeader  0x45 //E
#define SecondHeader 0x47 //G
#endif
#define RepeatCount  2

@implementation IPFinderByUDP
@synthesize mBroadcastSock;
@synthesize delegate;
@synthesize m_blnRepeat;
@synthesize m_SleepTime;

-(void)dealloc{
    if (sendTimer) {
        [sendTimer invalidate];
        sendTimer = nil;
    }
}

-(id) initFinderWithDelegate:(id) _IPFinderByUDPDelegate IsRepeat:(BOOL) _blnRepeat waiting:(NSInteger) _waitingTime
{
    m_UDPHeader[0] = FirstHeader;
    m_UDPHeader[1] = SecondHeader;
    m_UDPHeader[2] = 0x00;
    m_UDPHeader[3] = arc4random() % 255;
    m_UDPHeader[4] = arc4random() % 255;
//    m_UDPHeader[3] = 0xff;
//    m_UDPHeader[4] = 0xff;
    m_blnStop = NO;
    self.delegate = _IPFinderByUDPDelegate;
    self.m_blnRepeat = _blnRepeat;
    self.m_SleepTime = _waitingTime;
    
    [self initSocket];
    return self;
}

-(void) initSocket
{
    if(self.mBroadcastSock)
    {
        [self stopFindDeviceByUDP];
        self.mBroadcastSock = nil;
    }
    
    self.mBroadcastSock = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err;
    if([self.mBroadcastSock enableBroadcast:YES error:&err])
    {
        if([self.mBroadcastSock bindToPort:10000 error:&err])
        {
            NSLog(@"fail:%@",[err description]);
            if (![self.mBroadcastSock beginReceiving:&err])
            {
                NSLog(@"fail:%@",[err description]);
                self.mBroadcastSock = nil;
            }
        }
        else
        {
            self.mBroadcastSock = nil;
        }
    }
    else
    {
        NSLog(@"error code  dddddd=%@",[err localizedDescription]);
        self.mBroadcastSock=nil;
    }
    
    [NSThread sleepForTimeInterval:1.0f];

}

-(void) startfindDeviceByUDP
{
    m_blnStop = NO;
    if (sendTimer) {
        [sendTimer invalidate];
        sendTimer = nil;
    }
    [NSThread detachNewThreadSelector:@selector(createUDPSock) toTarget:self withObject:nil];
}

-(void) createUDPSock
{
    while (self.mBroadcastSock == nil)
    {
        [self initSocket];
        [NSThread sleepForTimeInterval:0.5f];
    }
    
    [NSThread detachNewThreadSelector:@selector(sendData) toTarget:self withObject:nil];
}

-(void) sendData
{
    iCount = 0;
    NSLog(@"send udp post=%@",m_blnStop ? @"YES" : @"NO");
    if (self.mBroadcastSock && !m_blnStop)
    {
        [self doSendData:nil];
    }
}

-(void)doSendData:(NSTimer*)timer{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if(!self.m_blnRepeat || iCount > (RepeatCount - 1) || m_blnStop)
    {
        if (sendTimer) {
            [sendTimer invalidate];
            sendTimer = nil;
        }
        if (!m_blnStop) {
            if ([self.delegate respondsToSelector:@selector(didFinishFind)]) {
                [self.delegate didFinishFind];
            }
        }
        return;
    }
    
    m_UDPHeader[3] = arc4random() % 255;
    m_UDPHeader[4] = arc4random() % 255;
    //        NSLog(@"%02x%02x",m_UDPHeader[3] ,m_UDPHeader[4]);
    
    NSLog(@"UDPHeader ==> %s(%zd)",m_UDPHeader,iCount);
    
    NSData *tmpData = [[NSData alloc] initWithBytes:m_UDPHeader length:sizeof(m_UDPHeader)];
    
    if(self.mBroadcastSock)
        [self.mBroadcastSock sendData:tmpData toHost:@"255.255.255.255" port:10000 withTimeout:-1 tag:1];
    
    iCount++;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        sendTimer = [NSTimer scheduledTimerWithTimeInterval:m_SleepTime
                                                     target:self
                                                   selector:@selector(doSendData:)
                                                   userInfo:nil
                                                    repeats:NO];
    });
}

-(void) stopFindDeviceByUDP
{
    m_blnStop = YES;
    if (sendTimer) {
        [sendTimer invalidate];
        sendTimer = nil;
    }
    [self.mBroadcastSock close];
    [self.mBroadcastSock setDelegate:nil];
    self.mBroadcastSock = nil;
}


#pragma CGDAsyncUdpSocket delegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
	
    Byte* tmpPtr = (Byte*)[data bytes];
    
    NSLog(@"receive data len=%zd",[data length]);
    
    if([data length] > 5)
    {
        if(tmpPtr[0] == FirstHeader && tmpPtr[1] == SecondHeader && tmpPtr[2] == 0X01)
        {//1. check by start code
            Byte iCheckSum = 0;
            
            for(int i = 7 ; i < [data length] -2 ; i++)
            {
                iCheckSum += tmpPtr[i];
            }
            
            NSLog(@"%u ,%u",iCheckSum ,tmpPtr[[data length]-1]);
            if(iCheckSum == tmpPtr[[data length] -1])
            {//2. check by checksum
                NSMutableDictionary *objSearchResult = [[NSMutableDictionary alloc] init];
                //3. get name and ip address
                NSData *tmpData = [NSData dataWithBytes:tmpPtr + 7 length:[data length] -8];
                //NSString *msg = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
                NSString *msg = [NSString stringWithUTF8String:[tmpData bytes]];
                NSArray *aryAckData = [msg componentsSeparatedByString:@","];
                NSLog(@"receive data = %zd ,%@" ,[data length] ,msg);
                
                for (NSString __strong*tmpDataInAck in aryAckData)
                {
                    NSArray *aryData = nil;
                    
                    tmpDataInAck = [tmpDataInAck stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    tmpDataInAck = [tmpDataInAck stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    aryData = [tmpDataInAck componentsSeparatedByString:@"="];
                    
                    [objSearchResult setObject:[aryData objectAtIndex:1] forKey:[aryData objectAtIndex:0]];
                }
                
                NSString *strModel = nil;
                NSString *strFwVer = nil;
                NSString *strIP = nil;
                NSString *strMac = nil;
                NSString *strMeshID = nil;
                
                if([objSearchResult valueForKey:@"model"])
                    strModel = [NSString stringWithFormat:@"%@",[objSearchResult valueForKey:@"model"]];
                
                if([objSearchResult valueForKey:@"fwver"])
                    strFwVer = [NSString stringWithFormat:@"%@",[objSearchResult valueForKey:@"fwver"]];

                if([objSearchResult valueForKey:@"ipaddr"])
                    strIP = [NSString stringWithFormat:@"%@",[objSearchResult valueForKey:@"ipaddr"]];
                
                if([objSearchResult valueForKey:@"macaddr"])
                    strMac = [NSString stringWithFormat:@"%@",[objSearchResult valueForKey:@"macaddr"]];
                
                if ([objSearchResult valueForKey:@"mesh_id"]) {
                    strMeshID = [NSString stringWithFormat:@"%@",[objSearchResult valueForKey:@"mesh_id"]];
                }
                
                if(strMeshID != nil && strIP != nil)
                {
                    [self.delegate didUDPFindDeviceIP:strIP
                                            fwVersion:strFwVer
                                          deviceModel:strModel
                                              macAddr:strMac
                                               meshID:strMeshID
                                              message:[msg copy]];
                }
                
                objSearchResult = nil;
            }
        }
    }
}

@end
