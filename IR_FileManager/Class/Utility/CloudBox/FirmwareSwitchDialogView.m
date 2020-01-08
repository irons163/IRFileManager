//
//  FirmwareDialogView.m
//  CloudBox
//
//  Created by Wowoya on 13/4/21.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "FirmwareSwitchDialogView.h"
#import "KGModal.h"

@implementation FirmwareSwitchDialogView

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

- (IBAction)noClk:(id)sender{
    if ([self.delegate respondsToSelector:@selector(cancelTurnOffFirmwareSwitchAlert)]){
        [self.delegate performSelector:@selector(cancelTurnOffFirmwareSwitchAlert)];
    }
    
    [[KGModal sharedInstance] hideAnimated:YES];
}

-(IBAction)yesClk:(id)sender{
    if ([self.delegate respondsToSelector:@selector(turnOffFirmwareSwitchAlert)]){
        [self.delegate performSelector:@selector(turnOffFirmwareSwitchAlert)];
    }
    
    [[KGModal sharedInstance] hideAnimated:YES];
}

-(void)changeToSingleBtn{
    self.yesBtn.hidden = YES;
    self.noBtn.frame = CGRectMake(91, 110, 69, 26);
}

- (IBAction)okClk:(id)sender {
    
}

- (IBAction)helpClk:(id)sender {

}

@end
