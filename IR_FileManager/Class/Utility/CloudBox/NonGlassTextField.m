//
//  NonGlassTextField.m
//  EnShare
//
//  Created by Titan Chen on 2014/11/27.
//  Copyright (c) 2014年 Senao. All rights reserved.
//

#import "NonGlassTextField.h"

@implementation NonGlassTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    //Prevent zooming but not panning
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
    {
        gestureRecognizer.enabled = NO;
    }
    [super addGestureRecognizer:gestureRecognizer];
    return;
}

@end
