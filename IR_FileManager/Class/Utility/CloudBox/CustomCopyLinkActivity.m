//
//  CustomCopyLinkActivity.m
//  EnShare
//
//  Created by Phil on 2015/7/14.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "CustomCopyLinkActivity.h"

@implementation CustomCopyLinkActivity{
    NSString* str;
}

+(UIActivityCategory)activityCategory{
    return UIActivityCategoryAction;
}

- (NSString *)activityType {
//    self.activityType = @"CustomCopyLinkActivity";
//    return self.activityType;
    return @"CustomCopyLinkActivity"; }
- (NSString *)activityTitle { return @"Copy Link"; }
- (UIImage *) activityImage { return [UIImage imageNamed:@"Copy_Link_inverse.png"]; }
- (BOOL) canPerformWithActivityItems:(NSArray *)activityItems { return YES; }
- (void) prepareWithActivityItems:(NSArray *)activityItems {
    str = activityItems[0];
}
- (UIViewController *) activityViewController { return nil; }
- (void) performActivity {
    if(str)
        [UIPasteboard generalPasteboard].string = str;
    [self activityDidFinish:true];
}

-(void)activityDidFinish:(BOOL)completed{
    [super activityDidFinish:completed];
}

@end
