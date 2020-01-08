//
//  CollectionDataFile.h
//  EnShare
//
//  Created by Phil on 2016/10/20.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OnLineDataFile : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * size;
@property (nonatomic, strong) NSDate * createTime;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSString * filePath;
@property (nonatomic, strong) NSNumber * isFavorite;
@property (nonatomic) BOOL isFolder;

//-(id)initWithFileName:(NSString*)filename;
-(id)initWithFileName:(NSString*)filename filePath:(NSString*)filePath type:(NSString*)type date:(NSDate*)date;

@end
