//
//  CollectionDataFile.h
//  EnShare
//
//  Created by Phil on 2016/10/20.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CollectionDataFile : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * size;
@property (nonatomic, strong) NSDate * createTime;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSNumber * count;
@property (nonatomic, strong) NSString * uid;
@property (nonatomic, strong) NSString * addfavoritetime;

-(id)initWithDatabaseNSDictionary:(NSDictionary*)databaseReadResult fileSize:(NSNumber*)size fileCreatedDate:(NSDate*)date;

@end
