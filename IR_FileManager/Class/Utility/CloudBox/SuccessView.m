//
//  SuccessView.m
//  EnShare
//
//  Created by ke on 6/27/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "SuccessView.h"
#import "KGModal.h"

@implementation SuccessView

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
    if ([self.delegate respondsToSelector:@selector(logout)])
        [self.delegate performSelector:@selector(logout) withObject:nil];
}

@end
