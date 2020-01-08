//
//  RouterGlobal.m
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "RouterGlobal.h"
#import "ASIFormDataRequest.h"
#import "DataManager.h"
#import "dataDefine.h"
#import "AppDelegate.h"

@implementation RouterGlobal

-(void)getStorageInfo:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.storageInfoBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_STORAGE_INFO_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_STORAGE_INFO_CALLBACK                                                          Target:self];
}

-(void)getDeviceSettings:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.deviceSettingsBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_DEVICE_SETINGS_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_DEVICE_SETINGS_CALLBACK
                                                          Target:self];
}

-(void)getSystemInformation:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.systemInformationBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_SYSTEM_INFORMATION_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_SYSTEM_INFORMATION_CALLBACK
                                                          Target:self];
}

-(void)checkAlive:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.checkAliveBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:CHECK_ALIVE_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:CHECK_ALIVE_CALLBACK
                                                          Target:self];
}

-(void)renameFileInFileListWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.renameInFileListBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:RENAME_FILE_IN_FILE_LIST_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:RENAME_FILE_IN_FILE_LIST_CALLBACK
                                                          Target:self];
}

-(void)getWLanRadioSecurityWithRadioID:(NSString*)radioID CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.wlanRadioSecurityBlock = completeBlock;
    NSString *jsonString = [NSString stringWithFormat:@"{\"RadioID\":\"%@\",\"SSIDID\":\"%@\"}",radioID,@"1"];
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_WLAN_RADIO_SECURITY_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:GET_WLAN_RADIO_SECURITY_CALLBACK
                                                          Target:self];
}

-(void)getSystemThroughput:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.systemThroughputBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_SYSTEM_THROUGHPUT_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_SYSTEM_THROUGHPUT_CALLBACK
                                                          Target:self];
}

-(void)getWLanRadios:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.wlanRadiosBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_WLAN_RADIOS_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_WLAN_RADIOS_CALLBACK
                                                          Target:self];
}

-(void)getWLanRadioSettingsWithRadioID:(NSString*)radioID CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.wlanRadioSettingsBlock = completeBlock;
    NSString *jsonString = [NSString stringWithFormat:@"{\"RadioID\":\"%@\",\"SSIDID\":\"%@\"}",radioID,@"1"];
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_WLAN_RADIO_SETTINGS_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:GET_WLAN_RADIO_SETTINGS_CALLBACK
                                                          Target:self];
}

-(void)setWLanRadioSettingsWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.setWLanRadioSettingsBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:SET_WLAN_RADIO_SETTINGS_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:SET_WLAN_RADIO_SETTINGS_CALLBACK
                                                          Target:self];
}

-(void)setWLanRadioSecurityWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.setWLanRadioSecurityBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:SET_WLAN_RADIO_SECURITY_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:SET_WLAN_RADIO_SECURITY_CALLBACK
                                                          Target:self];
}

-(void)reboot:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.rebootBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:REBOOT_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:REBOOT_CALLBACK
                                                          Target:self];
}

-(void)getWanSettings:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.wanSettingsBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_WAN_SETTINGS_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_WAN_SETTINGS_CALLBACK
                                                          Target:self];
}

-(void)getLanSettings:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.lanSettingsBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_LAN_SETTINGS_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_LAN_SETTINGS_CALLBACK
                                                          Target:self];
}

-(void)getDeviceStatus:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.deviceStatusBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_DEVICE_STATUS_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_DEVICE_STATUS_CALLBACK
                                                          Target:self];
}

-(void)downloadDeviceConfigFile:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.deviceConfigFileBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:DOWNLOAD_DEVICE_CONFIG_FILE_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:DOWNLOAD_DEVICE_CONFIG_FILE_CALLBACK
                                                          Target:self];
}

-(void)getClientStatus:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.clientStatusBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_CLIENT_STATUS_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_CLIENT_STATUS_CALLBACK
                                                          Target:self];
}

-(void)getBlockedClientList:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.blockedClientListBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_BLOCKED_CLIENT_LIST_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_BLOCKED_CLIENT_LIST_CALLBACK
                                                          Target:self];
}

-(void)editBlockedClientListWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.editBlockedClientListBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:EDIT_BLOCKED_CLIENT_LIST_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:EDIT_BLOCKED_CLIENT_LIST_CALLBACK
                                                          Target:self];
}

-(void)deleteBlockedClientList:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.deleteBlockedClientListBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:DELETE_BLOCKED_CLIENT_LIST_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:DELETE_BLOCKED_CLIENT_LIST_CALLBACK
                                                          Target:self];
}

-(void)createFolderWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.createFolderBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:CREATE_FOLDER_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:CREATE_FOLDER_CALLBACK
                                                          Target:self];
}

-(void)addFileIntoPublicListWithJsonString:(NSString*)jsonString CompleteBlock:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.addFileIntoPublicListBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:ADD_FILE_INRO_PUBLIC_LIST_COMMAND
                                                          Method:@"POST"
                                                            Body:jsonString
                                                      CallbackID:ADD_FILE_INRO_PUBLIC_LIST_CALLBACK
                                                          Target:self];
}

-(void) getMeshNodeSimplifyInfo:(void (^)(NSDictionary* resultDictionary))completeBlock
{
    self.getMeshNodeSimplifyInfoBlock = completeBlock;
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GET_MESH_NODE_SIMPLIFY_INFO_COMMAND
                                                          Method:@"GET"
                                                            Body:nil
                                                      CallbackID:GET_MESH_NODE_SIMPLIFY_INFO_CALLBACK                                                          Target:self];
}

#pragma mark StaticHttpRequestDelegate
-(void)didFinishStaticRequestJSON:(NSDictionary *)strAckResult CommandIp:(NSString *)ip CommandPort:(int)port CallbackID:(NSUInteger)callback
{
    NSString *loginResult = [strAckResult objectForKey:@"LoginResult"];
    if(loginResult!=nil && [loginResult isEqualToString:@"ERROR"]){
        NSLog(@"backToLoginPage");
        [self backToLoginPage];
        return;
    }
    switch (callback) {
        case GET_STORAGE_INFO_CALLBACK:
        {
            if (self.storageInfoBlock) {
                self.storageInfoBlock(strAckResult);
            }
        }
            break;
        case GET_DEVICE_SETINGS_CALLBACK:
        {
            if (self.deviceSettingsBlock) {
                self.deviceSettingsBlock(strAckResult);
            }
        }
            break;
        case GET_SYSTEM_INFORMATION_CALLBACK:
        {
            if (self.systemInformationBlock) {
                self.systemInformationBlock(strAckResult);
            }
        }
            break;
        case CHECK_ALIVE_CALLBACK:
        {
            if (self.checkAliveBlock) {
                self.checkAliveBlock(strAckResult);
            }
        }
            break;
        case RENAME_FILE_IN_FILE_LIST_CALLBACK:
        {
            if (self.renameInFileListBlock) {
                self.renameInFileListBlock(strAckResult);
            }
        }
            break;
        case GET_WLAN_RADIO_SECURITY_CALLBACK:
        {
            if (self.wlanRadioSecurityBlock) {
                self.wlanRadioSecurityBlock(strAckResult);
            }
        }
            break;
        case GET_SYSTEM_THROUGHPUT_CALLBACK:
        {
            if (self.systemThroughputBlock) {
                self.systemThroughputBlock(strAckResult);
            }
        }
            break;
        case GET_WLAN_RADIOS_CALLBACK:
        {
            if (self.wlanRadiosBlock) {
                self.wlanRadiosBlock(strAckResult);
            }
        }
            break;
        case GET_WLAN_RADIO_SETTINGS_CALLBACK:
        {
            if (self.wlanRadioSettingsBlock) {
                self.wlanRadioSettingsBlock(strAckResult);
            }
        }
            break;
        case SET_WLAN_RADIO_SETTINGS_CALLBACK:
        {
            if (self.setWLanRadioSettingsBlock) {
                self.setWLanRadioSettingsBlock(strAckResult);
            }
        }
            break;
        case SET_WLAN_RADIO_SECURITY_CALLBACK:
        {
            if (self.setWLanRadioSecurityBlock) {
                self.setWLanRadioSecurityBlock(strAckResult);
            }
        }
            break;
        case REBOOT_CALLBACK:
        {
            if (self.rebootBlock) {
                self.rebootBlock(strAckResult);
            }
        }
            break;
        case GET_WAN_SETTINGS_CALLBACK:
        {
            if (self.wanSettingsBlock) {
                self.wanSettingsBlock(strAckResult);
            }
        }
            break;
        case GET_LAN_SETTINGS_CALLBACK:
        {
            if (self.lanSettingsBlock) {
                self.lanSettingsBlock(strAckResult);
            }
        }
            break;
        case GET_DEVICE_STATUS_CALLBACK:
        {
            if (self.deviceStatusBlock) {
                self.deviceStatusBlock(strAckResult);
            }
        }
            break;
        case DOWNLOAD_DEVICE_CONFIG_FILE_CALLBACK:
        {
            if (self.deviceConfigFileBlock) {
                self.deviceConfigFileBlock(strAckResult);
            }
        }
            break;
        case GET_CLIENT_STATUS_CALLBACK:
        {
            if (self.clientStatusBlock) {
                self.clientStatusBlock(strAckResult);
            }
        }
            break;
        case GET_BLOCKED_CLIENT_LIST_CALLBACK:
        {
            if (self.blockedClientListBlock) {
                self.blockedClientListBlock(strAckResult);
            }
        }
            break;
        case EDIT_BLOCKED_CLIENT_LIST_CALLBACK:
        {
            if (self.editBlockedClientListBlock) {
                self.editBlockedClientListBlock(strAckResult);
            }
        }
            break;
        case DELETE_BLOCKED_CLIENT_LIST_CALLBACK:
        {
            if (self.deleteBlockedClientListBlock) {
                self.deleteBlockedClientListBlock(strAckResult);
            }
        }
            break;
        case CREATE_FOLDER_CALLBACK:
        {
            if (self.createFolderBlock) {
                self.createFolderBlock(strAckResult);
            }
        }
            break;
        case ADD_FILE_INRO_PUBLIC_LIST_CALLBACK:
        {
            if (self.addFileIntoPublicListBlock) {
                self.addFileIntoPublicListBlock(strAckResult);
            }
        }
            break;
        case GET_MESH_NODE_SIMPLIFY_INFO_CALLBACK:
        {
            if (self.getMeshNodeSimplifyInfoBlock) {
                self.getMeshNodeSimplifyInfoBlock(strAckResult);
            }
        }
            break;
        default:
            break;
    }
}

-(void)failToStaticRequestWithErrorCode:(NSInteger)iFailStatus description:(NSString *)desc callbackID:(NSUInteger)callback
{
    switch (callback) {
        case GET_STORAGE_INFO_CALLBACK:
        {
            if (self.storageInfoBlock) {
                self.storageInfoBlock(nil);
            }
        }
            break;
        case GET_DEVICE_SETINGS_CALLBACK:
        {
            if (self.deviceSettingsBlock) {
                self.deviceSettingsBlock(nil);
            }
        }
            break;
        case GET_SYSTEM_INFORMATION_CALLBACK:
        {
            if (self.systemInformationBlock) {
                self.systemInformationBlock(nil);
            }
        }
            break;
        case CHECK_ALIVE_CALLBACK:
        {
            if (self.checkAliveBlock) {
                self.checkAliveBlock(nil);
            }
        }
            break;
        case RENAME_FILE_IN_FILE_LIST_CALLBACK:
        {
            if (self.renameInFileListBlock) {
                self.renameInFileListBlock(nil);
            }
        }
            break;
        case GET_WLAN_RADIO_SECURITY_CALLBACK:
        {
            if (self.wlanRadioSecurityBlock) {
                self.wlanRadioSecurityBlock(nil);
            }
        }
            break;
        case GET_SYSTEM_THROUGHPUT_CALLBACK:
        {
            if (self.systemThroughputBlock) {
                self.systemThroughputBlock(nil);
            }
        }
            break;
        case GET_WLAN_RADIOS_CALLBACK:
        {
            if (self.wlanRadiosBlock) {
                self.wlanRadiosBlock(nil);
            }
        }
            break;
        case GET_WLAN_RADIO_SETTINGS_CALLBACK:
        {
            if (self.wlanRadioSettingsBlock) {
                self.wlanRadioSettingsBlock(nil);
            }
        }
            break;
        case SET_WLAN_RADIO_SETTINGS_CALLBACK:
        {
            if (self.setWLanRadioSettingsBlock) {
                self.setWLanRadioSettingsBlock(nil);
            }
        }
            break;
        case SET_WLAN_RADIO_SECURITY_CALLBACK:
        {
            if (self.setWLanRadioSecurityBlock) {
                self.setWLanRadioSecurityBlock(nil);
            }
        }
            break;
        case REBOOT_CALLBACK:
        {
            if (self.rebootBlock) {
                self.rebootBlock(nil);
            }
        }
            break;
        case GET_WAN_SETTINGS_CALLBACK:
        {
            if (self.wanSettingsBlock) {
                self.wanSettingsBlock(nil);
            }
        }
            break;
        case GET_LAN_SETTINGS_CALLBACK:
        {
            if (self.lanSettingsBlock) {
                self.lanSettingsBlock(nil);
            }
        }
            break;
        case GET_DEVICE_STATUS_CALLBACK:
        {
            if (self.deviceStatusBlock) {
                self.deviceStatusBlock(nil);
            }
        }
            break;
        case DOWNLOAD_DEVICE_CONFIG_FILE_CALLBACK:
        {
            if (self.deviceConfigFileBlock) {
                self.deviceConfigFileBlock(nil);
            }
        }
            break;
        case GET_CLIENT_STATUS_CALLBACK:
        {
            if (self.clientStatusBlock) {
                self.clientStatusBlock(nil);
            }
        }
            break;
        case GET_BLOCKED_CLIENT_LIST_CALLBACK:
        {
            if (self.blockedClientListBlock) {
                self.blockedClientListBlock(nil);
            }
        }
            break;
        case EDIT_BLOCKED_CLIENT_LIST_CALLBACK:
        {
            if (self.editBlockedClientListBlock) {
                self.editBlockedClientListBlock(nil);
            }
        }
            break;
        case DELETE_BLOCKED_CLIENT_LIST_CALLBACK:
        {
            if (self.deleteBlockedClientListBlock) {
                self.deleteBlockedClientListBlock(nil);
            }
        }
            break;
        case CREATE_FOLDER_CALLBACK:
        {
            if (self.createFolderBlock) {
                self.createFolderBlock(nil);
            }
        }
            break;
        case ADD_FILE_INRO_PUBLIC_LIST_CALLBACK:
        {
            if (self.addFileIntoPublicListBlock) {
                self.addFileIntoPublicListBlock(nil);
            }
        }
            break;
        case GET_MESH_NODE_SIMPLIFY_INFO_CALLBACK:
        {
            if (self.getMeshNodeSimplifyInfoBlock) {
                self.getMeshNodeSimplifyInfoBlock(nil);
            }
        }
            break;
        default:
            break;
    }
}

-(void)backToLoginPage{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [navController dismissViewControllerAnimated:YES completion:nil];
}

@end
