//
//  StaticHttpRequest.m
//  EnShare
//
//  Created by WeiJun on 2015/2/13.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "StaticHttpRequest.h"
#import "dataDefine.h"
#import "AFHTTPRequestOperation.h"
#import "PJTunnel.h"
#import "DeviceClass.h"
#import "Reachability.h"

static id master = nil;

@implementation StaticHttpRequest{
    BOOL downloading;
}

+(id)sharedInstance
{
    if (!master) {
        master = [self alloc];
        master = [master init];
        NSLog(@"StaticHttpRequest Got New!!");
    }
    return master;
}

-(id)init{
    if ((self = [super init])) {
        targetDictionary = [NSMutableDictionary dictionary];
        requestQueue = [[NSOperationQueue alloc] init];
#ifdef smalink
        [[PJTunnel sharedInstance] setAppAesKeyType:2];
#endif
#ifdef MESSHUDrive
        [[PJTunnel sharedInstance] setAppAesKey:@"$~FuJitsU!^ApP&#sErViCe?@"];
#endif
    }
    return self;
}

-(void)sleepWithTimeInterval:(double)seconds Function:(const char *)_function Line:(int)_line File:(char *)_file{
    //NSLog(@"\n Function: %s\n Line: %d\n File: %s\n Interval: %f(s)",_function, _line, _file, seconds);
    [NSThread sleepForTimeInterval:seconds];
}

-(void)doLoginRequestWithUrl:(NSString *)url Body:(NSString *)body CallbackID:(NSUInteger)callback Target:(id<StaticHttpRequestDelegate>)target{
    NSString* URL = nil;
    if ([url hasPrefix:@"://"]) {
        URL = [NSString stringWithFormat:@"https%@",url];
    }else{
        URL = [NSString stringWithString:url];
    }
    
    NSURL* requestURL = [NSURL URLWithString:URL];
    
    if ([requestURL.scheme isEqualToString:@"http"]) {
        [self doJsonHttpRequestWithUrl:URL
                                Method:@"POST"
                                  Body:body
                            CallbackID:callback
                                Scheme:@"http"
                            RetryCount:0
                                Target:target];
    }else{
        [self doJsonHttpsRequestWithUrl:URL
                                 Method:@"POST"
                                   Body:body
                             CallbackID:callback
                                 Scheme:@"https"
                             RetryCount:0
                                 Target:target];
    }
}

-(void)doJsonRequestWithCommand:(NSString *)command Method:(NSString *)method Body:(NSString *)body CallbackID:(NSUInteger)callback Target:(id<StaticHttpRequestDelegate>)target
{
    NSString* URL = nil;
    DeviceClass* tmpDevie = [DeviceClass sharedInstance];
    NSString* scheme = tmpDevie.scheme;
    
    NSLog(@"[Command]:%@", command);
    
    if ([scheme isEqualToString:@"http"]) {
        URL = [NSString stringWithFormat:@"http://%@:%d/json/%@",tmpDevie.commandDeviceAddress,tmpDevie.commandHttpAgentPort,command];
        [self doJsonHttpRequestWithUrl:URL
                                Method:method
                                  Body:body
                            CallbackID:callback
                                Scheme:@"http"
                            RetryCount:0
                                Target:target];
    }else{
        URL = [NSString stringWithFormat:@"https://%@:%d/json/%@",tmpDevie.commandDeviceAddress,tmpDevie.commandHttpsAgentPort,command];
        [self doJsonHttpsRequestWithUrl:URL
                                 Method:method
                                   Body:body
                             CallbackID:callback
                                 Scheme:@"https"
                             RetryCount:0
                                 Target:target];
    }
}

-(void)doJsonHttpsRequestWithUrl:(NSString *)url Method:(NSString *)method Body:(NSString *)body CallbackID:(NSUInteger)callback Scheme:(NSString*)scheme RetryCount:(int)retryCount Target:(id<StaticHttpRequestDelegate>)target
{
    if (!targetDictionary) {
        NSLog(@"Request Stop!!");
        return;
    }
    
    NSURL* requestURL = [NSURL URLWithString:url];
    requestURL = [self changeURL:requestURL withScheme:scheme];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:TIMEOUT_INTERVAL];
//    if (callback == GENERATE_FILE_LIST_BY_TYPE_CALLBACK) {
//        request.timeoutInterval = LONG_TIMEOUT_INTERVAL;
//    }
    
    NSLog(@"StaticeHttpRequest URL:%@ - %d",requestURL,requestQueue.operationCount);
    
    [targetDictionary setObject:target forKey:[NSString stringWithFormat:@"%@-%d",requestURL,callback]];
    
    if (body && [method isEqualToString:@"POST"]) {
        NSData* postData = [body dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:postData];
    }
    
    [request setHTTPMethod:method];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    op.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain", nil];
//    op.securityPolicy.allowInvalidCertificates = YES;
    
    AFSecurityPolicy* policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setValidatesDomainName:NO];
    [policy setAllowInvalidCertificates:YES];
    op.securityPolicy = policy;
    
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,callback]]) {
            NSLog(@"%@ Response String : %@",requestURL,responseObject);
            if ([target respondsToSelector:@selector(didFinishStaticRequestJSON:CommandIp:CommandPort:CallbackID:)]) {
                [target didFinishStaticRequestJSON:responseObject
                                         CommandIp:requestURL.host
                                       CommandPort:[requestURL.port intValue]
                                        CallbackID:callback];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,callback]]) {
            NSLog(@"%@ Response Error  %@",requestURL,error);
            if (retryCount < CONNECT_RETRY_COUNT) {
                [self doJsonHttpsRequestWithUrl:url
                                         Method:method
                                           Body:body
                                     CallbackID:callback
                                         Scheme:scheme
                                     RetryCount:retryCount+1
                                         Target:target];
            }else{
                if ([target respondsToSelector:@selector(failToStaticRequestWithErrorCode:description:callbackID:)]) {
                    [target failToStaticRequestWithErrorCode:error.code description:error.localizedDescription callbackID:callback];
                }
            }
        }
    }];
    
    [op setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        NSURL* redirectURL = [request URL];
         if (!(!redirectURL || ([redirectURL.host isEqualToString:requestURL.host] && [redirectURL.port integerValue]==[requestURL.port integerValue])))
         {
             NSLog(@"Redirect %@ to %@",requestURL,redirectURL);
             [connection cancel];
             connection = nil;
             [self doJsonHttpsRequestWithUrl:[redirectURL absoluteString]
                                      Method:method
                                        Body:body
                                  CallbackID:callback
                                      Scheme:scheme
                                  RetryCount:retryCount
                                      Target:target];
             return nil;
         }
        return request;
    }];
    
    [requestQueue addOperation:op];
}

-(void)doJsonHttpRequestWithUrl:(NSString *)url Method:(NSString *)method Body:(NSString *)body CallbackID:(NSUInteger)callback Scheme:(NSString*)scheme RetryCount:(int)retryCount Target:(id<StaticHttpRequestDelegate>)target
{
    if (!targetDictionary) {
        NSLog(@"Request Stop!!");
        return;
    }
    
    NSURL* requestURL = [NSURL URLWithString:url];
    requestURL = [self changeURL:requestURL withScheme:scheme];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:TIMEOUT_INTERVAL];
    
//    if (callback == GENERATE_FILE_LIST_BY_TYPE_CALLBACK) {
//        request.timeoutInterval = LONG_TIMEOUT_INTERVAL;
//    }
    
    NSLog(@"StaticeHttpRequest URL:%@ - %d",requestURL,requestQueue.operationCount);
    
    [targetDictionary setObject:target forKey:[NSString stringWithFormat:@"%@-%d",requestURL,callback]];
    
    if (body && [method isEqualToString:@"POST"]) {
        @synchronized ([PJTunnel sharedInstance]) {
            NSString* encrptedBody = [[PJTunnel sharedInstance] getEncryptedString:body];
            [request setHTTPBody:[encrptedBody dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    [request setHTTPMethod:method];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFHTTPResponseSerializer serializer];
    op.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain", nil];
    op.securityPolicy.allowInvalidCertificates = YES;
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,callback]]) {
            NSLog(@"%@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            NSString* decryptedString = nil;
            @synchronized ([PJTunnel sharedInstance]) {
                decryptedString = [[PJTunnel sharedInstance] getDecryptedString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
            }
            NSRange range = [decryptedString rangeOfString:@"}" options:NSBackwardsSearch];
            if(range.location != NSNotFound)
                decryptedString = [decryptedString substringWithRange:NSMakeRange(0,range.location+1)];
             NSData *data = [decryptedString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* json = nil;
            if (data) {
                NSError* error;
                json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            }else{
                json = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            }
            if (!json) {
                NSLog(@"Check");
            }
            NSLog(@"%@ Response String : %@",requestURL,json);
            if ([target respondsToSelector:@selector(didFinishStaticRequestJSON:CommandIp:CommandPort:CallbackID:)]) {
                [target didFinishStaticRequestJSON:json
                                         CommandIp:requestURL.host
                                       CommandPort:[requestURL.port intValue]
                                        CallbackID:callback];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,callback]]) {
            NSLog(@"%@ Response Error  %@",requestURL,error);
            if (retryCount < CONNECT_RETRY_COUNT) {
                [self doJsonHttpRequestWithUrl:url
                                        Method:method
                                          Body:body
                                    CallbackID:callback
                                        Scheme:scheme
                                    RetryCount:retryCount+1
                                        Target:target];
            }else{
                if ([target respondsToSelector:@selector(failToStaticRequestWithErrorCode:description:callbackID:)]) {
                    [target failToStaticRequestWithErrorCode:error.code description:error.localizedDescription callbackID:callback];
                }
            }
        }
    }];
    
    [op setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        NSURL* redirectURL = [request URL];
        if (!(!redirectURL || ([redirectURL.host isEqualToString:requestURL.host] && [redirectURL.port integerValue]==[requestURL.port integerValue])))
        {
            NSLog(@"Redirect %@ to %@",requestURL,redirectURL);
            [connection cancel];
            connection = nil;
            [self doJsonHttpRequestWithUrl:[redirectURL absoluteString]
                                     Method:method
                                       Body:body
                                 CallbackID:callback
                                     Scheme:scheme
                                 RetryCount:retryCount
                                     Target:target];
            return nil;
        }
        return request;
    }];
    
    [requestQueue addOperation:op];
}

-(NSURL*)changeURL:(NSURL*)_url withScheme:(NSString*)_scheme{
    if ([_url.scheme isEqualToString:_scheme]) {
        return _url;
    }
    
    NSString* str = [_url absoluteString];
    NSInteger colon = [str rangeOfString:@":"].location;
    if (colon != NSNotFound) {
        str = [str substringFromIndex:colon];
        str = [_scheme stringByAppendingString:str];
    }
    
    return [NSURL URLWithString:str];
}

- (NSString*)detect3GWifi{
    NSString *tag;
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    if(status == NotReachable){
        tag = @"NO";
    }else if (status == ReachableViaWiFi){
        tag = @"WiFi";
    }else if (status == ReachableViaWWAN){
        tag = @"3G";
    }
    return tag;
}

-(void)checkNewFirmwareWithModel:(NSString *)_model Version:(NSString *)_version CompleteBlock:(void (^)(NSDictionary *))completeBlock{
    self.checkFirmwareBlock = completeBlock;
    
    NSString* postBody = nil;
    if (_version) {
        postBody = [NSString stringWithFormat:@"model=%@&type=router&ver=v%@",_model,_version];
    }else{
        postBody = [NSString stringWithFormat:@"model=%@&type=router",_model];
    }
    
    NSURL* requestURL = [NSURL URLWithString:@"http://home.engeniusnetworks.com/epg/lastfwlist.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:15];
    NSLog(@"StaticeHttpRequest URL:%@\n%@",requestURL,postBody);
    
    NSData *postData = [postBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    [request setHTTPMethod:@"POST"];
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    op.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain", nil];
    op.securityPolicy.allowInvalidCertificates = YES;
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Check Firmware Response : %@",responseObject);
        self.checkFirmwareBlock(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Check Firmware error : %@",error);
        self.checkFirmwareBlock(nil);
    }];
    
    [op start];
}

+(id)initWithUIName:(NSString *)uiName{
    
}

-(void)doDownloadtoPath:(NSString *)_path url:(NSString *)_url callbackID:(NSUInteger)_callback target:(id<StaticHttpRequestDelegate>)_target{
    if (!targetDictionary) {
        NSLog(@"Request Stop!!");
        return;
    }
    
    NSURL* requestURL = [NSURL URLWithString:_url];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    NSLog(@"StaticeHttpRequest URL:%@",requestURL);
    
    [targetDictionary setObject:_target forKey:[NSString stringWithFormat:@"%@-%d",requestURL,_callback]];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.outputStream = [NSOutputStream outputStreamToFileAtPath:_path append:YES];
    downloading = YES;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully downloaded %@ to %@",responseObject, _path);
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,_callback]]) {
            if ([_target respondsToSelector:@selector(didFinishStaticRequestJSON:callbackID:)]) {
                [_target didFinishStaticRequestJSON:responseObject CommandIp:requestURL.host CommandPort:[requestURL.port intValue] CallbackID:_callback];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,_callback]]) {
            if (downloading && [_target respondsToSelector:@selector(failToStaticRequestWithErrorCode:description:callbackID:)]) {
                [_target failToStaticRequestWithErrorCode:error.code description:error.localizedDescription callbackID:_callback];
            }
        }
    }];
    
    [op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"bytesRead: %d, totalBytesRead: %lld, totalBytesExpected: %lld", bytesRead, totalBytesRead, totalBytesExpectedToRead);
        if (targetDictionary && [targetDictionary objectForKey:[NSString stringWithFormat:@"%@-%d",requestURL,_callback]]) {
            if ([_target respondsToSelector:@selector(updateProgressWithTotalBytesRead:TotalBytesExpectedToRead:)]) {
                [_target updateProgressWithTotalBytesRead:totalBytesRead TotalBytesExpectedToRead:totalBytesExpectedToRead];
            }
        }
    }];
    
        [requestQueue addOperation:op];
}

-(void)stopDownload{
    downloading = NO;
    if ([requestQueue operationCount] > 0) {
        [requestQueue cancelAllOperations];
    }
}

-(void)destroySharedInstance{
    master = nil;
    targetDictionary = nil;
    if ([requestQueue operationCount] > 0) {
        [requestQueue cancelAllOperations];
    }
}

@end
