//
//  DocumentTableViewCell.h
//  EnSmart
//
//  Created by Phil on 2015/8/20.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OnLineDataFile.h"

@interface DocumentTableViewCell_online : UITableViewCell
@property (strong, nonatomic) IBOutlet UIView *InfoView;
@property (strong, nonatomic) IBOutlet UIButton *checkboxView;
@property (strong, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (strong, nonatomic) IBOutlet UILabel *createDateLabel;
@property (strong, nonatomic) IBOutlet UIButton *checkboxButton;
@property (strong, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkboxWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *favoriteButtonWidthConstraint;
//- (IBAction)checkboxClick:(id)sender;
- (IBAction)favoriteClick:(id)sender;

@property (nonatomic) id delegate;
@property (strong, nonatomic) OnLineDataFile* file;

-(void) changeToSelectedMode:(BOOL)isSelectMode;
@end
