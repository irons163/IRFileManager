//
//  StorageDeleteView.m
//  CloudBox
//
//  Created by Wowoya on 13/3/19.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "StorageDeleteView.h"
#import "KGModal.h"

@implementation StorageDeleteView

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

- (IBAction)cancelClk:(id)sender {
    [[KGModal sharedInstance] hideAnimated:YES];
}

- (IBAction)okClk:(id)sender {
    if ([self.delegate respondsToSelector:@selector(delete:)])
        [self.delegate performSelector:@selector(delete:) withObject:self.files];
}

@end
