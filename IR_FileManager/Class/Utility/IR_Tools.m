//
//  Tools.m
//  EnSmart
//
//  Created by Phil on 2015/8/28.
//  Copyright (c) 2015年 Phil. All rights reserved.
//


#import "IR_Tools.h"
#import <AVFoundation/AVFoundation.h>

@implementation IR_Tools

+(NSDate *)getFileCreationTimeFromPath:(NSString *)filePath{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDictionary* attrs = [fm attributesOfItemAtPath:filePath error:nil];
    NSDate *date;
    if (attrs != nil) {
        date = (NSDate*)[attrs objectForKey: NSFileCreationDate];
        NSLog(@"Date Created: %@", [date description]);
    }
    else {
        NSLog(@"Not found");
    }
    
    return date;
}

+(NSString*)formatDate_ddMMyyyy:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy"];
    NSString *datestring = [formatter stringFromDate:date];
    return datestring;
}

+(NSString*)formatDate_yyyyMMdd:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *datestring = [formatter stringFromDate:date];
    return datestring;
}

+(UIImage *)generateThumbImage : (NSString *)filepath
{
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = [asset duration];
    time.value = 0;
    CGSize maxSize = CGSizeMake(320, 180);
    imageGenerator.maximumSize = maxSize;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return thumbnail;
}

//取得音樂封面
+ (UIImage*)getMusicCover:(NSString*)urlString{
//    NSString * s = [urlString substringFromIndex:1];
    NSURL *url = [NSURL fileURLWithPath:urlString];
    AVAsset *asset = [AVAsset assetWithURL:url];
//    UIImage* defaultImage = [UIImage imageNamed:@"music"];
    UIImage* defaultImage = nil;
    for (AVMetadataItem *metadataItem in asset.commonMetadata) {
        if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceID3]){
            if ([metadataItem.value isKindOfClass:[NSDictionary class]]) {
                NSDictionary *imageDataDictionary = (NSDictionary *)metadataItem.value;
                NSData *imageData = [imageDataDictionary objectForKey:@"data"];
                UIImage *image = [UIImage imageWithData:imageData];
                // Display this image on my UIImageView property imageView
                if (image) {
                    defaultImage = image;
                    break;
                }
            }else if([metadataItem.value isKindOfClass:[NSData class]]){
                UIImage *image = [UIImage imageWithData:(NSData*)metadataItem.value];
                if (image) {
                    defaultImage = image;
                    break;
                }
            }
        }else if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceiTunes]){
            if([[metadataItem.value copyWithZone:nil] isKindOfClass:[NSData class]]){
                UIImage* image = [UIImage imageWithData:[metadataItem.value copyWithZone:nil]];
                if (image) {
                    defaultImage = image;
                    break;
                }
            }
        }
    }
    
    return defaultImage;
}

+(float)getVideoDuration : (NSString *)filepath
{
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    AVAsset *asset = [AVAsset assetWithURL:url];
//    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = [asset duration];
    float seconds = CMTimeGetSeconds(time);
    
    return seconds;
}

+(NSNumber*)getFileSize:(NSString *)filepath{
    NSError* error;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error: &error];
    NSNumber *fileSize = [fileDictionary objectForKey:NSFileSize];
    return fileSize;
}

+(NSString*)transformedValue:(id)value
{
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

+(NSString*)getAppVersionName{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath = [path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    NSString *version = [plistData objectForKey:@"CFBundleVersion"];
    return version;
}

@end
