//
//  SenaoGA.h
//  EnMesh
//
//  Created by Titan Chen on 2016/4/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <Google/Analytics.h>

@interface SenaoGA : NSObject{

}

+(void)setScreenName:(NSString*)screenName;
+(void)setEvent:(NSString*)category Action:(NSString*)action Label:(NSString*)label Value:(NSString*)value;
+(void)simpleSetAction:(NSString*)action;
@end
