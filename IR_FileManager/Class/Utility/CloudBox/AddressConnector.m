         //
//  AddressConnector.m
//  EnShare
//
//  Created by sniApp on 2015/2/15.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "AddressConnector.h"
#import "dataDefine.h"

@implementation AddressConnector

-(void)startLoginToDevice{
    if (self.stopConnection) {
        return;
    }
    
    NSString *strCmd = [NSString stringWithFormat:LOGIN_URL
                        ,self.scheme
                        ,self.address
                        ,self.commandPort
                        ];
    
    NSLog(@"[addressConnector login] %@", strCmd);
    
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

-(void)getDownloadInfo{
    if (self.downloadCommandPort >0 && self.downloadAddress) {
        [self.delegate didGetDownloadIndo:self.downloadAddress Port:self.downloadCommandPort];
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getRedirectDownloadPort];
            [self.delegate didGetDownloadIndo:self.downloadAddress Port:self.downloadCommandPort];
        });
    }
}

-(void)getUplaodInfo{
    if (self.uploadCommandPort > 0 && self.uploadAddress) {
        [self.delegate didGetUploadIndo:self.uploadAddress Port:self.uploadCommandPort];
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getRedirectUploadPort];
            [self.delegate didGetUploadIndo:self.uploadAddress Port:self.uploadCommandPort];
        });
    }
}

-(NSString*)getDownloadUrl{
    return [NSString stringWithFormat:@"%@:%d",self.downloadAddress,self.downloadCommandPort];
}

-(NSString*)getUploadUrl{
    return [NSString stringWithFormat:@"%@:%d",self.uploadAddress,self.uploadCommandPort];
}

//當router為雙層架構，取得下載與上傳的URL
- (void)getRedirectDownloadPort{
    NSURL* downloadUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d",self.address,DOWNLOAD_PORT]];
    NSURL* redirectDownloadUrl = [self getRedirectURL:downloadUrl];
    self.downloadAddress = redirectDownloadUrl.host;
    self.downloadCommandPort = [redirectDownloadUrl.port integerValue];
}

-(void)getRedirectUploadPort{
    NSURL* uploadUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d",self.address,UPLOAD_PORT]];
    NSURL* redirectUploadUrl = [self getRedirectURL:uploadUrl];
    self.uploadAddress = redirectUploadUrl.host;
    self.uploadCommandPort = [redirectUploadUrl.port integerValue];
}

- (NSURL*)getRedirectURL:(NSURL*)url{
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    NSHTTPURLResponse *response;
    [NSURLConnection sendSynchronousRequest:requestObj returningResponse:&response error:nil];
    return [response URL];
}

#pragma mark StaticHttpRequestDelegate

-(void)didFinishStaticRequestJSON:(NSDictionary*)strAckResult CommandIp:(NSString *)ip CommandPort:(int)port CallbackID:(NSUInteger)callback
{
    if (self.stopConnection) {
        return;
    }
    
    if (callback == LOGIN_CALLBACK) {
        if ([strAckResult objectForKey:LOGIN_ACKTAG]) {
            if (!self.stopConnection && [self.delegate respondsToSelector:@selector(didLoginResult:caller:info:address:port:)])
            {
                if (![self.address isEqualToString:ip] || self.commandPort != port) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self getRedirectDownloadPort];
                        [self getRedirectUploadPort];
                    });
                }else{
                    self.downloadAddress = [[NSString alloc] initWithString:ip];
                    self.downloadCommandPort = DOWNLOAD_PORT;
                    self.uploadAddress = [[NSString alloc] initWithString:ip];
                    self.uploadCommandPort = UPLOAD_PORT;
                }
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

-(void)failToStaticRequestWithErrorCode:(NSInteger)iFailStatus description:(NSString *)desc callbackID:(NSUInteger)callback
{
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
