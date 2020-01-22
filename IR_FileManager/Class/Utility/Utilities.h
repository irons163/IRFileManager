//
//  Utilities.h
//  IR_FileManager
//
//  Created by Phil on 2020/1/21.
//  Copyright © 2020 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utilities : NSObject

+ (UIImage *)getMusicCover:(NSString *)urlString;
+ (UIImage *)generateThumbImage:(NSString *)filepath;

@end

NS_ASSUME_NONNULL_END
