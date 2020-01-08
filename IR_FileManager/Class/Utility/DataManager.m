//
//  DataManager.m
//  IR_FileManager
//
//  Created by Phil on 2019/7/3.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "DataManager.h"
#import "FileTypeUtility.h"

@implementation DataManager

+ (DataManager*) sharedInstance {
    static id sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [self alloc];
        sharedInstance = [sharedInstance init];
    }
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        self.database = [[Database alloc] init];
    }
    return self;
}

- (NSString*)getType:(NSString*)ext {
    return [FileTypeUtility getType:ext];
}

@end
