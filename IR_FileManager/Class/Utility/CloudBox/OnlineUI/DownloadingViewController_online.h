//
//  DownloadingViewController_online.h
//  EnShare
//
//  Created by Phil on 2016/12/5.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayoutGuildReplaceViewController.h"

@protocol DownloadingViewControllerDelegate <NSObject>

-(void)downloadSuccessCallback;
-(void)downloadCancelClickedCallback;

@end

@interface DownloadingViewController_online : LayoutGuildReplaceViewController
@property (strong, nonatomic) IBOutlet UILabel *downloadStatusInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *downloadToTargetInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

- (IBAction)cancelDownloadClick:(id)sender;

@property (nonatomic, assign) id<DownloadingViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray* downloadItems;

-(void)setSaveToAlbum:(BOOL)saveToAlbum;

@end
