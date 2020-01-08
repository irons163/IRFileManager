//
//  StaticHttpRequest.h
//  EnShare
//
//  Created by WeiJun on 2015/2/13.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StaticHttpRequestDelegate<NSObject>
@optional
- (void) didFinishStaticRequestJSON:(NSDictionary*) strAckResult CommandIp:(NSString*)ip CommandPort:(int)port CallbackID:(NSUInteger) callback;
- (void) failToStaticRequestWithErrorCode:(NSInteger) iFailStatus description:(NSString*) desc callbackID:(NSUInteger) callback;
- (void) updateProgressWithTotalBytesRead:(long long)_totalBytesRead TotalBytesExpectedToRead:(long long)_totalBytesExpectedToRead;
@end

@interface StaticHttpRequest : NSObject{
    NSMutableDictionary* targetDictionary;
    NSOperationQueue* requestQueue;
}

@property (copy,nonatomic) void (^checkFirmwareBlock)(NSDictionary* resultDictionary);

-(id) init UNAVAILABLE_ATTRIBUTE;
+(id) new UNAVAILABLE_ATTRIBUTE;

+(id)sharedInstance;

+(id)initWithUIName:(NSString*)uiName;

-(void)doLoginRequestWithUrl:(NSString*)url Body:(NSString*)body CallbackID:(NSUInteger)callback Target:(id<StaticHttpRequestDelegate>)target;

-(void)doJsonRequestWithCommand:(NSString*)command Method:(NSString*)method Body:(NSString*)body CallbackID:(NSUInteger)callback Target:(id<StaticHttpRequestDelegate>)target;

-(void)sleepWithTimeInterval:(double)seconds Function:(const char*)_function Line:(int)_line File:(char*)_file;

- (NSString*)detect3GWifi;

-(void)checkNewFirmwareWithModel:(NSString *)_model Version:(NSString *)_version CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;

-(void)doDownloadtoPath:(NSString *)_path url:(NSString *)_url callbackID:(NSUInteger)_callback target:(id<StaticHttpRequestDelegate>)_target;

-(void)stopDownload;

-(void)destroySharedInstance;

@end
