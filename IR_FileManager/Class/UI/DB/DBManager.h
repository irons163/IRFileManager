//
//  DBManager.h
//  IR_FileManager
//
//  Created by Phil on 2020/1/21.
//  Copyright © 2020 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBManager : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+ (instancetype)sharedInstance;

- (NSString *)getNewFileNameIfExistsByFileName:(NSString *)fullfilename;
- (void)save;

@end

NS_ASSUME_NONNULL_END
