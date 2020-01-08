//
//  StaticLanguage.h
//  EnViewerSOHO
//
//  Created by sniApp on 2015/4/18.
//  Copyright (c) 2015年 sniApp. All rights reserved.
//

#import <Foundation/Foundation.h>

//Language Key
#define LANGUAGE_ENGLISH_SHORT_ID              @"en"
#define LANGUAGE_CHINESE_TRADITIONAL_SHORT_ID  @"zh-Hant"
#define LANGUAGE_CHINESE_SIMPLIFIED_SHORT_ID   @"zh-Hans"

#define SETTING_LANGUALE_KEY                @"SettingLanguages"

@interface StaticLanguage : NSObject{
    NSString        *currentLanguage;
    NSBundle        *currentLanguageBundle;
}

-(id) init UNAVAILABLE_ATTRIBUTE;
+(id) new UNAVAILABLE_ATTRIBUTE;

+(id)sharedInstance;

-(void)setLanguage:(NSString*)languageName;
-(NSString*)stringFor:(NSString*)srcString;

@property (nonatomic, strong) NSString        *currentLanguage;

-(NSBundle*)getCurrentBundle;

@end
