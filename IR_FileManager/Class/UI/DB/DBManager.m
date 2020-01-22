//
//  DBManager.m
//  IR_FileManager
//
//  Created by Phil on 2020/1/21.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "DBManager.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation DBManager

+ (instancetype)sharedInstance {
    static DBManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        
    }
    return self;
}

- (NSString *)getNewFileNameIfExistsByFileName:(NSString *)fullfilename {
    if (![self checkExistWithFileName:fullfilename]) {
        return fullfilename;
    }else{
        
        NSString *filenameWithOutExtension = [fullfilename stringByDeletingPathExtension];
        NSString *ext = [fullfilename pathExtension];
        
        int limit = 999;
        NSString* newFilename;
        for(int i = 0; i < limit; i++){
            newFilename = [NSString stringWithFormat:@"%@(%d).%@", filenameWithOutExtension, i+1, ext];
            if(![self checkExistWithFileName:newFilename]){
                NSLog(nil, 0, @"%@", newFilename);
                break;
            }
        }
        
        if(newFilename==nil){
            
             NSString *ext = [NSString stringWithFormat:@".%@",[fullfilename pathExtension]];
             NSString *fileName = [[fullfilename lastPathComponent] stringByDeletingPathExtension];
             NSString *folder = [fullfilename stringByReplacingOccurrencesOfString:fileName withString:@""];
             folder = [folder stringByReplacingOccurrencesOfString:ext withString:@""];
             
             NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
             NSDate *date = [NSDate date];
             [formatter setDateFormat:@"YYYYMMddhhmmss'"];
             NSString *today = [formatter stringFromDate:date];
             
             newFilename = [NSString stringWithFormat:@"%@%@_%@.%@", folder, fileName, today, [fullfilename pathExtension]];
             NSLog(@"%@", newFilename);
            
        }
        
        return newFilename;
    }
}

- (BOOL)checkExistWithFileName:(NSString *)fullfilename {
    /*
    NSString *uid = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT uid FROM Collection WHERE type = '%@' AND filename = '%@'; ", [[DataManager sharedInstance] getType:[fullfilename pathExtension]], fullfilename]];
    if (uid.length == 0)
        return NO;
    return YES;
     */
    return NO;
}

- (void)save {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"You successfully saved your context.");
            } else if (error) {
                NSLog(@"Error saving context: %@", error.description);
            }
        }];
    });
}

@end
