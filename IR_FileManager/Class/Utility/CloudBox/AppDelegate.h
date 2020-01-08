//
//  AppDelegate.h
//  CloudBox
//
//  Created by Wowoya on 13/2/7.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CollectionDataFile.h"
#import "LogoViewController.h"
#import "SecurityView/SecurityPinViewController.h"
#import "SecurityView/SecurityPinManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, LogoViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) BOOL isUpgrading;
@property (strong,nonatomic) NSDictionary* EnMeshInfoDictionary;
@property (strong,nonatomic) CollectionDataFile* importFile;


@end
