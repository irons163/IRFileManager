//
//  Database.m
//  IR_FileManager
//
//  Created by Phil on 2019/7/3.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "Database.h"

@implementation Database
@synthesize database;

- (id)init {
    if ((self = [super init])) {
        mutex = [[NSLock alloc] init];
        [self createEditableCopyOfDatabaseIfNeeded];
        //        [self checkTableExistsNewColumeAndAddIfFalseByTable:@"Collection" colume:@"count" byType:@"INTEGER" withDefault:@"0"]; //add count column
        //        [self checkTableExistsNewColumeAndAddIfFalseByTable:@"Collection" colume:@"isfavorite" byType:@"INTEGER" withDefault:@"0"];
        [self checkTableExistsNewColumeAndAddIfFalseByTable:@"Collection" colume:@"addfavoritetime" byType:@"TEXT" withDefault:@"0"];
    }
    return self;
}

- (void)createEditableCopyOfDatabaseIfNeeded {
    NSError *error;
    
    // Library 路徑
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // 資料庫路徑
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"database.sqlite"];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite"];
    
    // 移除舊資料庫
    if (![fileManager fileExistsAtPath:writableDBPath]) {
        // 覆製新資料庫
        if (! [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error])
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    // 開啟資料庫
    if (sqlite3_open([writableDBPath UTF8String], &database) != SQLITE_OK)
    NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
}

- (int)getSqliteInt:(NSString*)sql {
    int result = 0;
    @try {
        [mutex lock];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                result = sqlite3_column_int(statement, 0);
                break;
            }
        }
        sqlite3_finalize(statement);
        [mutex unlock];
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
    return result;
}

- (NSString*)getSqliteString:(NSString*)sql {
    NSString *result = nil;
    @try {
        [mutex lock];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                result = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
                break;
            }
        }
        sqlite3_finalize(statement);
        [mutex unlock];
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
    return result;
}

- (NSArray*)sqliteRead:(NSString*)sql {
    NSMutableArray *items = [NSMutableArray array];
    @try {
        [mutex lock];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            NSMutableDictionary *_keys = [NSMutableDictionary dictionary];
            for (int i = 0; i < sqlite3_column_count(statement); i++)
            [_keys setObject:[NSNumber numberWithInt:i] forKey:[NSString stringWithUTF8String:(char*)sqlite3_column_name(statement, i)]];
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSMutableDictionary *item = [NSMutableDictionary dictionary];
                for (id key in _keys.allKeys) {
                    char *txt = (char*)sqlite3_column_text(statement, [[_keys objectForKey:key] intValue]);
                    if (txt != nil)
                    [item setObject:[NSString stringWithUTF8String:txt] forKey:key];
                }
                [items addObject:item];
            }
        }
        sqlite3_finalize(statement);
        [mutex unlock];
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
    return items;
}

- (void)sqliteDelete:(NSString*)table keys:(NSDictionary*)keys {
    @try {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ ", table];
        if (keys.count > 0) {
            [sql appendString:@"WHERE "];
            int i = 0;
            for (NSString *key in keys.allKeys) {
                if (i == 0)
                [sql appendFormat:@"%@ = '%@' ", key, keys[key]];
                else
                [sql appendFormat:@"AND %@ = '%@' ", key, keys[key]];
                i++;
            }
            [sql appendString:@"; "];
        }
        char *errMsg;
        [mutex lock];
        sqlite3_exec(database, [sql UTF8String], nil, nil, &errMsg);
        [mutex unlock];
        //    assert(!errMsg);
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
}

- (void)sqliteInsert:(NSString*)table keys:(NSDictionary*)keys {
    @try {
        if (keys.count > 0) {
            NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", table];
            int i = 0;
            for (NSString *key in keys.allKeys) {
                if (i == 0)
                [sql appendFormat:@"'%@' ", key];
                else
                [sql appendFormat:@", '%@' ", key];
                i++;
            }
            [sql appendString:@") VALUES ( "];
            
            i = 0;
            for (NSString *key in keys.allKeys) {
                if (i == 0)
                [sql appendFormat:@"'%@' ", keys[key]];
                else
                [sql appendFormat:@", '%@' ", keys[key]];
                i++;
            }
            [sql appendString:@"); "];
            char *errMsg;
            [mutex lock];
            sqlite3_exec(database, [sql UTF8String], nil, nil, &errMsg);
            [mutex unlock];
            //        assert(!errMsg);
        }
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
}

- (void)sqliteUpdate:(NSString*)table keys:(NSDictionary*)keys params:(NSDictionary*)params {
    @try {
        if (keys.count > 0) {
            NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", table];
            int i = 0;
            for (NSString *param in params.allKeys) {
                if (i == 0)
                [sql appendFormat:@"%@ = '%@' ", param, params[param]];
                else
                [sql appendFormat:@", %@ = '%@' ", param, params[param]];
                i++;
            }
            [sql appendString:@"WHERE "];
            
            i = 0;
            for (NSString *key in keys.allKeys) {
                if (i == 0)
                [sql appendFormat:@"%@ = '%@' ", key, keys[key]];
                else
                [sql appendFormat:@"AND %@ = '%@' ", key, keys[key]];
                i++;
            }
            [sql appendString:@"; "];
            char *errMsg;
            [mutex lock];
            sqlite3_exec(database, [sql UTF8String], nil, nil, &errMsg);
            [mutex unlock];
            //        assert(!errMsg);
        }
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
}

- (void)sqliteExec:(NSString*)sql {
    @try {
        char *errMsg;
        [mutex lock];
        sqlite3_exec(database, [sql UTF8String], nil, nil, &errMsg);
        [mutex unlock];
        //    assert(!errMsg);
    }
    @catch (NSException* ex) {
        [mutex unlock];
    }
}

-(void)checkTableExistsNewColumeAndAddIfFalseByTable:(NSString*)table colume:(NSString*)column byType:(NSString*)type withDefault:(NSString*)defaultStr{
    if(![self checkColumnExistsInTable:table colume:column]){
        [self alterTable:table addColume:column byType:type withDefault:defaultStr];
    }
}

-(BOOL)checkColumnExistsInTable:(NSString*)table colume:(NSString*)column
{
    BOOL columnExists = NO;
    
    sqlite3_stmt *selectStmt;
    
    //    const char *sqlStatement = "select yourcolumnname from yourtable";
    NSMutableString *sqlStatement = [NSMutableString stringWithFormat:@"select %@ from %@;", column, table];
    if(sqlite3_prepare_v2(database, [sqlStatement UTF8String], -1, &selectStmt, NULL) == SQLITE_OK)
    columnExists = YES;
    
    return columnExists;
}

-(void)alterTable:(NSString*)table addColume:(NSString*)column byType:(NSString*)type withDefault:(NSString*)defaultStr
{
    //    [self sqliteExec:@"ALTER TABLE {tableName} ADD COLUMN COLNew {type};"];
    NSMutableString *sqlStatement = [NSMutableString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@ DEFAULT %@;", table, column, type, defaultStr];
    [self sqliteExec:sqlStatement];
}

@end
