//
//  HttpAPICommander.m
//  EnShare
//
//  Created by WeiJun on 2015/2/13.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "HttpAPICommander.h"

@implementation HttpAPICommander

-(id)initWithAddress:(NSString *)strIP port:(NSInteger)port user:(NSString *)user pwd:(NSString *)pwd scheme:(NSString *)scheme
{
    if ([super init] == nil) {
        return nil;
    }
    
    self.address = strIP;
    self.userName = user;
    self.password = pwd;
    self.commandPort = port;
    self.scheme = scheme;
    self.stopConnection = NO;
    
    return self;
}

-(id)initWithUID:(NSString *)strUID port:(NSInteger)port user:(NSString *)user pwd:(NSString *)pwd scheme:(NSString *)scheme
{
    if ([super init] == nil) {
        return nil;
    }
    
    self.uid = strUID;
    self.userName = user;
    self.password = pwd;
    self.commandPort = port;
    self.scheme = scheme;
    
    return self;
}

@end
