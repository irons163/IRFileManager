//
//  CircleProgressView.h
//
//  Created by Andy Liu on 12/05/13.
//

#import "CircleProgressView.h"

#define kCircleSegs 100

@implementation CircleProgressView
@synthesize currentProgress;
@synthesize numberColor;
@synthesize numberFont;
@synthesize circleColor;
@synthesize circleBorderWidth;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.numberColor = [UIColor whiteColor];
        self.numberFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f];
        self.circleColor = [UIColor colorWithRed:186.0/255.0 green:218.0/255.0 blue:85.0/255.0 alpha:1.0];
        self.circleBorderWidth = 10;
        
        self.currentProgress = 0;
        
        self.backgroundColor = [UIColor clearColor];

    }
    return self;
}

- (void)update:(int)progress {
    
    self.currentProgress = progress;
    
//    if (progress == 0) {
//        self.currentProgress = 0.01;
//    }
    
    //NSLog(@"set progress to :%d",progress);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    float radius = CGRectGetWidth(rect)/2.0f - self.circleBorderWidth/2.0f;
    float angleOffset = M_PI_2;

    CGContextSetLineWidth(context, self.circleBorderWidth);
    CGContextBeginPath(context);
    
//    CGContextAddArc(context,
//                    CGRectGetMidX(rect), CGRectGetMidY(rect),
//                    radius,
//                    -angleOffset,
//                    self.currentProgress/(float)kCircleSegs*M_PI*2 - angleOffset,
//                    0);
//    
//    CGContextSetStrokeColorWithColor(context, self.circleColor.CGColor);
//    CGContextStrokePath(context);
    
    //if (self.currentProgress != kCircleSegs) {
        CGContextAddArc(context,
                        CGRectGetMidX(rect), CGRectGetMidY(rect),
                        radius,
                        100/(float)kCircleSegs*M_PI*2 - angleOffset,
                        -angleOffset,
                        0);
    
#ifdef MESSHUDrive
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
#else
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:192.0/255.0 green:219.0/255.0 blue:88.0/255.0 alpha:1.0].CGColor);
#endif
    
        CGContextStrokePath(context);
    //}
    
    CGContextAddArc(context,
                    CGRectGetMidX(rect), CGRectGetMidY(rect),
                    radius,
                    -angleOffset,
                    self.currentProgress/(float)kCircleSegs*M_PI*2 - angleOffset,
                    0);
    
    CGContextSetStrokeColorWithColor(context, self.circleColor.CGColor);
    CGContextStrokePath(context);
    
    CGContextSetLineWidth(context, 1.0f);
    NSString *numberText = [NSString stringWithFormat:@"%d%%",(int)self.currentProgress];
    CGSize sz = [numberText sizeWithFont:self.numberFont];
    [self.numberColor setFill];
    [numberText drawInRect:CGRectInset(rect, (CGRectGetWidth(rect) - sz.width)/2.0f, (CGRectGetHeight(rect) - sz.height)/2.0f) withFont:self.numberFont];
}

@end
