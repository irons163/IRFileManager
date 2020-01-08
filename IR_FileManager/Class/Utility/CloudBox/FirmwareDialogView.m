//
//  FirmwareDialogView.m
//  CloudBox
//
//  Created by Wowoya on 13/4/21.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "FirmwareDialogView.h"
#import "KGModal.h"

@implementation FirmwareDialogView

-(void)awakeFromNib{
    [super awakeFromNib];
    self.imageView.layer.cornerRadius = 10;
    self.imageView.clipsToBounds = YES;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (IBAction)cancelClk:(id)sender{
    [[KGModal sharedInstance] hideAnimated:YES];
}

-(IBAction)detailClk:(id)sender{
    if ([self.delegate respondsToSelector:@selector(showFirmwareDetail)]){
        [self.delegate performSelector:@selector(showFirmwareDetail) withObject:nil];
    }
    [[KGModal sharedInstance] hideAnimated:YES];
}

-(void)changeToSingleBtn{
    self.detailBtn.hidden = YES;
    self.cancelBtn.frame = CGRectMake(91, self.cancelBtn.frame.origin.y, 69, 26);
}

- (IBAction)okClk:(id)sender {
    
}

- (IBAction)helpClk:(id)sender {

}

@end
