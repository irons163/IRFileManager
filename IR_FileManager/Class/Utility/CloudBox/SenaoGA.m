//
//  SenaoGA.m
//  EnMesh
//
//  Created by Titan Chen on 2016/4/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "SenaoGA.h"

@implementation SenaoGA
+(void)setScreenName:(NSString*)screenName{
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker set:kGAIScreenName value:screenName];
//    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+(void)setEvent:(NSString*)category Action:(NSString*)action Label:(NSString*)label Value:(NSNumber*)value{
    
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:((category==nil)? @"no set":category)
//                                                          action:action
//                                                           label:((label==nil)? @"no set":label)
//                                                           value:value] build]];
}

+(void)simpleSetAction:(NSString *)action{
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"no set"
//                                                          action:action
//                                                           label:@"no set"
//                                                           value:nil] build]];
}
@end
