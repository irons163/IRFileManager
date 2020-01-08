//
//  UIDConnector.m
//  EnShare
//
//  Created by WeiJun on 2015/2/24.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "UIDConnector.h"
#import "dataDefine.h"

@implementation UIDConnector

-(void)startLoginToDevice{
    if (self.stopConnection) {
        return;
    }
    
    [[PJTunnel sharedInstance] setTunnelDebug:0];
    [[PJTunnel sharedInstance] setLocalTunnelIgnore:YES];
    
#ifdef MESSHUDrive
    [[PJTunnel sharedInstance] setRelayConfig:@"130.211.250.189" User:@"admin" Pass:@"admin"];
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self openCommandPort];
    });
}

-(void)getDownloadInfo{
    if (isLocal) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self openDownloadPort];
    });
}

-(void)getUplaodInfo{
    if (isLocal) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self openUploadPort];
    });
}

-(NSString*)getDownloadUrl{
    return [NSString stringWithFormat:@"%@:%d",self.downloadAddress,self.downloadCommandPort];
}

-(NSString*)getUploadUrl{
    return [NSString stringWithFormat:@"%@:%d",self.uploadAddress,self.uploadCommandPort];
}

-(void)loginToDevice{
    if (self.stopConnection) {
        return;
    }
    
    NSString *strCmd = [NSString stringWithFormat:LOGIN_URL
                        ,self.scheme
                        ,self.address
                        ,self.commandPort
                        ];
    
    NSLog(@"[UIDConnector login] %@", strCmd);
    
    NSMutableDictionary *objLogin = [[NSMutableDictionary alloc] initWithCapacity:2];
    [objLogin setValue:self.userName forKey:@"AdminUsername"];
    [objLogin setValue:self.password forKey:@"AdminPassword"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:objLogin
                                                       options:0
                                                         error:nil];
    
    NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    
    [[StaticHttpRequest sharedInstance] doLoginRequestWithUrl:strCmd
                                                         Body:JSONString
                                                   CallbackID:LOGIN_CALLBACK
                                                       Target:self];
}

#pragma mark OpenTunnel

-(void)openCommandPort{
    NSLog(@"openCommandPort ,UID=%@", self.uid);
    
    if (self.stopConnection) {
        return;
    }
    
    int commandPort = HTTPS_APP_AGENT_PORT;
    
    if ([self.scheme isEqualToString:@"http"]) {
        commandPort = HTTP_APP_AGENT_PORT;
    }
    
    if ([self openTunnel:self.uid :commandPort]) {
        [self loginToDevice];
    }else{
        [self.delegate didLoginResult:CONNECTION_FAILED
                               caller:self
                                 info:nil
                              address:self.address
                                 port:self.commandPort];
    }
}

-(void)openDownloadPort{
    NSLog(@"openDownloadPort ,UID=%@", self.uid);
    
    if (self.stopConnection) {
        return;
    }
    
    if ([self openTunnel:self.uid :DOWNLOAD_PORT]) {
        [self.delegate didGetDownloadIndo:self.downloadAddress Port:self.downloadCommandPort];
    }else{
        [self.delegate didGetDownloadIndo:nil Port:-1];
    }
}

-(void)openUploadPort{
    NSLog(@"openUploadPort ,UID=%@", self.uid);
    
    if (self.stopConnection) {
        return;
    }
    
    if ([self openTunnel:self.uid :UPLOAD_PORT]) {
        [self.delegate didGetUploadIndo:self.uploadAddress Port:self.uploadCommandPort];
    }else{
        [self.delegate didGetUploadIndo:nil Port:-1];
    }
}

- (BOOL)openTunnel:(NSString*)uid :(int)port{
    NSLog(@"Start %@ - %d tunnel",uid,port);
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
        return NO;
    }
    
    if ([[PJTunnel sharedInstance] getTunnelLocalPort:uid Port:port] > 0) {
        NSInteger tmpMappedPort = [[PJTunnel sharedInstance] getTunnelLocalPort:uid Port:port];
        if (port == HTTPS_APP_AGENT_PORT)
        {
            self.address = @"127.0.0.1";
            self.commandPort = tmpMappedPort;
        }
        else if (port == HTTP_APP_AGENT_PORT){
            self.address = @"127.0.0.1";
            self.commandPort = tmpMappedPort;
        }
        else if (port == DOWNLOAD_PORT)
        {
            self.downloadAddress = @"127.0.0.1";
            self.downloadCommandPort = tmpMappedPort;
        }
        else if (port == UPLOAD_PORT)
        {
            self.uploadAddress = @"127.0.0.1";
            self.uploadCommandPort = tmpMappedPort;
        }else
        {
            NSLog(@"!!!Unknow Port!!!");
        }
        return YES;
    }
    
    if (self.stopConnection) {
        return NO;
    }
    tunnel_errorCode = -1;
    tunnel_retry = 0;
    last_tunnel_retry = tunnel_retry;
    
    NSArray* portsArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:HTTPS_APP_AGENT_PORT],
                           [NSNumber numberWithInt:HTTP_APP_AGENT_PORT],
                           [NSNumber numberWithInt:DOWNLOAD_PORT],
                           [NSNumber numberWithInt:UPLOAD_PORT], nil];
    
    if (![[PJTunnel sharedInstance] startTunnelWithPause:uid Ports:portsArray Delay:800 KeepAlive:YES SymmGuess:YES Target:self PauseUs:1000]) {
        while (tunnel_retry < CONNECT_RETRY_COUNT) {
            if (tunnel_errorCode == 12)
            {
                [[StaticHttpRequest sharedInstance] sleepWithTimeInterval:2.0f Function:__func__ Line:__LINE__ File:__FILE__];
            }
            else if (tunnel_errorCode ==-1  ||
                     tunnel_errorCode == 3  ||
                     tunnel_errorCode == 10 ||
                     tunnel_errorCode == 11 ||
                     tunnel_errorCode == 8  ||
                     tunnel_errorCode == 7  ||
                     tunnel_errorCode == 9  ||
                     tunnel_errorCode == 13)
            {
                
            }
            else if (tunnel_errorCode == 5 || tunnel_errorCode == 6)
            {
#if ConnectionType
                [DataManager sharedInstance].connectionType = @"UID(Local)";
#endif
                return YES;
            }
            else
            {
                return NO;
            }
            if (self.stopConnection) {
                return NO;
            }
            if (last_tunnel_retry == tunnel_retry) {
                NSLog(@"**************Tunnel Library is busy open %d UID %@ waiting.......", port,uid);
                [[StaticHttpRequest sharedInstance] sleepWithTimeInterval:2.0f Function:__func__ Line:__LINE__ File:__FILE__];
                NSLog(@"**************open %d UID %@ start.......",port,uid);
            }
            
            if ([[PJTunnel sharedInstance] getTunnelLocalPort:uid Port:port] > 0) {
                NSInteger tmpMappedPort = [[PJTunnel sharedInstance] getTunnelLocalPort:uid Port:port];
                if (port == HTTPS_APP_AGENT_PORT)
                {
                    self.address = @"127.0.0.1";
                    self.commandPort = tmpMappedPort;
                }
                else if (port == HTTP_APP_AGENT_PORT){
                    self.address = @"127.0.0.1";
                    self.commandPort = tmpMappedPort;
                }
                else if (port == DOWNLOAD_PORT)
                {
                    self.downloadAddress = @"127.0.0.1";
                    self.downloadCommandPort = tmpMappedPort;
                }
                else if (port == UPLOAD_PORT)
                {
                    self.uploadAddress = @"127.0.0.1";
                    self.uploadCommandPort = tmpMappedPort;
                }
                else
                {
                    NSLog(@"!!!Unknow Port!!!");
                }
                return YES;
            }
            
            if (self.stopConnection) {
                return NO;
            }
            
            NSLog(@"Reopen %@-%d tunnel count : %d",uid,port,tunnel_retry+1);
            last_tunnel_retry = tunnel_retry;
            if ([[PJTunnel sharedInstance] startTunnelWithPause:uid Ports:portsArray Delay:800 KeepAlive:YES SymmGuess:YES Target:self PauseUs:1000]) {
                return YES;
            }
        }
        return NO;
    }else{
        return YES;
    }
}

#pragma mark PJTunnelDelegate
-(void)pjTunnelResponse:(tunnelState)state UID:(NSString *)uid ErrorCode:(int)errCode Message:(NSString *)msg Port:(int)port MapPort:(int)MapPort HasTurn:(BOOL)hasTurn
{
    NSLog(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~UID:%@ tunnelState:%u port:%d -> %d Error Code: %d Message:%@ HasTurn:%d",uid ,state, port, MapPort, errCode,msg,hasTurn);
    tunnel_errorCode = errCode;
    tunnel_retry++;
    isLocal = NO;
    switch (state) {
        case tunnelConnected:
        {
            if ([self.scheme isEqualToString:@"http"]) {
                self.address = @"127.0.0.1";
                self.commandPort = MapPort+1;
            }else{
                self.address = @"127.0.0.1";
                self.commandPort = MapPort;
            }
            
            self.downloadAddress = @"127.0.0.1";
            self.downloadCommandPort = MapPort+2;
            
            self.uploadAddress = @"127.0.0.1";
            self.uploadCommandPort = MapPort+3;
        }
            break;
        case tunnelBroken:
        {
            self.address = nil;
            self.commandPort = -1;
            
            self.downloadAddress = nil;
            self.downloadCommandPort = -1;
            
            self.uploadAddress = nil;
            self.uploadCommandPort = -1;
        }
            break;
        case tunnelDisconnected:
        {
            self.address = nil;
            self.commandPort = -1;
            
            self.downloadAddress = nil;
            self.downloadCommandPort = -1;
            
            self.uploadAddress = nil;
            self.uploadCommandPort = -1;
        }
            break;
        case tunnelIgnored:
        {
            isLocal = YES;
            if ([self.scheme isEqualToString:@"http"]) {
                self.address = msg;
                self.commandPort = HTTP_APP_AGENT_PORT;
            }else{
                self.address = msg;
                self.commandPort = HTTPS_APP_AGENT_PORT;
            }
            
            self.downloadAddress = msg;
            self.downloadCommandPort = DOWNLOAD_PORT;
            
            self.uploadAddress = msg;
            self.uploadCommandPort = UPLOAD_PORT;
        }
            break;
        default:
            break;
    }
}

#pragma mark StaticHttpRequestDelegate
-(void)didFinishStaticRequestJSON:(NSDictionary *)strAckResult CommandIp:(NSString *)ip CommandPort:(int)port CallbackID:(NSUInteger)callback{
    if (self.stopConnection) {
        return;
    }
    
    if (callback == LOGIN_CALLBACK) {
        if ([strAckResult objectForKey:LOGIN_ACKTAG]) {
            if (!self.stopConnection && [self.delegate respondsToSelector:@selector(didLoginResult:caller:info:address:port:)])
            {
                [self.delegate didLoginResult:CONNECTION_SUCCESS
                                       caller:self
                                         info:strAckResult
                                      address:ip
                                         port:port];
            }
        }else{
            [self failToStaticRequestWithErrorCode:-1 description:[strAckResult description] callbackID:callback];
        }
    }
}

-(void)failToStaticRequestWithErrorCode:(NSInteger)iFailStatus description:(NSString *)desc callbackID:(NSUInteger)callback{
    if (self.stopConnection) {
        return;
    }
    
    [self.delegate didLoginResult:CONNECTION_FAILED
                           caller:self
                             info:nil
                          address:self.address
                             port:self.commandPort];
}

@end
