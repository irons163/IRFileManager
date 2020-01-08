//
//  StorageSelectWarningView.m
//  CloudBox
//
//  Created by Wowoya on 13/3/19.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "StorageSelectWarningView.h"
#import "KGModal.h"

@implementation StorageSelectWarningView

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

- (IBAction)okClk:(id)sender {
    [[KGModal sharedInstance] hideAnimated:YES];
}

@end
