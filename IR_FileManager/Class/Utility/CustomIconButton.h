//
//  CustomIconButton.h
//  ezm_test
//
//  Created by Phil on 2018/1/5.
//  Copyright © 2018年 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IconContentMode) {
    IconContentModeCenter       = 0,
    IconContentModeLeft,
    IconContentModeRight
};

IB_DESIGNABLE
@interface CustomIconButton : UIButton

#if !TARGET_INTERFACE_BUILDER
@property (nonatomic, assign) IBInspectable UIViewContentMode imageViewContentMode;
#else
@property (nonatomic, assign) IBInspectable NSInteger imageViewContentMode;
#endif

@property (nonatomic, assign) IBInspectable NSInteger iconContentMode;
//@property (nonatomic, assign) IBInspectable XXX iconPosition;


@property (nonatomic, assign) IBInspectable CGSize iconSizePersent; // >0
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;
@property (nonatomic, assign) IBInspectable CGFloat borderWidth;
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

@property (nonatomic, assign) IBInspectable CGFloat titleEdgeTop;
@property (nonatomic, assign) IBInspectable CGFloat titleEdgeLeft;
@property (nonatomic, assign) IBInspectable CGFloat titleEdgeBottom;
@property (nonatomic, assign) IBInspectable CGFloat titleEdgeRight;

@end
