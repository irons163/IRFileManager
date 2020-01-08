//
//  DialogView.m
//  CloudBox
//
//  Created by Wowoya on 13/4/21.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "DialogView.h"
#import "KGModal.h"

@implementation DialogView

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

- (IBAction)helpClk:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dialogOk)]){
        [self.delegate performSelector:@selector(dialogOk) withObject:nil];
    }
    [[KGModal sharedInstance] hideAnimated:YES];
}

@end
