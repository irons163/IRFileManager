//
//  WirelessSettingViewController.h
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayoutGuildReplaceViewController.h"

@interface WirelessSettingViewController : LayoutGuildReplaceViewController

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIView *titleBackgroundView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *hintTitleLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
//@property (strong, nonatomic) IBOutlet UIView *rebootView;
//@property (strong, nonatomic) IBOutlet UILabel *timerLbl;
//@property (strong, nonatomic) IBOutlet UILabel *rebootTitleLabel;

@end
