//
//  OnlineFGalleryViewController.h
//  EnShare
//
//  Created by Phil on 2016/12/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "OfflineFGalleryViewController.h"

@interface OfflineFGalleryViewController ()
- (void)setNavigatinItem;
- (void)createToolbarItems;
- (void)shareClk:(id)sender;
- (void)shareByFileURLStringWithPath:(NSString*)file;
- (void)backBtnDidClick;
@end

@interface OnlineFGalleryViewController : OfflineFGalleryViewController

@end

@protocol OnlineFGalleryViewControllerDelegate <FGalleryViewControllerDelegate>
- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery filePathAtIndex:(NSUInteger)index;
@end
