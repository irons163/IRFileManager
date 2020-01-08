//
//  SettingTableViewCell.m
//  EnShare
//
//  Created by Phil on 2016/12/13.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "SettingTableViewCell.h"

@implementation SettingTableViewCell {
    CGPoint titleLabelCenterForTwoLine;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    titleLabelCenterForTwoLine = self.titleLabel.center;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)changeToOneLine {
    CGPoint tmp = self.titleLabel.center;
    tmp.y = self.imageView.center.y;
    self.titleLabel.center = tmp;
}

- (void)changeToTwoLine {
    CGPoint tmp = self.titleLabel.center;
    tmp.y = titleLabelCenterForTwoLine.y;
    self.titleLabel.center = tmp;
}

@end
