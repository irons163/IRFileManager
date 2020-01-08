//
//  AutoSyncPhotos.m
//  EnShare
//
//  Created by Phil on 2016/11/14.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "AutoSyncPhotos.h"
#import "RouterGlobal.h"
#import "sys/utsname.h"
#import "SuccessView.h"
#import "KGModal.h"
#import "AFNetworking.h"
#import "dataDefine.h"
#import "DeviceClass.h"
#import "LoadingView.h"

@interface AutoSyncPhotos()

@property (retain, nonatomic) NSMutableArray *albumArray;//儲存相片資料
@property int albumArrayCount;//上傳到哪一張
@property (retain, nonatomic) AFHTTPRequestOperation *uploadOperation;

@end

@implementation AutoSyncPhotos

+ (AutoSyncPhotos*)sharedInstance{
    static id sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [self alloc];
        sharedInstance = [sharedInstance init];
    }
    return sharedInstance;
}

- (id)init{
    if ((self = [super init])) {
        _albumArray = [[NSMutableArray alloc] init];
        _albumArrayCount = 0;
    }
    return self;
}

#pragma mark - 取得ALAssetsLibrary
+ (ALAssetsLibrary *)defaultAssetsLibrary{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once (&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

-(void)doSync{
    self.albumArrayCount = 0;
    [self getAlbum:[self getSaveDate]];
}

//取得相簿資料
- (void)getAlbum:(NSDate*)saveDate{
    LoadingView *loadingView;;
    VIEW(loadingView, LoadingView);
    loadingView.title.text = _(@"SYNCING");
    [[KGModal sharedInstance] setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:loadingView andAnimated:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    ALAssetsLibrary *assetsLibrary = [AutoSyncPhotos defaultAssetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:_(@"All_Photos")] || [[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:_(@"CAMERA_ROLL")]) {
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                    if (asset != nil) {
                        NSMutableDictionary *tDict = [[NSMutableDictionary alloc] init];
                        
                        NSString *fileUrl = [NSString stringWithFormat:@"%@", [asset valueForProperty:@"ALAssetPropertyAssetURL"]];
                        NSDate *fileDate = [asset valueForProperty:@"ALAssetPropertyDate"];
                        NSString *fileName = [self getFileName:fileUrl fileDate:[NSString stringWithFormat:@"%@", [asset valueForProperty:@"ALAssetPropertyDate"]]];
                        fileName = [fileName stringByReplacingOccurrencesOfString:@" +0000" withString:@""];//過濾檔名的+0000
                        
                        /* //比較時間來判斷是否sync過
                        if (saveDate == nil || [saveDate compare:fileDate] == NSOrderedAscending) {//比較時間
                            ALAssetRepresentation *assetRep = [asset defaultRepresentation];
                            
                            //if ([fileUrl rangeOfString:@"ext=JPG"].length>0) {
                            [tDict setObject:fileUrl forKey:@"FILE_URL"];
                            [tDict setObject:fileDate forKey:@"FILE_DATE"];
                            [tDict setObject:[fileName stringByReplacingOccurrencesOfString:@":" withString:@""] forKey:@"FILE_NAME"];
                            [tDict setObject:assetRep forKey:@"ASSET_REP"];
                            [tDict setObject:[UIImage imageWithCGImage:asset.thumbnail] forKey:@"THUMBNAIL"];
                            [_albumArray addObject:tDict];
                            
                            LogMessage(nil, 0, @"%@", fileDate);
                            //}
                        }
                        */
                        
                        //比較Url來判斷是否sync過
                        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
                        
                        //if ([fileUrl rangeOfString:@"ext=JPG"].length>0) {
                        [tDict setObject:fileUrl forKey:@"FILE_URL"];
                        [tDict setObject:fileDate forKey:@"FILE_DATE"];
                        [tDict setObject:[fileName stringByReplacingOccurrencesOfString:@":" withString:@""] forKey:@"FILE_NAME"];
                        [tDict setObject:assetRep forKey:@"ASSET_REP"];
                        [tDict setObject:[UIImage imageWithCGImage:asset.thumbnail] forKey:@"THUMBNAIL"];
                        
                        
                        LogMessage(nil, 0, @"%@", fileDate);
                        //}
                        
                        NSArray* readFromDB = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Collection WHERE type = '%@' AND isfolder = '%@' AND uid = '%@'; ", @"PICTURE", @"0", fileUrl]];
                        if(readFromDB.count==0) // DB not exist this photo
                            [_albumArray addObject:tDict];
                        
                    }else{
                        //列舉完成時的處理常式
                        if ([_albumArray count] > 0) {
                            [self sync];
                        }
                    }
                }];
            }
            
        }else{
            //列舉完成時的處理常式
            //LogMessage(nil, 0, @"列舉完成時的處理常式");
            [[KGModal sharedInstance] hideAnimated:YES];
            [self.delegate syncFinishCallback];
        }
    }failureBlock:^(NSError *error) {
        //失敗處理常式
        LogMessage(nil, 0, @"%@", error);
        [[KGModal sharedInstance] hideAnimated:YES];
        [self.delegate syncFinishCallback];
    }];
        
    });
}

- (NSString*)getFileName:(NSString*)URL fileDate:(NSString*)fileDate{
    NSString *fileId = nil, *fileExt = nil;
    
    NSString *tURL = [URL copy];
    
    NSRange po = [URL rangeOfString:@"?"];
    if(po.location>0){
        fileId = [URL substringFromIndex:po.location];
    }
    
    po = [tURL rangeOfString:@"&"];
    if(po.location>0){
        tURL = [tURL substringFromIndex:po.location];
        fileExt = [[tURL stringByReplacingOccurrencesOfString:@"&ext="withString:@""] lowercaseString];
    }
    
    return [NSString stringWithFormat:@"%@.%@", fileDate, fileExt];
}

//取得上次上傳到哪一張照片
- (NSDate*)getSaveDate{
    NSString *dateName = [NSString stringWithFormat:@"%@_SyncToCollection", [UIDevice currentDevice].identifierForVendor.UUIDString];
    NSString *tDocPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *datePath = [NSString stringWithFormat:@"%@/%@", tDocPath, dateName];
    NSDate *tDate = [NSKeyedUnarchiver unarchiveObjectWithFile:datePath];
    NSLog(@"getSaveDate %@", tDate);
    return tDate;
}

- (void)sync{
    NSDictionary *tDict = [_albumArray objectAtIndex:_albumArrayCount];
    NSString *fileUrl = [tDict objectForKey:@"FILE_URL"];
    NSString *fileName = [tDict objectForKey:@"FILE_NAME"];
    NSDate *fileDate = [tDict objectForKey:@"FILE_DATE"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), fileName];
    ALAssetRepresentation *assetRep = [tDict objectForKey:@"ASSET_REP"];
    
    LogMessage(nil, 0, @"fileUrl %@", fileUrl);
    
    //複製照片到本地端
    if ([fileUrl rangeOfString:@"ext=JPG"].length>0 || [fileUrl rangeOfString:@"ext=PNG"].length>0) {
        [self copyPhoto:nil tImageName:fileName assetRep:assetRep fileUrl:fileUrl];
        [self saveDate:fileDate];
    }
    
     if (self.albumArrayCount < [self.albumArray count]-1) {
        self.albumArrayCount++;
         [self sync];
        
     }else{
        [_albumArray removeAllObjects];
     }
}

//複製照片到本地端
- (void)copyPhoto:(UIImage*)image tImageName:(NSString*)tImageName assetRep:(ALAssetRepresentation*)assetRep fileUrl:(NSString*)fileUrl{
    NSString *filename = [[tImageName pathComponents] lastObject];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    //[UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:YES];
    
    filename = [self getNewFileNameIfExistsByFileName:filename];
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    NSOutputStream *outPutStream = [NSOutputStream outputStreamToFileAtPath:path append:YES];
    [outPutStream open];
    
    long long offset = 0;
    long long bytesRead = 0;
    NSError *error;
    uint8_t * buffer = malloc(131072);
    while (offset<[assetRep size] && [outPutStream hasSpaceAvailable]) {
        bytesRead = [assetRep getBytes:buffer fromOffset:offset length:131072 error:&error];
        [outPutStream write:buffer maxLength:bytesRead];
        offset = offset+bytesRead;
    }
    [outPutStream close];
    free(buffer);
    
    //存入到資料庫
    [[DataManager sharedInstance].database sqliteInsert:@"Collection" keys:@ {
        @"uid" : fileUrl,
        @"type" : [[DataManager sharedInstance] getType:[filename pathExtension]],
        @"filename" : [filename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        @"isdownload" : @"1",
        @"isfolder" : @"0",
        @"parentfolder" : @"/"
    }];
    
    LogMessage(nil, 0, @"Photo Copy Success! %@", filename);
}

-(NSString*)getNewFileNameIfExistsByFileName:(NSString*)fullfilename{
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
                LogMessage(nil, 0, @"%@", newFilename);
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
            LogMessage(nil, 0, @"%@", newFilename);
            
        }
        
        return newFilename;
    }
}

-(BOOL)checkExistWithFileName:(NSString*)fullfilename{
    NSString *uid = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT uid FROM Collection WHERE type = '%@' AND filename = '%@'; ", [[DataManager sharedInstance] getType:[fullfilename pathExtension]], fullfilename]];
    if (uid.length == 0)
        return NO;
    return YES;
}

//將照片的日期儲存到本機端的Document
- (void)saveDate:(NSDate*)tDate{
    NSString *dateName = [NSString stringWithFormat:@"%@_SyncToCollection", [UIDevice currentDevice].identifierForVendor.UUIDString];
    NSString *tDocPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *datePath = [NSString stringWithFormat:@"%@/%@", tDocPath, dateName];
    [NSKeyedArchiver archiveRootObject:tDate toFile:datePath];
}

@end

