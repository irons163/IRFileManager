//
//  AppDelegate.h
//  IR_FileManager
//
//  Created by Phil on 2019/7/1.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MagicalRecord/MagicalRecord.h>
#import <CoreData/CoreData.h>
#import "File+CoreDataClass.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) File* importFile;

@end

