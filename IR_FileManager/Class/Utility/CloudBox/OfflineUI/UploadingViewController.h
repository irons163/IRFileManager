//
//  UploadingViewController.h
//  EnShare
//
//  Created by Phil on 2016/11/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayoutGuildReplaceViewController.h"

@interface UploadingViewController : LayoutGuildReplaceViewController{
    BOOL isFromAlbum;
    int totalUploadItemsCount;
    int uploadedItemsCount;
}

@property (strong, nonatomic) IBOutlet UILabel *uploadStatusInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *uploadToTargetInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

- (IBAction)cancelUploadClick:(id)sender;

@property (nonatomic, strong) NSArray* uploadItems;
-(void)setFromAlbum:(BOOL)isFromAlbum;
-(void)willDoNextUploadAfterSuccess;
-(void)allSuccess;
@end
