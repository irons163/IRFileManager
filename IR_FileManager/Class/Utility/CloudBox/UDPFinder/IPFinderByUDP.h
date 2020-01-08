//
//  IPFinderByUDP.h
//  udpbroadcast
//
//  Created by sniApp on 13/3/21.
//  Copyright (c) 2013年 sniApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

@protocol IPFinderByUDPDelegate <NSObject>

-(void) didUDPFindDeviceIP:(NSString *) _strIPAddr
                 fwVersion:(NSString*) _fwVersion
               deviceModel:(NSString *) _deviceModel
                   macAddr:(NSString*) _macAddress
                    meshID:(NSString*)_meshID
                   message:(NSString*)msg;
@optional
-(void)didFinishFind;

@end

@interface IPFinderByUDP : NSObject<GCDAsyncUdpSocketDelegate>
{
    id<IPFinderByUDPDelegate> delegate;
@private
    BOOL        m_blnRepeat;
    BOOL        m_blnStop;
    NSInteger   m_SleepTime;
    u_int8_t    m_UDPHeader[5];
    NSTimer     *sendTimer;
    NSInteger   iCount;
}

@property (nonatomic ,strong) GCDAsyncUdpSocket *mBroadcastSock;
@property (nonatomic ,retain) id<IPFinderByUDPDelegate> delegate;
@property (nonatomic) BOOL m_blnRepeat;
@property (nonatomic) NSInteger m_SleepTime;

-(id) initFinderWithDelegate:(id) _IPFinderByUDPDelegate IsRepeat:(BOOL) _blnRepeat waiting:(NSInteger) _waitingTime;
-(void) startfindDeviceByUDP;
-(void) stopFindDeviceByUDP;


@end
