//
//  DeviceClass.h
//  EnShare
//
//  Created by WeiJun on 2015/2/13.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddressConnector.h"
#import "UIDConnector.h"

typedef enum _prefType
{
    UNKNOWN_TYPE,
    ADDRESS_TYPE,
    DDNS_TYPE,
    UID_TYPE
}prefType;

@class DeviceClass;

@protocol deviceClassDelegate <NSObject>
-(void)finishLogin:(DeviceClass*)device Success:(BOOL)success Message:(NSString*)message;
@end

@interface DeviceClass : NSObject <NSCopying,HttpAPICommanderDelegate>{
    AddressConnector* httpsAddressConnector;
    UIDConnector* httpsUIDConnector;
    AddressConnector* httpAddressConnector;
    UIDConnector* httpUIDConnector;
}

-(id) init UNAVAILABLE_ATTRIBUTE;
+(id) new UNAVAILABLE_ATTRIBUTE;

+(id)sharedInstance;
-(void)destroySharedInstance;

@property (nonatomic,strong) id<deviceClassDelegate> delegate;

@property (nonatomic,strong) HttpAPICommander* currentCaller;

@property (nonatomic) prefType  connectPrefType;
@property (nonatomic,strong) NSString* scheme;

@property (nonatomic,strong) NSString* userName;
@property (nonatomic,strong) NSString* password;

@property (nonatomic,strong) NSString *uid;

@property (nonatomic,strong) NSString *deviceAddress;
@property (nonatomic) NSInteger httpAgentPort;
@property (nonatomic) NSInteger httpsAgentPort;
@property (nonatomic) NSInteger downloadPort;
@property (nonatomic) NSInteger uploadPort;

@property (nonatomic,strong) NSString *commandDeviceAddress;
@property (nonatomic) NSInteger commandHttpAgentPort;
@property (nonatomic) NSInteger commandHttpsAgentPort;
@property (nonatomic) NSInteger commandDownloadPort;
@property (nonatomic) NSInteger commandUploadPort;

@property (nonatomic) BOOL hadFWChecked;

@property (nonatomic,strong) NSString *modelName;
@property (nonatomic,strong) NSString* macAddress;
@property (nonatomic,strong) NSString *firmwareVersion;

@property (nonatomic) BOOL isAdminUser;
@property (nonatomic) BOOL isTunnelUsed;

typedef void (^InfoBlock)(NSString* address,int port);

@property (copy, nonatomic) InfoBlock downloadInfoBlock;
@property (copy, nonatomic) InfoBlock uploadInfoBloack;

-(void)doLoginWithAddress:(NSString*)address
                 UserName:(NSString*)username
                 Password:(NSString*)password
                   Scheme:(NSString*)scheme
                   Target:(id<deviceClassDelegate>)target;

-(void)doLoginWithUID:(NSString*)uid
                 UserName:(NSString*)username
                 Password:(NSString*)password
               Scheme:(NSString*)scheme
               Target:(id<deviceClassDelegate>)target;

-(void)stopLogin;

-(void)getDownloadInfo:(void (^)(NSString* address, int port))finishBlock;
-(void)getUploadInfo:(void (^)(NSString* address, int port))finishBlock;

-(NSString*)getDownloadUrl;
-(NSString*)getUploadUrl;

-(void)saveMasterConntectionDetail;

-(void)useMasterConntectionDetail;

-(void)useCurrentConntectionDetail;

-(void)resetMasterConntectionDetail;

@end
