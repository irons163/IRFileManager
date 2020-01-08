//
//  DeviceClass.m
//  EnShare
//
//  Created by WeiJun on 2015/2/13.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "DeviceClass.h"
#import "dataDefine.h"
#import "DataManager.h"

#define MixDdnsUid 0
//#define HTTPSONLY

static id master = nil;
static id serverDevice = nil; //server(master mesh) router detail
static id tmpDevice = nil;

@implementation DeviceClass

+(id)sharedInstance
{
    if (!master) {
        master = [self alloc];
        master = [master init];
    }
    return master;
}

-(id)init{
    self = [super init];
    
    if (self) {
        NSLog(@"DeviceClass Got New");
        
        _delegate = nil;
        
        _currentCaller = nil;
        
        _connectPrefType = UNKNOWN_TYPE;
        _scheme = @"";
        
        _userName = @"";
        _password = @"";
        
        _uid = @"";
        
        _deviceAddress = @"";
        _httpAgentPort = HTTP_APP_AGENT_PORT;
        _httpsAgentPort = HTTPS_APP_AGENT_PORT;
        _downloadPort = DOWNLOAD_PORT;
        _uploadPort = UPLOAD_PORT;
        
        _commandDeviceAddress = @"";
        _commandHttpAgentPort = HTTP_APP_AGENT_PORT;
        _commandHttpsAgentPort = HTTPS_APP_AGENT_PORT;
        _commandDownloadPort = DOWNLOAD_PORT;
        _commandUploadPort = UPLOAD_PORT;
        
        _hadFWChecked = NO;
        _modelName = @"";
        _macAddress = @"";
        _firmwareVersion = nil;
        
        _isAdminUser = NO;
        _isTunnelUsed = NO;
    }
    return self;
}

-(void)destroySharedInstance{
    master = nil;
    tmpDevice = nil;
}

-(void)dealloc{
    NSLog(@"DeviceClass Got Dealoc");
}

-(id)copyWithZone:(NSZone *)zone{
    id copy = [[[self class] alloc] init];
    if (copy) {
        [copy setCurrentCaller:self.currentCaller];
        
        [copy setConnectPrefType:self.connectPrefType];
        [copy setScheme:[self.scheme copyWithZone:zone]];
        
        [copy setUserName:[self.userName copyWithZone:zone]];
        [copy setPassword:[self.password copyWithZone:zone]];
        
        [copy setUid:[self.uid copyWithZone:zone]];
        
        [copy setDeviceAddress:[self.deviceAddress copyWithZone:zone]];
        [copy setHttpAgentPort:self.httpAgentPort];
        [copy setHttpsAgentPort:self.httpsAgentPort];
        [copy setDownloadPort:self.downloadPort];
        [copy setUploadPort:self.uploadPort];
        
        [copy setCommandDeviceAddress:[self.commandDeviceAddress copyWithZone:zone]];
        [copy setCommandHttpAgentPort:self.commandHttpAgentPort];
        [copy setCommandHttpsAgentPort:self.commandHttpsAgentPort];
        [copy setCommandDownloadPort:self.commandDownloadPort];
        [copy setCommandUploadPort:self.commandUploadPort];
        
        [copy setHadFWChecked:self.hadFWChecked];
        
        [copy setModelName:[self.modelName copyWithZone:zone]];
        
        [copy setMacAddress:[self.macAddress copyWithZone:zone]];
        
        [copy setFirmwareVersion:[self.firmwareVersion copyWithZone:zone]];
        
        [copy setIsAdminUser:self.isAdminUser];
        [copy setIsTunnelUsed:self.isTunnelUsed];
    }
    return copy;
}

-(void)doLogin{
    if (self.connectPrefType == UNKNOWN_TYPE) {
        if ([self.uid length] > 0) {
#if MixDdnsUid
            self.connectPrefType = [self getPrefTypeFromCache];
#else
            self.connectPrefType = UID_TYPE;
#endif
        }else{
            self.connectPrefType = ADDRESS_TYPE;
        }
    }
    
#ifdef HTTPSONLY
    self.scheme = @"https";
#endif
    
    if ([self.scheme isEqualToString:@"http"]) {
        [self doHttpLogin];
    }else{
        [self doHttpsLogin];
    }
}

-(void)doLoginWithAddress:(NSString *)address UserName:(NSString *)username Password:(NSString *)password Scheme:(NSString *)scheme Target:(id<deviceClassDelegate>)target{
    self.deviceAddress = [[NSString alloc] initWithString:address];
    self.userName = [[NSString alloc] initWithString:username];
    self.password = [[NSString alloc] initWithString:password];
    self.scheme = [[NSString alloc] initWithString:scheme];
    self.delegate = target;
    [self doLogin];
}

-(void)doLoginWithUID:(NSString *)uid UserName:(NSString *)username Password:(NSString *)password Scheme:(NSString *)scheme Target:(id<deviceClassDelegate>)target{
    self.uid = [[NSString alloc] initWithString:uid];
    self.userName = [[NSString alloc] initWithString:username];
    self.password = [[NSString alloc] initWithString:password];
    self.scheme = [[NSString alloc] initWithString:scheme];
    self.delegate = target;
    [self doLogin];
}

-(void)doHttpsLogin{
    httpsAddressConnector = nil;
    httpsUIDConnector = nil;
    if ([self.uid length] > 0) {
        if (!httpsAddressConnector) {
            httpsAddressConnector = [[AddressConnector alloc] initWithAddress:[NSString stringWithFormat:@"%@.engeniusddns.com",self.uid]
                                                                         port:HTTPS_APP_AGENT_PORT
                                                                         user:self.userName
                                                                          pwd:self.password
                                                                       scheme:@"https"];
            httpsAddressConnector.delegate =self;
        }
        
        if (!httpsUIDConnector) {
            httpsUIDConnector = [[UIDConnector alloc] initWithUID:self.uid
                                                             port:HTTPS_APP_AGENT_PORT
                                                             user:self.userName
                                                              pwd:self.password
                                                           scheme:@"https"];
            httpsUIDConnector.delegate = self;
        }
    }else{
        if (!httpsAddressConnector) {
            httpsAddressConnector = [[AddressConnector alloc] initWithAddress:self.deviceAddress
                                                                         port:HTTPS_APP_AGENT_PORT
                                                                         user:self.userName
                                                                          pwd:self.password
                                                                       scheme:@"https"];
            httpsAddressConnector.delegate = self;
        }
        httpsUIDConnector = nil;
    }
    
    [self startHttpsLogin];
}

-(void)doHttpLogin{
    httpAddressConnector = nil;
    httpUIDConnector = nil;
    if ([self.uid length] > 0) {
        if (!httpAddressConnector) {
            httpAddressConnector = [[AddressConnector alloc] initWithAddress:[NSString stringWithFormat:@"%@.engeniusddns.com",self.uid]
                                                                        port:HTTP_APP_AGENT_PORT
                                                                        user:self.userName
                                                                         pwd:self.password
                                                                      scheme:@"http"];
            httpAddressConnector.delegate = self;
        }
        
        if (!httpUIDConnector) {
            httpUIDConnector = [[UIDConnector alloc] initWithUID:self.uid
                                                            port:HTTP_APP_AGENT_PORT
                                                            user:self.userName
                                                             pwd:self.password
                                                          scheme:@"http"];
            httpUIDConnector.delegate = self;
        }
    }else{
        if (!httpAddressConnector) {
            httpAddressConnector = [[AddressConnector alloc] initWithAddress:self.deviceAddress
                                                                        port:HTTP_APP_AGENT_PORT
                                                                        user:self.userName
                                                                         pwd:self.password
                                                                      scheme:@"http"];
            httpAddressConnector.delegate = self;
        }
        httpUIDConnector = nil;
    }
    
    [self startHttpLogin];
}

-(void)startHttpsLogin{
    switch (self.connectPrefType) {
        case ADDRESS_TYPE:
        {
            if (httpsAddressConnector) {
                [httpsAddressConnector startLoginToDevice];
                return;
            }
        }
            break;
        case DDNS_TYPE:
        {
            if (httpsAddressConnector) {
                [httpsAddressConnector startLoginToDevice];
                return;
            }else if (httpsUIDConnector){
                [httpsUIDConnector startLoginToDevice];
                return;
            }
        }
            break;
        case UID_TYPE:
        {
            if (httpsUIDConnector) {
                [httpsUIDConnector startLoginToDevice];
                return;
            }else if (httpsAddressConnector){
                [httpsAddressConnector startLoginToDevice];
                return;
            }
        }
            break;
        default:
        {
            NSLog(@"UNKNOW TYPE");
        }
            break;
    }
    
    [self.delegate finishLogin:self Success:NO Message:nil];
}

-(void)startHttpLogin{
    switch (self.connectPrefType) {
        case ADDRESS_TYPE:
        {
            if (httpAddressConnector) {
                [httpAddressConnector startLoginToDevice];
                return;
            }
        }
            break;
        case DDNS_TYPE:
        {
            if (httpAddressConnector) {
                [httpAddressConnector startLoginToDevice];
                return;
            }else if (httpUIDConnector){
                [httpUIDConnector startLoginToDevice];
                return;
            }
        }
            break;
        case UID_TYPE:
        {
            if (httpUIDConnector) {
                [httpUIDConnector startLoginToDevice];
                return;
            }else if (httpAddressConnector){
                [httpAddressConnector startLoginToDevice];
                return;
            }
        }
            break;
        default:
        {
            NSLog(@"UNKNOW TYPE");
        }
            break;
    }
    
    [self.delegate finishLogin:self Success:NO Message:nil];
}

-(void)stopLogin{
    if (httpsAddressConnector) {
        httpsAddressConnector.stopConnection = YES;
    }
    
    if (httpsUIDConnector) {
        httpsUIDConnector.stopConnection = YES;
    }
    
    if (httpAddressConnector) {
        httpAddressConnector.stopConnection = YES;
    }
    
    if (httpUIDConnector) {
        httpUIDConnector.stopConnection = YES;
    }
}

-(void)getDownloadInfo:(void (^)(NSString* address, int port))finishBlock{
    self.downloadInfoBlock = finishBlock;
    [self.currentCaller getDownloadInfo];
}

-(void)getUploadInfo:(void (^)(NSString* address, int port))finishBlock{
    self.uploadInfoBloack = finishBlock;
    [self.currentCaller getUplaodInfo];
}

-(NSString*)getDownloadUrl{
    return [self.currentCaller getDownloadUrl];
}

-(NSString*)getUploadUrl{
    return [self.currentCaller getUploadUrl];
}

#pragma mark HttpAPICommanderDelegate

-(void)didLoginResult:(ConnectionResult)result caller:(HttpAPICommander *)caller info:(NSDictionary *)LoginInfo address:(NSString *)strAddress port:(NSInteger)commandPort{
    if (result == CONNECTION_SUCCESS) {
        if ([self.uid length] > 0) {
            if ([caller isKindOfClass:[UIDConnector class]]) {
                self.connectPrefType = UID_TYPE;
            }else{
                self.connectPrefType = DDNS_TYPE;
            }
            [self saveToCache];
        }
        
        if ([strAddress isEqualToString:@"127.0.0.1"]) {
            self.isTunnelUsed = YES;
        }else{
            self.isTunnelUsed = NO;
        }
        
        self.commandDeviceAddress = [[NSString alloc] initWithString:strAddress];
        
        if ([self.scheme isEqualToString:@"http"]) {
            self.commandHttpAgentPort = commandPort;
        }else{
            self.commandHttpsAgentPort = commandPort;
        }
        
        NSString* loginResult = [LoginInfo objectForKey:LOGIN_ACKTAG];
        
        if (loginResult) {
            if ([loginResult isEqualToString:@"OK"] || [loginResult isEqualToString:@"GUEST"]) {
                if ([loginResult isEqualToString:@"OK"]) {
                    self.isAdminUser = YES;
                }else{
                    self.isAdminUser = NO;
                }
                
                if ([[LoginInfo objectForKey:@"ModelType"] intValue] == 1) {
                    [DataManager sharedInstance].modelType = 1;
                } else {
                    [DataManager sharedInstance].modelType = 0;
                }
                
#ifndef HTTPSONLY
                if ([[LoginInfo objectForKey:@"AgentCapability"] boolValue] && ![self.scheme isEqualToString:@"http"]) {
                    self.scheme = @"http";
                    [self doHttpLogin];
                    return;
                }
#endif
                
                if ([LoginInfo objectForKey:@"FirmwareVersion"]) {
                    self.firmwareVersion = [LoginInfo objectForKey:@"FirmwareVersion"];
                }
                
#if ConnectionType
                if (![[DataManager sharedInstance].connectionType isEqualToString:@"Local"]) {
                    if ([caller isKindOfClass:[UIDConnector class]]) {
                        if ([strAddress isEqualToString:@"127.0.0.1"]) {
                            [DataManager sharedInstance].connectionType = @"UID";
                        }else{
                            [DataManager sharedInstance].connectionType = @"UID(Local)";
                        }
                    }else{
                        [DataManager sharedInstance].connectionType = @"IP/DDNS";
                    }
                }
#endif
                self.currentCaller = caller;
                
                [self.currentCaller getDownloadInfo];
                [self.currentCaller getUplaodInfo];
                
                [self.delegate finishLogin:self Success:YES Message:loginResult];
                
            }else{
                [self.delegate finishLogin:self Success:YES Message:loginResult];
            }
        }else{
            [self.delegate finishLogin:self Success:NO Message:[LoginInfo description]];
        }
        
    }else{
        if (caller == httpsAddressConnector || caller == httpsUIDConnector) {
            if (caller == httpsAddressConnector) {
                httpsAddressConnector = nil;
            }else if (caller == httpsUIDConnector){
                httpsUIDConnector = nil;
            }
            
            [self startHttpsLogin];
        }else if (caller == httpAddressConnector || caller == httpUIDConnector){
            if (caller == httpAddressConnector) {
                httpAddressConnector = nil;
            }else if (caller == httpUIDConnector){
                httpUIDConnector = nil;
            }
            
            [self startHttpLogin];
        }else{
            [self.delegate finishLogin:self Success:NO Message:nil];
        }
    }
}

-(void)didGetDownloadIndo:(NSString *)address Port:(int)port{
    if (self.downloadInfoBlock) {
        self.downloadInfoBlock(address,port);
    }
}

-(void)didGetUploadIndo:(NSString *)address Port:(int)port{
    if (self.uploadInfoBloack) {
        self.uploadInfoBloack(address,port);
    }
}

#pragma mark MixDdnsUid
-(prefType)getPrefTypeFromCache{
    if ([self checkUIDFirst]) {
        return UID_TYPE;
    }
    return DDNS_TYPE;
}

-(BOOL)checkUIDFirst{
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"WiFi"]) {
        if ([[self checkBSSIDIsExist] objectForKey:@"index"] != nil) {
            return YES;
        }
        return NO;
    }else if([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"3G"]){
        if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:UID_3G_KEY,self.uid]] != nil) {
            return YES;
        }
        return NO;
    }else{
        return NO;
    }
}

-(NSDictionary*)checkBSSIDIsExist{
    NSDictionary* wifiInfo = [[DataManager sharedInstance] fetchSSIDInfo];
    NSString* ssid = [wifiInfo objectForKey:@"SSID"];
    NSString* bssid = [wifiInfo objectForKey:@"BSSID"];
    NSLog(@"WiFi Info : %@ , %@",ssid,bssid);
    
    NSArray* wifiList=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:UID_WIFI_KEY,self.uid]];
    
    NSMutableDictionary* resultDictionary=[NSMutableDictionary dictionary];
    for (int i=0; i<[wifiList count]; i++) {
        if ([wifiList[i] isEqualToString:bssid]) {
            [resultDictionary setObject:[NSNumber numberWithInt:i] forKey:@"index"];
            [resultDictionary setObject:bssid forKey:@"bssid"];
            return resultDictionary;
        }
    }
    if (bssid) {
        [resultDictionary setObject:bssid forKey:@"bssid"];
    }
    return resultDictionary;
}

-(void)saveToCache{
    NSLog(@"Current Preftyre: %d",self.connectPrefType);
    NSDictionary* result = [self checkBSSIDIsExist];
    NSMutableArray* wifiList=[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:UID_WIFI_KEY,self.uid]]];
    NSString* bssid = nil;
    int index = -1;
    if (result) {
        bssid = [result objectForKey:@"bssid"];
        if ([result objectForKey:@"index"]) {
            index = [[result objectForKey:@"index"] intValue];
        }
    }
    
    if (self.connectPrefType == UID_TYPE) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"3G"]) {
            [userDefault setObject:@"UID" forKey:[NSString stringWithFormat:UID_3G_KEY,self.uid]];
        }else if([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"WiFi"]){
            if (index == -1) {
                if ([wifiList count] >= 5) {
                    [wifiList removeLastObject];
                }
            }else{
                [wifiList removeObjectAtIndex:index];
            }
            if (bssid) {
                [wifiList insertObject:bssid atIndex:0];
            }
            [userDefault setObject:wifiList forKey:[NSString stringWithFormat:UID_WIFI_KEY,self.uid]];
        }
        
        [userDefault synchronize];
        
#if ConnectionType
        [DataManager sharedInstance].connectionType = @"UID";
#endif
    }else{
        [[DataManager sharedInstance] resetTunnel];
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"3G"]) {
            [userDefault setObject:nil forKey:[NSString stringWithFormat:UID_3G_KEY,self.uid]];
        }else if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"WiFi"]){
            if (index != -1) {
                [wifiList removeObjectAtIndex:index];
            }
            [userDefault setObject:wifiList forKey:[NSString stringWithFormat:UID_WIFI_KEY,self.uid]];
        }
        [userDefault synchronize];
        
#if ConnectionType
        [DataManager sharedInstance].connectionType = @"UID.EnGeniusDDNS";
#endif
    }
}

-(void)saveMasterConntectionDetail{
    serverDevice = master;
}

-(void)useMasterConntectionDetail{
    if(serverDevice){
        tmpDevice = master;
        master = serverDevice;
    }
}

-(void)useCurrentConntectionDetail{
    if(tmpDevice)
        master = tmpDevice;
}

-(void)resetMasterConntectionDetail{
    serverDevice = nil;
}

@end
