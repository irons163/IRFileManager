//
//  HttpAPICommander.h
//  EnShare
//
//  Created by WeiJun on 2015/2/13.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    HTTP_API_ADDRESS=0
    ,HTTP_API_EnGeniusDDNS=1
    ,HTTP_API_UID=2
} HttpAPICommanderType;

typedef enum
{
    CONNECTION_FAILED,
    CONNECTION_SUCCESS
}ConnectionResult;

@class HttpAPICommander;

@protocol HttpAPICommanderDelegate <NSObject>
@optional
-(void) didLoginResult:(ConnectionResult) result caller:(HttpAPICommander *) caller info:(NSDictionary *) LoginInfo address:(NSString *) strAddress port:(NSInteger) commandPort;
-(void) didGetDownloadIndo:(NSString*)address Port:(int)port;
-(void) didGetUploadIndo:(NSString*)address Port:(int)port;
@end

@interface HttpAPICommander : NSObject

@property (nonatomic,strong) id<HttpAPICommanderDelegate>delegate;
@property (nonatomic) BOOL stopConnection;
@property (nonatomic,strong) NSString* address;
@property (nonatomic,strong) NSString* downloadAddress;
@property (nonatomic,strong) NSString* uploadAddress;
@property (nonatomic,strong) NSString* userName;
@property (nonatomic,strong) NSString* password;
@property (nonatomic,strong) NSString* uid;
@property (nonatomic,strong) NSString* scheme;
@property (nonatomic) NSInteger commandPort;
@property (nonatomic) NSInteger downloadCommandPort;
@property (nonatomic) NSInteger uploadCommandPort;

-(id) initWithAddress:(NSString *) strIP port:(NSInteger) port user:(NSString *) user pwd :(NSString *) pwd scheme:(NSString*)scheme;
-(id) initWithUID:(NSString *) strUID port:(NSInteger) port user:(NSString *) user pwd :(NSString *) pwd scheme:(NSString*)scheme;

-(void) getDownloadInfo;
-(void) getUplaodInfo;

-(NSString*)getDownloadUrl;
-(NSString*)getUploadUrl;

@end
