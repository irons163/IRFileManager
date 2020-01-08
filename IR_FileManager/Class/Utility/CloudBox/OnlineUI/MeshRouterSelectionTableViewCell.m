//
//  MeshRouterSelectionTableViewCell.m
//  EnShare
//
//  Created by Phil on 2017/3/16.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import "MeshRouterSelectionTableViewCell.h"

@implementation MeshRouterSelectionTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
#ifdef MESSHUDrive
    CGRect tmpFrame = self.checkedIcon.frame;
    tmpFrame.origin.x = 0;
    tmpFrame.origin.y = 16;
    tmpFrame.size.height = 21;
    self.checkedIcon.frame = tmpFrame;
#endif
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
