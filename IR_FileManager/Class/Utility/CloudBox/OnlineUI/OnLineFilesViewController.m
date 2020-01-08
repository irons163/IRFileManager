//
//  OnLineFilesViewController.m
//  EnShare
//
//  Created by Phil on 2016/11/29.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "OnLineFilesViewController.h"
#import "DataManager.h"
#import "DeviceClass.h"
#import "SuccessView.h"
#import "DialogView.h"
#import "AppDelegate.h"

@interface OnLineFilesViewController (){
    
}

@end

@implementation OnLineFilesViewController{

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    taskes = [[NSMutableArray alloc] init];
    results = [[NSMutableDictionary alloc] init];
    favorites = [NSMutableArray array];
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.loadingView setCenter:CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2)];
    [self.view addSubview:self.loadingView];
    
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
}

- (void)reloadData{
    [items removeAllObjects];
    [self resetTask];
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.loadingView.hidden = NO;
    [self doTask];
}

-(void)backToLoginPage{
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Task
- (void)resetTask {
    [taskes removeAllObjects];
    if ([self getTypeStringByFileType:self.fileType].length > 0) {
        [taskes addObject:@ { @"api" : GET_STORAGE_INFO_COMMAND,
            @"callback" : [NSNumber numberWithUnsignedInteger:GET_STORAGE_INFO_CALLBACK] }];
        [taskes addObject:@ { @"api" : CHECK_GENERATE_PROCESS_BY_TYPE_COMMAND,
            @"body" : [NSString stringWithFormat:@"{\"FileType\":\"%@\"}", @"MUSIC"],
            @"callback" : [NSNumber numberWithUnsignedInteger:CHECK_GENERATE_PROCESS_BY_TYPE_CALLBACK] }];
        [taskes addObject:@ { @"api" : GET_FILE_LIST_BY_TYPE_COMMAND ,
            @"callback" : [NSNumber numberWithUnsignedInteger:GET_FILE_LIST_BY_TYPE_CALLBACK]} ];
    } else {
        [taskes addObject:@ { @"api" : GET_STORAGE_INFO_COMMAND,
            @"callback" : [NSNumber numberWithUnsignedInteger:GET_STORAGE_INFO_CALLBACK] } ];
        [taskes addObject:@ { @"api" : GET_FILELIST_UNDER_FOLDER_IN_FILE_COMMAND,
            @"body" : [NSString stringWithFormat:@"{\"CurrentFolderPath\":\"%@\"}", self.path],
            @"callback" : [NSNumber numberWithUnsignedInteger:GET_FILELIST_UNDER_FOLDER_IN_FILE_CALLBACK] } ];
    }
}

//取得資料
- (bool)doTask {
    if (taskes.count > 0) {
        NSDictionary *task = taskes[0];
        
        NSString *method = @"GET";
        NSString *body = nil;
        if ([task[@"body"] length] > 0) {
            body = task[@"body"];
            method = @"POST";
        } else if ([task[@"api"] isEqualToString:GET_FILE_LIST_BY_TYPE_COMMAND]) {
            if (results[GET_STORAGE_INFO_COMMAND] != nil) {
                @try {
                    if ([DataManager sharedInstance].diskPath != nil) {
                        if([self getTypeStringByFileType:self.fileType].length > 0){
                            body = [NSString stringWithFormat:@"{\"FileType\":\"%@\",\"UsbPath\":\"%@\"}", [self getTypeStringByFileType:self.fileType], [DataManager sharedInstance].diskPath];
                        }else{
                            body = [NSString stringWithFormat:@"{\"FileType\":\"%@\",\"UsbPath\":\"%@\"}", task[@"object"], [DataManager sharedInstance].diskPath];
                        }
                    }else{
                        if([self getTypeStringByFileType:self.fileType].length > 0){
                            body = [NSString stringWithFormat:@"{\"FileType\":\"%@\",\"UsbPath\":\"%@\"}", [self getTypeStringByFileType:self.fileType], results[@"GetStorageInfo"][@"StorageInformation"][0][@"UsbPath"]];
                        }else{
                            body = [NSString stringWithFormat:@"{\"FileType\":\"%@\",\"UsbPath\":\"%@\"}", task[@"object"], results[@"GetStorageInfo"][@"StorageInformation"][0][@"UsbPath"]];
                        }
                        
                        [DataManager sharedInstance].diskPath = results[GET_STORAGE_INFO_COMMAND][@"StorageInformation"][0][@"UsbPath"];
                        [DataManager sharedInstance].diskGuestPath = results[GET_STORAGE_INFO_COMMAND][0][@"UsbGuestPath"];
                    }
                    
                    if ([[DeviceClass sharedInstance] isAdminUser]) {
                        [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskPath;
                    }else{//guest
                        [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskGuestPath;
                    }
                    
                }
                @catch (NSException* ex) { }
            }
            method = @"POST";
        } else if ([task[@"api"] isEqualToString:@"GetFavoriteListByType"]) {
            if (results[@"GetStorageInfo"] != nil) {
                body = [NSString stringWithFormat:@"{\"FileType\":\"%@\"}", [self getTypeStringByFileType:self.fileType]];
            }
            method = @"POST";
        }
        
        //LogMessage(nil, 0, @"%@\n%@\n%@", str, method, body);
        NSLog(@"%@\n%@\n%@", task[@"api"], method, body);
        
        [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:task[@"api"]
                                                              Method:method
                                                                Body:body
                                                          CallbackID:[task[@"callback"] unsignedIntegerValue]
                                                              Target:self];
    } else {
        NSLog(@"處理完成");
        
        //確認最愛檔案是否有在USB內
        [self checkFavorite];
        
        [self.loadingView stopAnimating];
        [self.view setUserInteractionEnabled:YES];
        self.loadingView.hidden = YES;
        
        return true;
    }
    
    return false;
}

-(OnLineDataFile*)addObjectToItems:(NSString*)obj isFolder:(BOOL)isFolder{
    NSArray *parts = [obj componentsSeparatedByString:@"/"];
    NSString *fileName = [parts lastObject];
    
    OnLineDataFile* file = [[OnLineDataFile alloc] initWithFileName:fileName filePath:obj type:[self getTypeStringByFileType:self.fileType] date:[NSDate date]];
    file.isFolder = isFolder;
    [items addObject:file];
    
    return file;
}

-(NSString*)getTypeStringByFileType:(FILE_TYPE)fileType{
    NSString* typeString = nil;
    switch (fileType) {
        case DOCUMENT_TYPE:
            typeString = @"DOCUMENT";
            break;
        case MUSIC_TYPE:
            typeString = @"MUSIC";
            break;
        case VIDEO_TYPE:
            typeString = @"VIDEO";
            break;
        case PHOTO_TYPE:
            typeString = @"PICTURE";
            break;
        default:
            break;
    }
    return typeString;
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

- (void)showWarnning:(NSString*)title info:(NSString*)info{
    DialogView *dialogView;;
    VIEW(dialogView, DialogView);
    dialogView.titleNameLbl.text = NSLocalizedString(title, nil);
    dialogView.titleLbl.text = NSLocalizedString(info, nil);
    [dialogView.titleLbl setFont:[UIFont systemFontOfSize:12]];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:dialogView andAnimated:YES];
}

-(void)addItme{
    if(self.fileType != ALL_TYPE){
        // 下載檔案列表
        NSDictionary *item = results[@"GetFileListByType"];
        NSString *str = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], item[@"FileListPath"]];
        //LogMessage(nil, 0, @"URL : %@", str);
        NSLog(@"URL : %@",str);
        
        NSURL *url = [NSURL URLWithString:str];
        NSString *webData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        if (webData == NULL) {
            for (int i= 0; i < 3; i++) {
                NSLog(@"Re Get Webdata !!");
                webData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
                if (webData != NULL) {
                    break;
                }
            }
        }
        
        NSLog(@"WebData : %@",webData);
        
        NSString *files = webData;
        for (NSString *file in [files componentsSeparatedByString:@"\n"]) {
            if (file.length > 0) {
                NSLog(@"下載檔案列表 file : %@", file);
                if ([[DeviceClass sharedInstance] isAdminUser]) {
                    [self addObjectToItems:file isFolder:NO];
                }else{//guest
                    if ([file rangeOfString: [DataManager sharedInstance].diskGuestPath].length>0) {
                        [self addObjectToItems:file isFolder:NO];
                    }
                }
            }
        }
    }else{
        // 下載檔案列表
        NSString *fileListName = @"current_folder_file_list";
        NSString *fileListURLString = [NSString stringWithFormat:@"http://%@/%@", [[DeviceClass sharedInstance] getDownloadUrl], fileListName];
        NSLog(@"URL : %@",fileListURLString);
        
        NSURL *url = [NSURL URLWithString:fileListURLString];
        NSString *webData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        if (webData == NULL) {
            for (int i= 0; i < 3; i++) {
                NSLog(@"Re Get Webdata !!");
                webData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
                if (webData != NULL) {
                    break;
                }
            }
        }
        
        NSLog(@"WebData : %@",webData);
        
        NSString *pattern = @"^\\S{10,} +\\d+ \\w+ +\\w+ +[0-9.]+[A-Z]* [a-zA-Z]{3} +\\d+ +[0-9:]{4,}+ ";
        NSString *files = webData;
        for (NSString *fileInfo in [files componentsSeparatedByString:@"\n"]) {
            if (fileInfo.length > 0) {
                NSRange searchedRange = NSMakeRange(0, [fileInfo length]);
                NSError *error = nil;
                NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
                NSTextCheckingResult *match = [regex firstMatchInString:fileInfo options:0 range: searchedRange];
//                NSLog(@"fileInfo : %@", fileInfo);
                NSUInteger index = NSMaxRange([match rangeAtIndex:0]);
                
                NSString *filename = [fileInfo substringFromIndex:index];
                if([filename hasPrefix:@"."])
                    continue;
                filename = [NSString stringWithFormat:@"%@/%@", self.path, filename];
                
                regex = [NSRegularExpression regularExpressionWithPattern:@" +" options:0 error:NULL];
                NSString *newString = [regex stringByReplacingMatchesInString:fileInfo options:0 range:NSMakeRange(0, fileInfo.length) withTemplate:@" "];
                NSArray *parts = [newString componentsSeparatedByString:@" "];
                NSString *permissionsStr = parts[0];
                NSString *sizeStr = parts[4];
                
                BOOL isFolder;
                if([permissionsStr hasPrefix:@"d"])
                    isFolder = YES;
                else
                    isFolder = NO;
                
                OnLineDataFile *file = [self addObjectToItems:filename isFolder:isFolder];
                
                long size = 0;
                if([sizeStr containsString:@"G"]){
                    size = [[sizeStr substringToIndex:sizeStr.length -1] doubleValue] * 1024 * 1024 * 1024;
                }if([sizeStr containsString:@"M"]){
                    size = [[sizeStr substringToIndex:sizeStr.length -1] doubleValue] * 1024 * 1024;
                }if([sizeStr containsString:@"K"]){
                    size = [[sizeStr substringToIndex:sizeStr.length -1] doubleValue] * 1024;
                }else{
                    size = [sizeStr intValue];
                }
                
                file.size = [NSNumber numberWithLong:size];
            }
        }
    }
}

- (void)delete:(NSArray*)dfiles {
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.loadingView.hidden = NO;
    
    NSMutableArray *deleteItems = [NSMutableArray array];
    for (OnLineDataFile* file in dfiles){
        [deleteItems addObject:file.filePath];
    }
    [self deleteByFileName:[NSMutableArray arrayWithArray:deleteItems] :0];
}

#pragma mark - StaticHttpRequestDelegate
-(void)didFinishStaticRequestJSON:(NSDictionary *)strAckResult CommandIp:(NSString *)ip CommandPort:(int)port CallbackID:(NSUInteger)callback{
    if (callback == GET_STORAGE_INFO_CALLBACK)
    {
        if ([strAckResult[GET_STORAGE_INFO_ACKTAG] isEqualToString:@"OK"]) {
            if ([strAckResult objectForKey:@"StorageInformation"] && [(NSDictionary*)[strAckResult objectForKey:@"StorageInformation"] count] == 0) {
                
                [self showWarnning:_(@"USB")];
                [self.navigationController popToRootViewControllerAnimated:YES];
                return;
            }else if (![[DeviceClass sharedInstance] isTunnelUsed] &&
                [[strAckResult objectForKey:@"RemoteAccess"] isEqualToString:@"DISABLE"] &&
                ![[[DeviceClass sharedInstance] commandDeviceAddress] isEqualToString:ip]) {
                
                [self showWarnning:_(@"RemoteAccess Title") info:_(@"RemoteAccess")];
                
                [self.navigationController popToRootViewControllerAnimated:YES];
                return;
            }
            
            if(taskes.count > 0)
                [taskes removeObjectAtIndex:0];
            [results setObject:strAckResult forKey:GET_STORAGE_INFO_COMMAND];
            [items removeAllObjects];
            dispatch_async(dispatch_get_main_queue(),^{
                [self doTask];
            });
            return;
        }
    }
    else if (callback == GET_FILE_LIST_BY_TYPE_CALLBACK)
    {
        if ([strAckResult[GET_FILE_LIST_BY_TYPE_ACKTAG] isEqualToString:@"OK"]) {
            if(taskes.count > 0)
                [taskes removeObjectAtIndex:0];
            [results setObject:strAckResult forKey:GET_FILE_LIST_BY_TYPE_COMMAND];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                if ([self getTypeStringByFileType:self.fileType].length > 0) {
                    [self addItme];
                } else {
                    [self addItme];
                }
                
                dispatch_async(dispatch_get_main_queue(),^{
                    [self doTask];
                });
            });
            return;
        }else if ([strAckResult[GET_FILE_LIST_BY_TYPE_ACKTAG] isEqualToString:@"ERROR"]) {
            if(taskes.count > 0)
                [taskes removeObjectAtIndex:0];
            dispatch_async(dispatch_get_main_queue(),^{
                [self doTask];
            });
            return;
        }
    }
    else if (callback == GET_FILELIST_UNDER_FOLDER_IN_FILE_CALLBACK)
    {
        if ([strAckResult[GET_FILELIST_UNDER_FOLDER_IN_FILE_ACKTAG] isEqualToString:@"OK"]) {
            if(taskes.count > 0)
                [taskes removeObjectAtIndex:0];
            [results setObject:strAckResult forKey:GET_FILELIST_UNDER_FOLDER_IN_FILE_COMMAND];
            
            [self addItme];
            dispatch_async(dispatch_get_main_queue(),^{
                [self doTask];
            });

            return;
        }else if ([strAckResult[GET_FILELIST_UNDER_FOLDER_IN_FILE_ACKTAG] isEqualToString:@"ERROR"]) {
            //            [self.loadingView stopAnimating];
            //            [self.view setUserInteractionEnabled:YES];
            //            self.loadingView.hidden = YES;
            return;
        }
    }
    else if (callback == GENERATE_FILE_LIST_BY_TYPE_CALLBACK)
    {
        return;
    }
    else if (callback == CHECK_GENERATE_PROCESS_BY_TYPE_CALLBACK)
    {
        if([strAckResult[CHECK_GENERATE_PROCESS_BY_TYPE_ACKTAG] isEqualToString:@"OK"]) {
            if(taskes.count > 0)
                [taskes removeObjectAtIndex:0];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [self doTask];
            });
        }else{
            [self showWarnning:_(@"GenerateProcessingTitle") info:_(@"GenerateProcessing")];
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        return;
    }
    else if (callback == DELETE_FILE_BY_NAME_CALLBACK)
    {
        NSArray* brokenFileArray = strAckResult[@"BrokenFileList"];
        NSLog(@"%d",[brokenFileArray count]);
        if ([strAckResult[DELETE_FILE_BY_NAME_ACKTAG] isEqualToString:@"OK"] ||
            [strAckResult[DELETE_FILE_BY_NAME_ACKTAG] isEqualToString:@"ERROR_FILE_NOT_EXISTED"] ||
            [brokenFileArray count] > 0)
        {
            NSArray* dfiles;
            NSRange r;
            
            NSMutableString *files_lists_music = [NSMutableString string];
            NSMutableString *files_lists_document = [NSMutableString string];
            NSMutableString *files_lists_video = [NSMutableString string];
            NSMutableString *files_lists_picture = [NSMutableString string];
            
            if ([selectedItems count] >= DELETE_LIMIT) {
                r.location = 0;
                r.length = DELETE_LIMIT;
                dfiles = [selectedItems subarrayWithRange:r];
            }else{
                dfiles = selectedItems;
            }
            NSString *listFile = nil;
            for (NSString *file_ in dfiles) {
                if (![brokenFileArray containsObject:file_]) {
                    if (self.fileType == MUSIC_TYPE || [[[DataManager sharedInstance] getType:[file_ pathExtension]] isEqualToString:@"MUSIC"]) {
                        //確認最愛檔案是否有在USB內
                        [self checkFavorite];
                        
                        [self saveFavoriteByRemove:file_];
                        
                    }
                    
                    if ([file_ hasPrefix:@"http"])
                        listFile = [file_ stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://%@", [[DeviceClass sharedInstance] getDownloadUrl]] withString:@""];
                    else
                        listFile = file_;
                    
                    if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"MUSIC"]) {
                        if (files_lists_music.length == 0) {
                            [files_lists_music appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                        }else{
                            [files_lists_music appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                        }
                    }else if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"DOCUMENT"]){
                        if (files_lists_document.length == 0) {
                            [files_lists_document appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                        }else{
                            [files_lists_document appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                        }
                    }else if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"VIDEO"]){
                        if (files_lists_video.length == 0) {
                            [files_lists_video appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                        }else{
                            [files_lists_video appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                        }
                    }else if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"PICTURE"]){
                        if (files_lists_picture.length == 0) {
                            [files_lists_picture appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                        }else{
                            [files_lists_picture appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                        }
                    }
                }
            }
            
            if (files_lists_music.length > 0) {
                [self deleteFileList:files_lists_music :@"MUSIC"];
            }
            
            if (files_lists_document.length > 0) {
                [self deleteFileList:files_lists_document :@"DOCUMENT"];
            }
            
            if (files_lists_video.length > 0) {
                [self deleteFileList:files_lists_video :@"VIDEO"];
            }
            
            if (files_lists_picture.length > 0) {
                [self deleteFileList:files_lists_picture :@"PICTURE"];
            }
            
            if ([brokenFileArray count]>0) {
//                [self reloadData];
                //[[KGModal sharedInstance] hideAnimated:YES];
                [self showWarnning:_(@"Operation_Failed")];
                /*
                 if (editBtn.selected) {
                 [self editClk:nil];//關閉修改模式
                 }*/
                [self switchFromDeleteToNormalMode];
            }else{
                if ([dfiles count] < DELETE_LIMIT) {
//                    [self reloadData];
                    //[[KGModal sharedInstance] hideAnimated:YES];
                    [self showWarnning:_(@"DELETE_ALERT")];
                    /*
                     if (editBtn.selected) {
                     [self editClk:nil];//關閉修改模式
                     }*/
                    [self switchFromDeleteToNormalMode];
                }else{
                    [selectedItems removeObjectsInRange:r];
                    [self deleteByName:selectedItems :0];
                }
            }
        }
        else
        {
            [self showWarnning:_(@"Operation_Failed")];
            [self switchFromDeleteToNormalMode];
        }
        
        return;
    }
    else if (callback == DELETE_FILE_BY_FILE_NAME_CALLBACK)
    {
        NSArray* brokenFileArray = strAckResult[@"BrokenFileList"];
        if ([strAckResult[@"DeleteFileByFileNameResult"] isEqualToString:@"OK"] ||
            [strAckResult[@"DeleteFileByFileNameResult"] isEqualToString:@"ERROR_FILE_NOT_EXISTED"] ||
            [brokenFileArray count] > 0)
        {
            NSArray* dfiles;
            NSRange r;
            
            if ([selectedItems count] >= DELETE_LIMIT) {
                r.location = 0;
                r.length = DELETE_LIMIT;
                dfiles = [selectedItems subarrayWithRange:r];
            }else{
                dfiles = selectedItems;
            }
            
            NSMutableString *files_lists = [NSMutableString string];
            NSMutableString *files_lists_music = [NSMutableString string];
            NSMutableString *files_lists_document = [NSMutableString string];
            NSMutableString *files_lists_video = [NSMutableString string];
            NSMutableString *files_lists_picture = [NSMutableString string];
            
            NSString *listFile = nil;
            
            for (NSString *file_ in dfiles) {
                if (![brokenFileArray containsObject:file_]) {
//                    if (self.fileType == MUSIC_TYPE || [[[DataManager sharedInstance] getType:[file_ pathExtension]] isEqualToString:@"MUSIC"]) {
                        //確認最愛檔案是否有在USB內
                        [self checkFavorite];
                        
                        [self saveFavoriteByRemove:file_];
//                    }
                    
                    if ([file_ hasPrefix:@"http"])
                        listFile = [file_ stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://%@", [[DeviceClass sharedInstance] getDownloadUrl]] withString:@""];
                    else
                        listFile = file_;
                    
                    if([self getTypeStringByFileType:self.fileType].length > 0){
                        if (files_lists.length == 0) {
                            [files_lists appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                        }else{
                            [files_lists appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                        }
                    }else{
                        if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"MUSIC"]) {
                            if (files_lists_music.length == 0) {
                                [files_lists_music appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                            }else{
                                [files_lists_music appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                            }
                        }else if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"DOCUMENT"]){
                            if (files_lists_document.length == 0) {
                                [files_lists_document appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                            }else{
                                [files_lists_document appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                            }
                        }else if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"VIDEO"]){
                            if (files_lists_video.length == 0) {
                                [files_lists_video appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                            }else{
                                [files_lists_video appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                            }
                        }else if ([[[DataManager sharedInstance] getType:[listFile pathExtension]] isEqualToString:@"PICTURE"]){
                            if (files_lists_picture.length == 0) {
                                [files_lists_picture appendFormat:@"\"%@\"", [listFile urlDecodeUsingDecoding]];
                            }else{
                                [files_lists_picture appendFormat:@", \"%@\"", [listFile urlDecodeUsingDecoding]];
                            }
                        }
                    }
                    
                    
                    
                }
            }
            
            if([self getTypeStringByFileType:self.fileType].length > 0){
                [self deleteFileList:files_lists :[self getTypeStringByFileType:self.fileType]];
            }else{
                if (files_lists_music.length > 0) {
                    [self deleteFileList:files_lists_music :@"MUSIC"];
                }
                
                if (files_lists_document.length > 0) {
                    [self deleteFileList:files_lists_document :@"DOCUMENT"];
                }
                
                if (files_lists_video.length > 0) {
                    [self deleteFileList:files_lists_video :@"VIDEO"];
                }
                
                if (files_lists_picture.length > 0) {
                    [self deleteFileList:files_lists_picture :@"PICTURE"];
                }
            }
            
            if ([brokenFileArray count] > 0) {
                [self showWarnning:_(@"Operation_Failed")];
                [self switchFromDeleteToNormalMode];
            }else{
                if ([dfiles count] < DELETE_LIMIT) {
                    [self showWarnning:_(@"DELETE_ALERT")];
                    [self switchFromDeleteToNormalMode];
                }else{
                    [selectedItems removeObjectsInRange:r];
                    [self deleteByFileName:selectedItems :0];
                    
                    return;
                }
            }
        }else{
            [self showWarnning:_(@"Operation_Failed")];
            [self switchFromDeleteToNormalMode];
        }
        
        [self.loadingView stopAnimating];
        [self.view setUserInteractionEnabled:YES];
        self.loadingView.hidden = YES;
        [self loadData];
        
        return;
    }
    else if (callback == DELETE_FILE_FROM_FILE_LIST_CALLBACK)
    {
        return;
    }
    
    [self.loadingView stopAnimating];
    [self.view setUserInteractionEnabled:YES];
    self.loadingView.hidden = YES;
//    [self.navigationController popToRootViewControllerAnimated:YES];
    [self backToLoginPage];
}

-(void)failToStaticRequestWithErrorCode:(NSInteger)iFailStatus description:(NSString *)desc callbackID:(NSUInteger)callback{
    if (callback == GENERATE_FILE_LIST_BY_TYPE_CALLBACK)
    {
        return;
    }
    else if (callback == DELETE_FILE_BY_NAME_CALLBACK)
    {
        [self showWarnning:_(@"Operation_Failed")];
        [self switchFromDeleteToNormalMode];
        return;
    }
    else if (callback == DELETE_FILE_BY_FILE_NAME_CALLBACK)
    {
        [self showWarnning:_(@"Operation_Failed")];
        [self switchFromDeleteToNormalMode];
        return;
    }
    else if (callback == DELETE_FILE_FROM_FILE_LIST_CALLBACK)
    {
        return;
    }
    else if (callback == ADD_FILE_INRO_PUBLIC_LIST_CALLBACK)
    {
        [[KGModal sharedInstance] hideAnimated:YES];
        return;
    }
    
    [self.loadingView stopAnimating];
    [self.view setUserInteractionEnabled:YES];
    self.loadingView.hidden = YES;
//    [self.navigationController popToRootViewControllerAnimated:YES];
    [self backToLoginPage];
}

- (void)deleteFileList:(NSString*)files_str :(NSString*)fileType{
    NSString *method = @"POST";
    NSString *body = [NSString stringWithFormat:@"{ \"FileType\" : \"%@\", \"Filename\" : [%@]}", fileType, files_str];
    
    NSLog(@"%@\n%@\n%@", DELETE_FILE_FROM_FILE_LIST_COMMAND, method, body);
    
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:DELETE_FILE_FROM_FILE_LIST_COMMAND
                                                          Method:method
                                                            Body:body
                                                      CallbackID:DELETE_FILE_FROM_FILE_LIST_CALLBACK
                                                          Target:self];
}


-(void)deleteByName:(NSMutableArray*)oriDfiles :(int)count{
    count++;
    if ([oriDfiles count] == 0) {
        [self showWarnning:_(@"DELETE_ALERT")];
        [self switchFromDeleteToNormalMode];
        return;
    }
    
    NSArray* dfiles;
    NSRange r;
    
    if ([oriDfiles count] >= DELETE_LIMIT) {
        r.location = 0;
        r.length = DELETE_LIMIT;
        dfiles = [oriDfiles subarrayWithRange:r];
    }else{
        dfiles = oriDfiles;
    }
    
    NSMutableString *files_str = [NSMutableString string];
    
    NSString *file = nil;
    for (NSString *file_ in dfiles) {
        NSLog(@"file_ : %@", file_);
        if ([file_ hasPrefix:@"http"])
            file = [file_ stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://%@", [[DeviceClass sharedInstance] getDownloadUrl]] withString:@""];
        else
            file = file_;
        
        if (files_str.length == 0){
            [files_str appendFormat:@"\"%@\"", [[[file pathComponents] lastObject] urlDecodeUsingDecoding]];
        }else{
            [files_str appendFormat:@", \"%@\"", [[[file pathComponents] lastObject]  urlDecodeUsingDecoding]];
        }
    }
    
    NSString *folder;
    NSString *method = @"POST";
    NSString *body = [NSString stringWithFormat:@"{ \"Filename\" : [%@], \"Folder\" : \"%@\" }", files_str, folder];
    
    //LogMessage(nil, 0, @"%@\n%@\n%@", str, method, body);
    NSLog(@"%@\n%@\n%@", DELETE_FILE_BY_NAME_COMMAND, method, body);
    
    selectedItems = oriDfiles;
    
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:DELETE_FILE_BY_NAME_COMMAND
                                                          Method:method
                                                            Body:body
                                                      CallbackID:DELETE_FILE_BY_NAME_CALLBACK
                                                          Target:self];
}

-(void)deleteByFileName:(NSMutableArray*)oriDfiles :(int)count{
    count++;
    if ([oriDfiles count] == 0) {
        [self showWarnning:_(@"DELETE_ALERT")];
        [self switchFromDeleteToNormalMode];
        return;
    }
    
    NSArray* dfiles;
    NSRange r;
    
    if ([oriDfiles count] >= DELETE_LIMIT) {
        r.location = 0;
        r.length = DELETE_LIMIT;
        dfiles = [oriDfiles subarrayWithRange:r];
    }else{
        dfiles = oriDfiles;
    }
    
    NSMutableString *files_str = [NSMutableString string];
    NSString *file = nil;
    for (NSString* file_ in dfiles) {
        NSLog(@"file_ : %@", file_);
        if ([file_ hasPrefix:@"http"])
            file = [file_ stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://%@", [[DeviceClass sharedInstance] getDownloadUrl]] withString:@""];
        else
            file = file_;
        
        if (files_str.length == 0){
            [files_str appendFormat:@"\"%@\"", [file urlDecodeUsingDecoding]];
        }else{
            [files_str appendFormat:@", \"%@\"", [file urlDecodeUsingDecoding]];
        }
    }
    
    selectedItems = oriDfiles;
    
    NSString *method = @"POST";
    NSString *body = [NSString stringWithFormat:@"{ \"Filename\" : [%@]}", files_str];
    NSLog(@"%@\n%@\n%@", DELETE_FILE_BY_FILE_NAME_COMMAND, method, body);
    
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:DELETE_FILE_BY_FILE_NAME_COMMAND
                                                          Method:method
                                                            Body:body
                                                      CallbackID:DELETE_FILE_BY_FILE_NAME_CALLBACK
                                                          Target:self];
}

#pragma mark - ChildImplement
-(void)loadData{
    
}

//確認最愛檔案是否有在USB內
- (void)checkFavorite{
    NSString *favorite_str = [NSString stringWithFormat:@"favorite_%@_%@", [[NSUserDefaults standardUserDefaults] stringForKey:WLAN_MAC_ADDRESS_KEY], [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY] ];
    NSMutableArray* favoriteStrings = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:favorite_str]];
    
    if ([favoriteStrings count]>0) {
        for (int i=0;i<[favoriteStrings count];i++) {
            NSString *temp = [favoriteStrings objectAtIndex:i];
            bool checked = false;
            for(OnLineDataFile* file in items){
                if([file.filePath isEqualToString:temp]){
                    [favorites addObject:file];
                    checked = true;
                    break;
                }
            }
            if(!checked){
                [favoriteStrings removeObjectAtIndex:i];
                i--;
            }
        }
    }
}

-(void)saveFavoriteByRemove:(NSString*)file{
    NSString *favorite_str = [NSString stringWithFormat:@"favorite_%@_%@", [[NSUserDefaults standardUserDefaults] stringForKey:WLAN_MAC_ADDRESS_KEY], [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY] ];
    NSMutableArray* favorite_list = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:favorite_str]];
    [favorite_list removeObject:file];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:favorite_list forKey:favorite_str];
    [userDefault synchronize];
}

-(void)saveFavoriteByAdd:(NSString*)file{
    NSString *favorite_str = [NSString stringWithFormat:@"favorite_%@_%@", [[NSUserDefaults standardUserDefaults] stringForKey:WLAN_MAC_ADDRESS_KEY], [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY] ];
    
    NSMutableArray* favorite_list = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:favorite_str]];
    
    [favorite_list addObject:file];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:favorite_list forKey:favorite_str];
    [userDefault synchronize];
}

-(void)switchFromDeleteToNormalMode{
    
}

@end
