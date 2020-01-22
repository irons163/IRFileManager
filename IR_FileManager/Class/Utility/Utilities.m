//
//  Utilities.m
//  IR_FileManager
//
//  Created by Phil on 2020/1/21.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "Utilities.h"
#import <AVFoundation/AVFoundation.h>

@implementation Utilities

+ (UIImage *)getMusicCover:(NSString *)urlString {
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

+ (UIImage *)generateThumbImage:(NSString *)filepath {
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

@end
