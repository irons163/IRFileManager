//
//  StaticLanguage.m
//  EnViewerSOHO
//
//  Created by sniApp on 2015/4/18.
//  Copyright (c) 2015年 sniApp. All rights reserved.
//

#import "StaticLanguage.h"
//#import "dataDefine.h"

static id master = nil;

@implementation StaticLanguage

@synthesize currentLanguage;

+(id)sharedInstance{
    if (!master) {
        master = [self alloc];
        master = [master init];
    }
    return master;
}

-(id)init{
    if ((self = [super init])) {
        currentLanguage = nil;
        currentLanguageBundle = nil;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        //if ([userDefaults objectForKey:SETTING_LANGUALE_KEY]) {
            NSString *path = [self getPathWithLanguage:[userDefaults objectForKey:SETTING_LANGUALE_KEY]];
            if (path) {
                currentLanguageBundle = [NSBundle bundleWithPath:path];
                currentLanguage = [userDefaults objectForKey:SETTING_LANGUALE_KEY];
            }else{
                [userDefaults removeObjectForKey:SETTING_LANGUALE_KEY];
                [userDefaults synchronize];
            }
        //}
    }
    return self;
}

-(void)setLanguage:(NSString *)languageName{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [self getPathWithLanguage:languageName];
    if (path) {
        currentLanguageBundle = [NSBundle bundleWithPath:path];
        currentLanguage = languageName;
        [userDefaults setObject:languageName forKey:SETTING_LANGUALE_KEY];
    }else{
        currentLanguage = nil;
        currentLanguageBundle = nil;
        [userDefaults removeObjectForKey:SETTING_LANGUALE_KEY];
    }
    [userDefaults synchronize];
}

-(NSString*)stringFor:(NSString *)srcString{
    if (currentLanguageBundle) {
        return NSLocalizedStringFromTableInBundle(srcString, nil, currentLanguageBundle, nil);
    }
    return NSLocalizedString(srcString, nil);
}

-(NSString*)getPathWithLanguage:(NSString *)languageName{
     return [[NSBundle mainBundle] pathForResource:LANGUAGE_ENGLISH_SHORT_ID ofType:@"lproj"];
    
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_EN", nil)])
    {
        return [[NSBundle mainBundle] pathForResource:LANGUAGE_ENGLISH_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_TC", nil)])
    {
        return [[NSBundle mainBundle] pathForResource:LANGUAGE_CHINESE_TRADITIONAL_SHORT_ID ofType:@"lproj"];
    }
//    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_SC", nil)])
//    {
//        return [[NSBundle mainBundle] pathForResource:LANGUAGE_CHINESE_SIMPLIFIED_SHORT_ID ofType:@"lproj"];
//    }
    return nil; //is Auto
}

-(NSBundle*)getCurrentBundle{
    return currentLanguageBundle;
}

@end
