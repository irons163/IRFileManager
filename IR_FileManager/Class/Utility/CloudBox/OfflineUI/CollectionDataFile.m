//
//  CollectionDataFile.m
//  EnShare
//
//  Created by Phil on 2016/10/20.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "CollectionDataFile.h"

@implementation CollectionDataFile

-(id)initWithDatabaseNSDictionary:(NSDictionary*)databaseReadResult fileSize:(NSNumber*)size fileCreatedDate:(NSDate*)date{
    if(self = [super init]){
        self.name = databaseReadResult[@"filename"];
        self.size = size;
        self.createTime = date;
        self.type = databaseReadResult[@"type"];
        self.count = databaseReadResult[@"count"];
        self.uid = databaseReadResult[@"uid"];
        self.addfavoritetime = databaseReadResult[@"addfavoritetime"];
    }
    return self;
}

@end
