//
//  AutoUpload.h
//  EnShare
//
//  Created by ke on 2014/2/5.
//  Copyright (c) 2014年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoUpload : NSObject

+ (AutoUpload*)sharedInstance;
//- (BOOL)checkUpload:(NSString*)folderName;
- (void)doUpload:(NSString*)folderName;
- (void)cancelUpload;

@end
