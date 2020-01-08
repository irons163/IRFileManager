//
//  SettingViewController.h
//  EnShare
//
//  Created by Phil on 2016/12/2.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayoutGuildReplaceViewController.h"

@interface SettingViewController : LayoutGuildReplaceViewController{
    
    IBOutlet UIImageView *modelImageView;
    
    IBOutlet UILabel *modelNameLabel;
    IBOutlet UILabel *publicIPTitleLabel;
    IBOutlet UILabel *localIPTitleLabel;
    IBOutlet UILabel *storageSizeTitleLabel;
    IBOutlet UILabel *updateTitleLabel;
    IBOutlet UILabel *publicIPLabel;
    IBOutlet UILabel *localIPLabel;
    IBOutlet UILabel *totalSizeLabel;
    IBOutlet UILabel *firmwareLabel;
    IBOutlet UIActivityIndicatorView *loadingView;
    IBOutlet UIButton *updateButton;
}
@property (strong, nonatomic) IBOutlet UIView *titleBackgroundView;
@property (strong, nonatomic) IBOutlet UIView *mainView;

- (IBAction)updateClick:(id)sender;

@end
