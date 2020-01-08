//
//  CollectionDataFile.m
//  EnShare
//
//  Created by Phil on 2016/10/20.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "OnLineDataFile.h"
#import "DataManager.h"

@implementation OnLineDataFile

-(id)initWithFileName:(NSString*)filename filePath:(NSString*)filePath type:(NSString*)type date:(NSDate*)date{
    if(self = [super init]){
        self.name = filename;
        self.filePath = filePath;
        if(type){
            self.type = type;
        }else{
            self.type = [[DataManager sharedInstance] getType:[filename pathExtension]];
        }
        self.createTime = date;
    }
    return self;
}

@end
