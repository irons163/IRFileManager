//
//  Database.h
//  IR_FileManager
//
//  Created by Phil on 2019/7/3.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface Database : NSObject {
    NSLock *mutex;
}

@property (nonatomic) sqlite3 *database;

- (int)getSqliteInt:(NSString*)sql;
- (NSString*)getSqliteString:(NSString*)sql;
- (NSArray*)sqliteRead:(NSString*)sql;
- (void)sqliteDelete:(NSString*)table keys:(NSDictionary*)keys;
- (void)sqliteInsert:(NSString*)table keys:(NSDictionary*)keys;
- (void)sqliteUpdate:(NSString*)table keys:(NSDictionary*)keys params:(NSDictionary*)params;
- (void)sqliteExec:(NSString*)sql;

@end

NS_ASSUME_NONNULL_END
