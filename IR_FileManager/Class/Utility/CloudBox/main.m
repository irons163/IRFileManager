//
//  main.m
//  CloudBox
//
//  Created by Wowoya on 13/2/7.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
    #ifdef smalink
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObject:@"en"] forKey:@"AppleLanguages"];
            [[NSUserDefaults standardUserDefaults] synchronize];
    #endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
