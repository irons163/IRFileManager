//
//  FileTypeUtility.h
//  EnShare
//
//  Created by Phil on 2017/8/14.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FileTypeUtility : NSObject

+ (NSString*)getType:(NSString*)ext;
+ (UIImage*)getImageWithType:(NSString*)type ext:(NSString*)ext;
+ (UIImage*)getImageOfflineWithType:(NSString*)type ext:(NSString*)ext;

@end
