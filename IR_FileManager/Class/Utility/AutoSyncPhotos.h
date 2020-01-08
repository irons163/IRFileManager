//
//  AutoSyncPhotos.h
//  EnShare
//
//  Created by Phil on 2016/11/14.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AutoSyncPhotosDelegate <NSObject>

- (void)syncFinishCallback;

@end

@interface AutoSyncPhotos : NSObject
+ (AutoSyncPhotos*)sharedInstance;
//- (BOOL)checkUpload:(NSString*)folderName;
-(void)doSync;
//- (void)cancelUpload;
@property (nonatomic, assign) id<AutoSyncPhotosDelegate> delegate;

@end
