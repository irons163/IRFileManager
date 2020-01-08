//
//  ClientManagerTableViewCell.m
//  EnShare
//
//  Created by Phil on 2016/12/12.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "ClientManagerTableViewCell.h"
#import "UIColor+Helper.h"

@implementation ClientManagerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.blockButton setTitleColor:[UIColor colorWithRGB:0x00b4f5] forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)blockButtonClick:(id)sender {
    if(self.isConnected){
        if ([self.delegate respondsToSelector:@selector(doEditBlockedClient:)])
            [self.delegate performSelector:@selector(doEditBlockedClient:) withObject:sender];
    }else{
        if ([self.delegate respondsToSelector:@selector(doDeleteBlockedClient:)])
            [self.delegate performSelector:@selector(doDeleteBlockedClient:) withObject:sender];
    }
}
@end
