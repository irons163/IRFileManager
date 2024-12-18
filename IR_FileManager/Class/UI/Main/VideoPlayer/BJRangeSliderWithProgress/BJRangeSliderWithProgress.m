//
//  BJRangeSliderWithProgress.m
//  BJRangeSliderWithProgress
//
//  Created by Barrett Jacobsen on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BJRangeSliderWithProgress.h"

#define sliderHeight 1

@implementation BJRangeSliderWithProgress
@dynamic minValue, maxValue, currentProgressValue;
@dynamic leftValue, rightValue;
@dynamic showThumbs, showProgress, showRange;

static bool enableRightLimit = false;

- (void)setLeftValue:(CGFloat)newValue {
    if (newValue < minValue)
        newValue = minValue;
    
    if(enableRightLimit){
        if (newValue > rightValue)
            newValue = rightValue;
        
        leftValue = newValue;
    }else{
        if (newValue > maxValue)
            newValue = maxValue;
        
        leftValue = newValue;
    }

    
    [self setNeedsLayout];
}

- (void)setRightValue:(CGFloat)newValue {
    if (newValue > maxValue)
        newValue = maxValue;
    
    if (newValue < leftValue)
        newValue = leftValue;
    
    rightValue = newValue;
    
    [self setNeedsLayout];
}

- (void)setCurrentProgressValue:(CGFloat)newValue {
    if (newValue > maxValue)
        newValue = maxValue;
    
    if (newValue < minValue)
        newValue = minValue;
    
    currentProgressValue = newValue;
    
    [self setNeedsLayout];
}

- (void)setMinValue:(CGFloat)newValue {
    minValue = newValue;
    
    if (leftValue < minValue)
        leftValue = minValue;
    
    if (rightValue < minValue)
        rightValue = minValue;
    
    [self setNeedsLayout];
}

- (void)setMaxValue:(CGFloat)newValue {
    maxValue = newValue;
    
    if (leftValue > maxValue)
        leftValue = maxValue;
    
    if (rightValue > maxValue)
        rightValue = maxValue;
    
    [self setNeedsLayout];
}

- (CGFloat)minValue {
    return minValue;
}

- (CGFloat)maxValue {
    return maxValue;
}

- (CGFloat)currentProgressValue {
    return currentProgressValue;
}

- (CGFloat)leftValue {
    return leftValue;
}

- (CGFloat)rightValue {
    return rightValue;
}

- (void)setShowThumbs:(BOOL)showThumbs {
    leftThumb.hidden = !showThumbs;
    rightThumb.hidden = YES;
}

- (BOOL)showThumbs {
    return !leftThumb.hidden;
}


- (void)setShowProgress:(BOOL)showProgress {
    progressImage.hidden = !showProgress;
}

- (BOOL)showProgress {
    return !progressImage.hidden;
}

- (void)setShowRange:(BOOL)showRange {
    rangeImage.hidden = !showRange;
}

- (BOOL)showRange {
    return !rangeImage.hidden;
}

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        self.sliding = YES;
        CGPoint translation = [gesture translationInView:self];
        CGFloat range = maxValue - minValue;
        CGFloat availableWidth = self.frame.size.width - BJRANGESLIDER_THUMB_SIZE;
        self.leftValue += translation.x / availableWidth * range;
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.sliding = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(progressDidChange:)]) {
            [self.delegate progressDidChange:self.leftValue];
        }
    }
}

- (void)handleRightPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat range = maxValue - minValue;
        CGFloat availableWidth = self.frame.size.width - BJRANGESLIDER_THUMB_SIZE;
        self.rightValue += translation.x / availableWidth * range;
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)setup {
    if (maxValue == 0.0) {
        maxValue = 100.0;
    }
    
    leftValue = minValue;
    rightValue = maxValue;
    
//    slider = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderEmpty.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4]];
    slider = [[UIImageView alloc] initWithImage:[self createImageWithColor:[UIColor whiteColor]]];
    [self addSubview:slider];

//    rangeImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderBlue.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4]];
    rangeImage = [[UIImageView alloc] initWithImage:[self createImageWithColor:[UIColor grayColor]]];
    [self addSubview:rangeImage];

//    progressImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderRed.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4]];
    progressImage = [[UIImageView alloc] initWithImage:[self createImageWithColor:[UIColor redColor]]];
    [self addSubview:progressImage];


    // left thumb is above
    UIImage* thumbImage = [UIImage imageNamed:@"BJRangeSlider.bundle/sliderthumb"];
    leftThumb = [[UIImageView alloc] initWithFrame:CGRectMake(0, -BJRANGESLIDER_THUMB_SIZE, thumbImage.size.width*3, thumbImage.size.height*3)];
    //leftThumb.image = [UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderStartThumb.png"];
    leftThumb.image = thumbImage;
    leftThumb.userInteractionEnabled = YES;
    leftThumb.contentMode = UIViewContentModeCenter;
    [self addSubview:leftThumb];
    
    UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
    [leftThumb addGestureRecognizer:leftPan];
    
    //right thumb is below
    rightThumb = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, BJRANGESLIDER_THUMB_SIZE + 12, BJRANGESLIDER_THUMB_SIZE * 2)];
    rightThumb.image = [UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderEndThumb.png"];
    rightThumb.userInteractionEnabled = YES;
    rightThumb.contentMode = UIViewContentModeCenter;
    [self addSubview:rightThumb];
    
    UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
    [rightThumb addGestureRecognizer:rightPan];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    
    CGFloat availableWidth = self.frame.size.width - BJRANGESLIDER_THUMB_SIZE;
    CGFloat inset = BJRANGESLIDER_THUMB_SIZE / 2;
    
    CGFloat range = maxValue - minValue;
    
    CGFloat left = floorf((leftValue - minValue) / range * availableWidth);
    CGFloat right = floorf((rightValue - minValue) / range * availableWidth);
//    CGFloat right = floorf((1 - minValue) / range * availableWidth);
    
    if (isnan(left)) {
        left = 0;
    }
    
    if (isnan(right)) {
        right = 0;
    }
    
    slider.frame = CGRectMake(inset, self.frame.size.height / 2 , availableWidth, sliderHeight);

    CGFloat rangeWidth = right - left;
//    CGFloat rangeWidth = 1 - left;
    if ([self showRange]) {
        rangeImage.frame = CGRectMake(inset + left, self.frame.size.height / 2 , rangeWidth, sliderHeight);
    }
    
    if ([self showProgress]) {
//        CGFloat progressWidth = floorf((currentProgressValue - leftValue) / (rightValue - leftValue) * rangeWidth) * -1;
//        if (isnan(progressWidth)) {
//            progressWidth = 0;
//        }
        
        CGFloat progressWidth = progressWidth = ((leftValue - minValue)/(maxValue - minValue)) * availableWidth;
//        NSLog(@"abc %@,%f",self,self.frame.size.height);
        //progressImage.frame = CGRectMake(inset + left, self.frame.size.height / 2 - 5, progressWidth, sliderHeight);
        progressImage.frame = CGRectMake(inset , self.frame.size.height / 2 , progressWidth, sliderHeight);
    }
        
//    leftThumb.center = CGPointMake(inset + left, self.frame.size.height / 2 - BJRANGESLIDER_THUMB_SIZE / 2);
    leftThumb.center = CGPointMake(inset + left, slider.center.y);
    rightThumb.center = CGPointMake(inset + right, self.frame.size.height / 2 + BJRANGESLIDER_THUMB_SIZE / 2);
}


- (void)setDisplayMode:(BJRangeSliderWithProgressDisplayMode)mode {
    switch (mode) {
        case BJRSWPAudioRecordMode:
            self.showThumbs = NO;
            self.showRange = NO;
            self.showProgress = YES;
            progressImage.image = [[UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderRed.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4];
            break;
            
        case BJRSWPAudioSetTrimMode:
            self.showThumbs = YES;
            self.showRange = YES;
            self.showProgress = NO;
            break;

        case BJRSWPAudioPlayMode:
            self.showThumbs = NO;
            self.showRange = YES;
            self.showProgress = YES;
            progressImage.image = [[UIImage imageNamed:@"BJRangeSlider.bundle/BJRangeSliderGreen.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4];
        default:
            break;
    }
    
    [self setNeedsLayout];
}

- (UIImage *) createImageWithColor: (UIColor *) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

@end
