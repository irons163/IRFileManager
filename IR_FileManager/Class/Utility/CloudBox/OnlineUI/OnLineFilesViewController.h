//
//  OnLineFilesViewController.h
//  EnShare
//
//  Created by Phil on 2016/11/29.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KGModal.h"
#import "NSString+URLEncoding.h"
#import "dataDefine.h"
#import "OnLineDataFile.h"
#import "LayoutGuildReplaceViewController.h"

@interface OnLineFilesViewController : LayoutGuildReplaceViewController{
    NSMutableArray *taskes;
    NSMutableDictionary *results;
    
    NSMutableArray *items;
    NSMutableArray* selectedItems;
    NSMutableArray *favorites;
}

typedef enum{
    DOCUMENT_TYPE = 0,
    MUSIC_TYPE,
    VIDEO_TYPE,
    PHOTO_TYPE,
    ALL_TYPE
}FILE_TYPE;

@property (nonatomic) FILE_TYPE fileType;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) NSString *path;

//- (void)resetTask;
- (bool)doTask ;
- (void)reloadData;
- (OnLineDataFile*)addObjectToItems:(NSString*)obj isFolder:(BOOL)isFolder;
- (void)showWarnning:(NSString*)info;
- (void)switchFromDeleteToNormalMode;
- (void)checkFavorite;
- (void)saveFavoriteByRemove:(NSString*)file;
- (void)saveFavoriteByAdd:(NSString*)file;
- (void)loadData;
- (void)deleteByFileName:(NSMutableArray*)oriDfiles :(int)count;
- (void)backToLoginPage;
@end
