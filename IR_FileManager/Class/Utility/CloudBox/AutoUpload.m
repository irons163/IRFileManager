//
//  AutoUpload.m
//  EnShare
//
//  Created by ke on 2014/2/5.
//  Copyright (c) 2014年 Senao. All rights reserved.
//

#import "AutoUpload.h"
#import "RouterGlobal.h"
#import "sys/utsname.h"
#import "SuccessView.h"
#import "KGModal.h"
#import "AFNetworking.h"
#import "dataDefine.h"
#import "DeviceClass.h"

@interface AutoUpload()

@property BOOL tagIfGo;//是否已經執行本程式
@property int callApiCount;//重複次數
@property (retain, nonatomic) NSMutableArray *albumArray;//儲存相片資料
@property int albumArrayCount;//上傳到哪一張
@property (retain, nonatomic) AFHTTPRequestOperation *uploadOperation;

@end

@implementation AutoUpload

+ (AutoUpload*)sharedInstance{
    static id sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [self alloc];
        sharedInstance = [sharedInstance init];
    }
    return sharedInstance;
}

- (id)init{
	if ((self = [super init])) {
        [self resetParams];
        _albumArray = [[NSMutableArray alloc] init];
        LogMessage(nil, 0, @"usb path : %@", [DataManager sharedInstance].diskPath);
	}
	return self;
}

//判斷資料夾名稱是否正確
//- (BOOL)checkUpload:(NSString*)folderName{
//    NSString *tag = [self createFolder:folderName];
//    if ([tag isEqualToString:@"OK"]) {
//        return YES;
//        //return NO;
//    }else{
//        return NO;
//    }
//}

- (void)doUpload:(NSString*)folderName{
    if (self.tagIfGo == NO) {
        self.tagIfGo = YES;
        [_albumArray removeAllObjects];
        
        [DataManager sharedInstance].autoUploadProgressFloat = 0;
        
        [self checkMacWithFolderName:folderName];
    }
}

-(void)isMainRouterWithFolderName:(NSString*)folderName{//表示是 Main Router
    [self createFolder:folderName];
}

-(void)finishcreateFolderWithFolderName:(NSString*)folderName Result:(NSString*)tag
{
    if ([tag isEqualToString:@"OK"]) {
        _callApiCount = 0;
        [self getAlbum:[self getSaveDate]];
        //[self getAlbum:nil];
        
    }else if ([tag isEqualToString:@"ERROR_FILE_EXISTED"] || [tag isEqualToString:@"ERROR_THE_SAME_FILE_NAME"]) {
        _callApiCount = 0;
        [self getAlbum:[self getSaveDate]];
        
    }else { //error or failure or disconnect
        //失敗的話，重新做，做三次就不做
        _callApiCount++;
        if (_callApiCount <= 3) {
            [self doUpload:folderName];
        }else{
            _callApiCount = 0;
            self.tagIfGo = NO;
            self.albumArrayCount = 0;
            [DataManager sharedInstance].autoUploadProgressFloat = -1;//網路有問題
        }
    }
}

-(void)notMainRouter{
    _callApiCount = 0;
    self.tagIfGo = NO;
    self.albumArrayCount = 0;
    [DataManager sharedInstance].autoUploadProgressFloat = -2;//非Main Router
}

//確認是不是第一次開啟，如果是將Mac Address存下來，並且判斷是不是同一個Mac Address
- (void)checkMacWithFolderName:(NSString*)folderName{
    RouterGlobal *global = [[RouterGlobal alloc] init];
    [global getDeviceSettings:^(NSDictionary *resultDictionary) {
        LogMessage(nil, 0, @"GetDeviceSettings result : %@", resultDictionary[@"WanMacAddress"]);
        
        if (resultDictionary[@"WanMacAddress"] == nil || [resultDictionary[@"WanMacAddress"] isEqualToString:@""]) { //網路不穩
            [self notMainRouter];
        }else{
            NSString *macAddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"macAddress"];
            if (macAddress == nil) {//第一次使用Auto Upload
                NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                [userDefault setObject:resultDictionary[@"WanMacAddress"] forKey:MAC_ADDRESS_KEY];
                [userDefault synchronize];
                
                [self isMainRouterWithFolderName:folderName];
            }else{//不是第一次使用
                if ([macAddress isEqualToString:resultDictionary[@"WanMacAddress"]]) {
                    [self isMainRouterWithFolderName:folderName];
                }else{
                    [self notMainRouter];
                }
            }
        }
    }];
}

- (void)createFolder:(NSString*)folderName{
    NSString *usbPath = [DataManager sharedInstance].diskPath;
    usbPath = [NSString stringWithFormat:@"%@/Album_Uploads/", usbPath];
    
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    NSString *jsonString = [NSString stringWithFormat:@"{\"UsbPath\":\"%@\",\"FolderName\":\"%@\"}", usbPath ,folderName];
    LogMessage(nil, 0, @"jsonString : %@", jsonString);
    [global createFolderWithJsonString:jsonString CompleteBlock:^(NSDictionary *resultDictionary) {
        LogMessage(nil, 0, @"CreateFolder result : %@", resultDictionary[CREATE_FOLDER_ACKTAG]);
        [self finishcreateFolderWithFolderName:folderName Result:resultDictionary[CREATE_FOLDER_ACKTAG]];
    }];
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

//取得相簿資料
- (void)getAlbum:(NSDate*)saveDate{
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && [[[UIDevice currentDevice] systemVersion] floatValue] < 8.1) {
        //notify user to upgrade iOS version
        
        [DataManager sharedInstance].autoUploadProgressFloat = -4;//無法取得相簿資料，only in iOS8~8.02
        return;
//        SuccessView *successView;;
//        VIEW(successView, SuccessView);
//        successView.infoLabel.text = NSLocalizedString(_(@"UPGRADE_OS"), nil);
//        [[KGModal sharedInstance] setShowCloseButton:FALSE];
//        [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];

    }

    ALAssetsLibrary *assetsLibrary = [AutoUpload defaultAssetsLibrary];
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
                        
                    }else{
                        //列舉完成時的處理常式
                        if ([_albumArray count] > 0) {
                            [self upload];
                        }else{
                            self.tagIfGo = NO;
                            [DataManager sharedInstance].autoUploadLeft = 0;//全部完成上傳
                        }
                    }
                }];
            }
            
        }else{
            //列舉完成時的處理常式
            //LogMessage(nil, 0, @"列舉完成時的處理常式");
        }
    }failureBlock:^(NSError *error) {
        //失敗處理常式
        LogMessage(nil, 0, @"%@", error);
        [DataManager sharedInstance].autoUploadProgressFloat = -3;//沒有開啟相簿權限
    }];
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
    NSString *dateName = [NSString stringWithFormat:@"%@", [UIDevice currentDevice].identifierForVendor.UUIDString];
    NSString *tDocPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *datePath = [NSString stringWithFormat:@"%@/%@", tDocPath, dateName];
    NSDate *tDate = [NSKeyedUnarchiver unarchiveObjectWithFile:datePath];
    NSLog(@"getSaveDate %@", tDate);
    return tDate;
}

- (void)upload{
    if(_albumArrayCount >= [_albumArray count] || _albumArrayCount < 0)
        return;
    NSDictionary *tDict = [_albumArray objectAtIndex:_albumArrayCount];
    NSString *fileUrl = [tDict objectForKey:@"FILE_URL"];
    NSString *fileName = [tDict objectForKey:@"FILE_NAME"];
    NSDate *fileDate = [tDict objectForKey:@"FILE_DATE"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), fileName];
    ALAssetRepresentation *assetRep = [tDict objectForKey:@"ASSET_REP"];
    
    LogMessage(nil, 0, @"fileUrl %@", fileUrl);
    
    [DataManager sharedInstance].autoUploadImage = [tDict objectForKey:@"THUMBNAIL"];
    [DataManager sharedInstance].autoUploadLeft = [_albumArray count] - _albumArrayCount;
    LogMessage(nil, 0, @"剩餘幾張 %d", [DataManager sharedInstance].autoUploadLeft);
    
    //複製照片或影片到本地端
    if ([fileUrl rangeOfString:@"ext=JPG"].length>0 || [fileUrl rangeOfString:@"ext=PNG"].length>0) {
        [self copyPhoto:nil tImageName:fileName assetRep:assetRep];
    }else if ([fileUrl rangeOfString:@"ext=MOV"].length>0 || [fileUrl rangeOfString:@"ext=mov"].length>0) {
        [self copyVideo:fileName assetRep:assetRep];
    }
    
    //上傳檔案
    [DataManager sharedInstance].autoUploadName = fileName;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self uploadFile:fileDate filePath:filePath fileName:fileName];
    });
}

//複製照片到tmp
- (void)copyPhoto:(UIImage*)image tImageName:(NSString*)tImageName assetRep:(ALAssetRepresentation*)assetRep{
    NSString *filename = [[tImageName pathComponents] lastObject];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    //[UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:YES];
    
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
    
    LogMessage(nil, 0, @"Photo Copy Success! %@", tImageName);
}

//複製影片到tmp
- (void)copyVideo:(NSString*)tImageName assetRep:(ALAssetRepresentation*)assetRep{
    NSString *filename = [[tImageName pathComponents] lastObject];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle) {
    }
    
    static const NSUInteger BufferSize = 1024*1024;
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    do {
        @try {
            bytesRead = [assetRep getBytes:buffer fromOffset:offset length:BufferSize error:nil];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            
            offset += bytesRead;
            //NSLog(@"%lu",(unsigned long)data.length);
        } @catch (NSException *exception) {
            break;
        }
    } while (bytesRead > 0);
    
    LogMessage(nil, 0, @"Video Copy Success! %@", tImageName);
}

- (void)uploadFile:(NSDate*)tDate filePath:(NSString*)filePath fileName:(NSString*)fileName{
    NSString *str = [NSString stringWithFormat:@"http://%@/upload.html", [[DeviceClass sharedInstance] getUploadUrl]]; //上傳位置 192.168.0.1:2000/upload.html
    LogMessage(nil, 0, @"url %@", str);
    
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    AFHTTPRequestSerializer* serializer = [AFHTTPRequestSerializer serializer];
    NSDictionary *params = @{@"page" : @"upload",
                             @"path" : [NSString stringWithFormat:@"/www%@/Album_Uploads/%@/%@",
                                        [DataManager sharedInstance].diskPath,
                                        [[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY],
                                        fileName],
                             @"totalsize" : [NSString stringWithFormat:@"%llu", fileSize]};
    
    //LogMessage(nil, 0, @"%@", params);
     NSURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST"
                                                              URLString:str
                                                             parameters:params
                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                  [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"webUpload" error:nil];
                                                  //LogMessage(nil, 0, @"%@", filename);
                                                  NSLog(@"FILENAME : %@", fileName);
                                              }
                                                                  error:nil];
    self.uploadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [self.uploadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = [operation responseString];
        LogMessage(nil, 0, @"response: %@", response);
        if ([[response lowercaseString] rangeOfString:@"success"].length>0) {
            //[self saveDate:tDate filePath:filePath fileName:fileName];
            _callApiCount = 0;
            [self saveDate:tDate];
            
            //上傳完之後，刪除暫存檔案
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            
            //表示已經傳完最後一張
            if (self.albumArrayCount == [self.albumArray count]-1) {
                self.tagIfGo = NO;
                self.albumArrayCount = 0;
                [DataManager sharedInstance].autoUploadLeft = 0;
            }
            //上傳成功才傳下一張
            else if (self.albumArrayCount < [self.albumArray count]-1) {
                if(!self.tagIfGo){
                    return; //if canceled, finish auto upload.
                }
                
                self.albumArrayCount++;
            
                //delay 2 秒
                int64_t delayInSeconds = 3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if(!self.tagIfGo){
                        return; //if canceled, finish auto upload.
                    }
                    [self upload];
                });
            }
        }else{
            //上傳失敗則重新傳一次
            //失敗的話，重新做，做三次就不做
            _callApiCount++;
            if (_callApiCount <= 3) {
                //delay 2 秒
                int64_t delayInSeconds = 3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self upload];
                });
            }else{
                _callApiCount = 0;
                self.tagIfGo = NO;
                self.albumArrayCount = 0;
                [DataManager sharedInstance].autoUploadProgressFloat = -1;//網路有問題
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        LogMessage(nil, 0, @"Error: %@", error);
        
        if ([error code]==-999) {//取消上傳
            self.tagIfGo = NO;
            self.albumArrayCount = 0;
            //}else ([error code]==-1001 || [error code]==-1005) {//網路有問題
        }else{
            [DataManager sharedInstance].autoUploadProgressFloat = -1;//網路有問題
            
            _callApiCount++;
            if (_callApiCount <= 3) {
                //delay 2 秒
                int64_t delayInSeconds = 3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self upload];
                });
            }else{
                _callApiCount = 0;
                self.tagIfGo = NO;
                self.albumArrayCount = 0;
                [DataManager sharedInstance].autoUploadProgressFloat = -1;//網路有問題
            }
        }
    }];
    [self.uploadOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) { //更新上傳的百分比
        //LogMessage(nil, 0, @"%d %@ %@", bytesWritten, @(totalBytesWritten), @(totalBytesExpectedToWrite));
        double progress = ((double)(totalBytesWritten) / (double)(totalBytesExpectedToWrite)) * 0.99;
        LogMessage(nil, 0, @"%f", progress);
        [DataManager sharedInstance].autoUploadProgressFloat = progress;
    }];
    [self.uploadOperation start];
}

//將照片的日期儲存到本機端的Document
- (void)saveDate:(NSDate*)tDate{
    NSString *dateName = [NSString stringWithFormat:@"%@", [UIDevice currentDevice].identifierForVendor.UUIDString];
    NSString *tDocPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *datePath = [NSString stringWithFormat:@"%@/%@", tDocPath, dateName];
    [NSKeyedArchiver archiveRootObject:tDate toFile:datePath];
}

- (void)cancelUpload{
    [self resetParams];
    [self.uploadOperation cancel];
}

- (void)resetParams{
    [DataManager sharedInstance].autoUploadLeft = -1; //not ready to upload
    _callApiCount = 0;
    self.tagIfGo = NO;
    self.albumArrayCount = 0;
}

@end
