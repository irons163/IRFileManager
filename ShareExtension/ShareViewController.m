//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Phil on 2020/1/17.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "ShareViewController.h"
#import <IRShareManager/IRShare.h>

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    [IRShare sharedInstance].groupID = @"group.irons163.IRFileManager";
    return YES;
}

- (void)didSelectPost {
    [[IRShare sharedInstance] showSaveAlertIn:self];
    [[IRShare sharedInstance] didSelectPostWith:self.extensionContext];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
