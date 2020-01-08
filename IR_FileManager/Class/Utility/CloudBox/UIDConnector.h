//
//  UIDConnector.h
//  EnShare
//
//  Created by WeiJun on 2015/2/24.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "HttpAPICommander.h"
#import "StaticHttpRequest.h"
#import "PJTunnel.h"

@interface UIDConnector : HttpAPICommander<StaticHttpRequestDelegate,PJTunnelDelegate>
{
    int tunnel_errorCode;
    int tunnel_retry;
    int last_tunnel_retry;
    BOOL isLocal;
}

-(void) startLoginToDevice;

@end
