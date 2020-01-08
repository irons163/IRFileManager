//
//  DiskTableViewCell.m
//  EnShare
//
//  Created by Phil on 2017/2/16.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import "DiskTableViewCell.h"

@implementation DiskTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
#ifdef MESSHUDrive
    CGRect iconFrame = self.checkedIcon.frame;
    iconFrame.origin.x = 0;
    iconFrame.size.width = 52;
    self.checkedIcon.frame = iconFrame;
    CGRect imageFrame = self.diskImageView.frame;
    imageFrame.origin.x = imageFrame.origin.x + 40;
    self.diskImageView.frame = imageFrame;
    CGRect titleFrame  = self.partitionLabel.frame;
    titleFrame.origin.x = titleFrame.origin.x + 40;
    self.partitionLabel.frame =titleFrame;
#endif
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
