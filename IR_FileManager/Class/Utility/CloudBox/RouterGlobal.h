//
//  RouterGlobal.h
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StaticHttpRequest.h"

@interface RouterGlobal : NSObject<StaticHttpRequestDelegate>

//- (id)init:(NSString*)IP;
//- (NSDictionary*)HttpRequest:(NSString*)command jsonString:(NSString*)jsonString method:(NSString*)method;
//- (NSDictionary*)getRadioInfo;
//- (NSDictionary*)getSSID:(NSString*)radioID;
//- (NSDictionary*)getEncryption:(NSString*)radioID;
//- (NSArray*)getSystemThroughput;


typedef void (^GetBlock)(NSDictionary* resultDictionary);

@property (copy,nonatomic) GetBlock storageInfoBlock;
@property (copy,nonatomic) GetBlock deviceSettingsBlock;
@property (copy,nonatomic) GetBlock systemInformationBlock;
@property (copy,nonatomic) GetBlock checkAliveBlock;
@property (copy,nonatomic) GetBlock renameInFileListBlock;
@property (copy,nonatomic) GetBlock wlanRadioSecurityBlock;
@property (copy,nonatomic) GetBlock systemThroughputBlock;
@property (copy,nonatomic) GetBlock wlanRadiosBlock;
@property (copy,nonatomic) GetBlock wlanRadioSettingsBlock;
@property (copy,nonatomic) GetBlock setWLanRadioSettingsBlock;
@property (copy,nonatomic) GetBlock setWLanRadioSecurityBlock;
@property (copy,nonatomic) GetBlock rebootBlock;
@property (copy,nonatomic) GetBlock wanSettingsBlock;
@property (copy,nonatomic) GetBlock lanSettingsBlock;
@property (copy,nonatomic) GetBlock deviceStatusBlock;
@property (copy,nonatomic) GetBlock deviceConfigFileBlock;
@property (copy,nonatomic) GetBlock clientStatusBlock;
@property (copy,nonatomic) GetBlock blockedClientListBlock;
@property (copy,nonatomic) GetBlock editBlockedClientListBlock;
@property (copy,nonatomic) GetBlock deleteBlockedClientListBlock;
@property (copy,nonatomic) GetBlock createFolderBlock;
@property (copy,nonatomic) GetBlock addFileIntoPublicListBlock;
@property (copy,nonatomic) GetBlock getMeshNodeSimplifyInfoBlock;

-(void)getStorageInfo:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getDeviceSettings:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getSystemInformation:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)checkAlive:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)renameFileInFileListWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getWLanRadioSecurityWithRadioID:(NSString*)radioID CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getSystemThroughput:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getWLanRadios:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getWLanRadioSettingsWithRadioID:(NSString*)radioID CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)setWLanRadioSettingsWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)setWLanRadioSecurityWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)reboot:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getWanSettings:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getLanSettings:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getDeviceStatus:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)downloadDeviceConfigFile:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getClientStatus:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getBlockedClientList:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)editBlockedClientListWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)deleteBlockedClientList:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)createFolderWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)addFileIntoPublicListWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock;
-(void)getMeshNodeSimplifyInfo:(void (^)(NSDictionary* resultDictionary))completeBlock;
@end
