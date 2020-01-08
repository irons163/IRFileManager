//
//  SecurityPinButton.m
//  EnFile
//
//  Created by Phil on 2018/10/24.
//  Copyright © 2018年 Senao. All rights reserved.
//

#import "SecurityPinButton.h"
#import "UIColor+Helper.h"

@implementation SecurityPinButton

- (instancetype)init {
    if (self = [super init]) {
        [self initButton];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initButton];
    }
    return self;
}

- (void)initButton {
//    [self setContentEdgeInsets:UIEdgeInsetsMake(8, 4, 8, 4)];
    [self setBackgroundImage:[self imageFromColor:[UIColor colorWithColorCodeString:@"FF18937B"]] forState:UIControlStateHighlighted];
}

- (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
