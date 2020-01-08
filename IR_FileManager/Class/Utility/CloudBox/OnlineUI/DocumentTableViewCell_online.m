//
//  DocumentTableViewCell.m
//  EnSmart
//
//  Created by Phil on 2015/8/20.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "DocumentTableViewCell_online.h"

@implementation DocumentTableViewCell_online{
    CGFloat originalCheckboxWidth;
    CGFloat originalFavoriteButtonWidth;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.checkboxButton.userInteractionEnabled = NO;
    originalCheckboxWidth = self.checkboxWidthConstraint.constant;
    originalFavoriteButtonWidth = self.favoriteButtonWidthConstraint.constant;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)favoriteClick:(id)sender {
    self.favoriteButton.selected = !self.favoriteButton.selected;
    if ([self.delegate respondsToSelector:@selector(starClk:file:)])
        [self.delegate performSelector:@selector(starClk:file:) withObject:@(self.favoriteButton.selected) withObject:self.file];
}

-(void)changeToSelectedMode:(BOOL)isSelectMode{
    if(isSelectMode){
        self.checkboxWidthConstraint.constant = originalCheckboxWidth;
        self.favoriteButtonWidthConstraint.constant = 10;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }else{
        self.checkboxWidthConstraint.constant = 0;
        self.favoriteButtonWidthConstraint.constant = originalFavoriteButtonWidth;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    self.checkboxView.hidden =!isSelectMode;
    self.favoriteButton.hidden = isSelectMode;
}
@end
