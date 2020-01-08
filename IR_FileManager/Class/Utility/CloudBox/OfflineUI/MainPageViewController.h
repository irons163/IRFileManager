//
//  MainPageViewController.h
//  EnSmart
//
//  Created by Phil on 2015/8/17.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AssetsLibrary/AssetsLibrary.h>

@interface MainPageViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *documentTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *albumTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *musicTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *allTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *messageCenterButton;
@property (strong, nonatomic) IBOutlet UIButton *personalStorageButton;
@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIButton *passcodeLockButton;

- (IBAction)gotoDocumentPageClick:(id)sender;
- (IBAction)gotoVideoPageClick:(id)sender;
- (IBAction)gotoMusicPageClick:(id)sender;
- (IBAction)gotoAlbumPageClick:(id)sender;
- (IBAction)gotoAllPageClick:(id)sender;
- (IBAction)gotoOnlineModeClick:(id)sender;
- (IBAction)notificationClick:(id)sender;
- (IBAction)passcodeLockClick:(id)sender;

@end
