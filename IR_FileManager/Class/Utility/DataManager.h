//
//  DataManager.h
//  IR_FileManager
//
//  Created by Phil on 2019/7/3.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataManager : NSObject

+ (instancetype)sharedInstance;
- (NSString*)getType:(NSString*)ext;

@property (strong, nonatomic) Database *database;
@property BOOL isAudioPlaying;//是否正在播音樂
@end

NS_ASSUME_NONNULL_END
