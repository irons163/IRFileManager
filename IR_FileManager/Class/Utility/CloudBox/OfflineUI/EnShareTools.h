//
//  EnShareTools.h
//
//  Created by Phil on 2015/8/24.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#ifndef EnShare_Tools_h
#define EnShare_Tools_h

// 多國語言字串
#define _(str)  NSLocalizedString(str, nil)

// 從 view 的 xib 取出
#define VIEW(viewObj, viewClass) \
NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:[[viewClass class] description] owner:nil options:nil]; \
for (id currentObject in topLevelObjects) \
{ \
if ([currentObject isKindOfClass:[viewClass class]]) \
{ \
viewObj =  (viewClass*)currentObject; \
break; \
} \
} \

#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EnShareTools : NSObject

+(NSDate*)getFileCreationTimeFromPath:(NSString*)path;
//+(NSString*)formatDate:(NSDate*)date;
+(NSString*)formatDate_ddMMyyyy:(NSDate*)date;
+(NSString*)formatDate_yyyyMMdd:(NSDate*)date;
+(UIImage *)generateThumbImage : (NSString *)filepath;
+(UIImage*)getMusicCover:(NSString*)urlString;
+(float)getVideoDuration : (NSString *)filepath;
+(NSNumber*)getFileSize:(NSString *)filepath;
+(NSString*)transformedValue:(id)value;
+(NSString*)getAppVersionName;
@end
