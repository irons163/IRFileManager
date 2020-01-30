//
//  FileTypeUtility.h
//
//  Created by Phil on 2017/8/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FileTypeUtility : NSObject

+ (NSString *)getFileType:(NSString *)ext;
+ (NSNumber *)getFileSize:(NSString *)filepath;
+ (NSDate *)getFileCreationTimeFromPath:(NSString *)filePath;
+ (UIImage *)getImageWithType:(NSString *)type ext:(NSString *)ext;
+ (UIImage *)getImageOfflineWithType:(NSString *)type ext:(NSString *)ext;

+ (NSString *)getDocumentFileType;
+ (NSString *)getPictureFileType;
+ (NSString *)getVideoFileType;
+ (NSString *)getMusicFileType;

@end
