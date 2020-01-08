//
//  DataManager.m
//  CloudBox
//
//  Created by Wowoya on 13/3/9.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "DataManager.h"
#import "MBProgressHUD.h"
#import "NSString+URLEncoding.h"
#import "RouterGlobal.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "dataDefine.h"
#import "StaticHttpRequest.h"
#import "AFHTTPRequestOperation.h"

#include "getgateway.c"
#include <ifaddrs.h>
#include <arpa/inet.h>

#import "DeviceClass.h"
#import "IPFinderByUDP.h"
#import "FileTypeUtility.h"

@implementation DataManager{
    AFHTTPRequestOperation *downloadOperation, *uploadOperation;
    NSString *fileSource;//當上傳時，記錄要放在documents或tmp資料夾裡
    IPFinderByUDP* deviceFinderByUDP;
}

+ (DataManager*) sharedInstance {
    static id sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [self alloc];
        sharedInstance = [sharedInstance init];
    }
    return sharedInstance;
}

- (id)init {
	if ((self = [super init])) {
        self.database = [[Databases alloc] init];
        //self.playerViewController = [[PlayerViewController alloc] init];
        self.timeOut = 20;
        self.tagDownloadStatus = self.tagUploadStatus = self.isAudioPlaying = NO;
        self.uploadCount = 0;
        self.reDownloadCount = 0;
        [self resetDownload];
        
        self.pjTunnel = [PJTunnel sharedInstance];
        [self.pjTunnel setTunnelDebug:1];
        [self.pjTunnel setTunnelConfig:@"signal1.engeniusddns.com" Port:443];
        self.tunnelInterval = 0;
        self.delayTime = 2;
        self.resendDelay = 3;
        self.needShow = 0;
        
        if (!deviceFinderByUDP) {
            deviceFinderByUDP = [[IPFinderByUDP alloc] initFinderWithDelegate:self IsRepeat:YES waiting:2.0f];
        }
	}
	return self;
}

- (void)resetDownload {
    NSArray *items = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Downloading WHERE result <> 'OK'; "]];
    for (NSDictionary *item in items) {
        [[DataManager sharedInstance].database sqliteUpdate:@"Downloading" keys:@ {
            @"file" : [item[@"file"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        } params:@ {
            @"downloading" : @"FALSE",
            @"progress" : @"0",
            @"result" : @""
        }];
    }
}

- (NSString*)getType:(NSString*)ext {
    return [FileTypeUtility getType:ext];
}

- (UIImage*)getImageWithType:(NSString*)type ext:(NSString*)ext {
    return [FileTypeUtility getImageWithType:type ext:ext];
}

- (UIImage*)getImageOfflineWithType:(NSString*)type ext:(NSString*)ext {
    return [FileTypeUtility getImageOfflineWithType:type ext:ext];
}

- (NSString*)getUTI:(NSString*)type {
    // Text
    if ( [[type lowercaseString] isEqualToString:@"txt"] || [[type lowercaseString] isEqualToString:@"rtf"] ||
        [[type lowercaseString] isEqualToString:@"htm"] || [[type lowercaseString] isEqualToString:@"html"] )
        return @"public.text";
    else if ([[type lowercaseString] isEqualToString:@"pdf"])
        return @"com.adobe.pdf";
    else if ([[type lowercaseString] isEqualToString:@"sheet"])
        return @"org.openxmlformats.spreadsheetml.sheet";
    
    // MS Office
    else if ([[type lowercaseString] isEqualToString:@"doc"] || [[type lowercaseString] isEqualToString:@"docx"])
        return @"com.microsoft.word.doc";
    else if ([[type lowercaseString] isEqualToString:@"ppt"] || [[type lowercaseString] isEqualToString:@"pptx"])
        return @"com.microsoft.powerpoint.ppt";
    else if ([[type lowercaseString] isEqualToString:@"xls"] || [[type lowercaseString] isEqualToString:@"xlsx"])
        return @"com.microsoft.excel.xls";
    
    // iWork
    else if ([[type lowercaseString] isEqualToString:@"key"])
        return @"com.apple.keynote.key";
    else if ([[type lowercaseString] isEqualToString:@"numbers"])
        return @"public.content";
    else if ([[type lowercaseString] isEqualToString:@"pages"])
        return @"com.apple.pages";
    
    // Photo
    else if ([[type lowercaseString] isEqualToString:@"png"])
        return @"public.png";
    else if ([[type lowercaseString] isEqualToString:@"jpg"] || [[type lowercaseString] isEqualToString:@"jpeg"])
        return @"public.jpeg";
    else if ([[type lowercaseString] isEqualToString:@"tiff"])
        return @"public.tiff";
    else if ([[type lowercaseString] isEqualToString:@"heic"])
        return @"public.heif";

    // Music & Video
    else if ([[type lowercaseString] isEqualToString:@"mp3"])
        return @"public.mp3";
    else if ([[type lowercaseString] isEqualToString:@"mp4"])
        return @"public.mpeg-4";
    else if ([[type lowercaseString] isEqualToString:@"avi"])
        return @"public.avi";
    else if ([[type lowercaseString] isEqualToString:@"3gpp"])
        return @"public.3gpp";
    else if ([[type lowercaseString] isEqualToString:@"mpg"])
        return @"public.mpeg-2-video";
    else if ([[type lowercaseString] isEqualToString:@"mpeg"])
        return @"public.mpeg-2-video";
    return @"";
}

- (void)download:(NSString*)fullfilename completion:(void (^)(NSString *file))completion error:(void (^)(void))error {
    [self download:fullfilename type:nil completion:completion error:error];
}

- (void)download:(NSString*)fullfilename type:(NSString*)type completion:(void (^)(NSString *file))completion error:(void (^)(void))error {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (type == nil)
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filename = [[fullfilename pathComponents] lastObject];
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",filename]];
    
    //NSLog(@"%@",path);
    int exist = [[DataManager sharedInstance].database getSqliteInt:[NSString stringWithFormat:@"SELECT COUNT(*) FROM Collection WHERE type = '%@' AND filename = '%@'; ", type, filename]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == FALSE || exist == 0) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].windows[0] animated:YES];
        hud.mode = MBProgressHUDModeAnnularDeterminate;
        if (type != nil)
            hud.labelText = @"Loading";
        NSString *file = [[fullfilename urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
        NSString *str = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], file];
        //LogMessage(nil, 0, @"%@", str);
        NSLog(@"%@",str);
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
        downloadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
        [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].windows[0] animated:YES];
            LogMessage(nil, 0, @"Successfully downloaded file to %@", path);
            completion(path);
        } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].windows[0] animated:YES];
            LogMessage(nil, 0, @"Error: %@", err);
            error();
        }];
        [downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            LogMessage(nil, 0, @"%d %@ %@", bytesRead, @(totalBytesRead), @(totalBytesExpectedToRead));
            float progress = ((float)totalBytesRead) / totalBytesExpectedToRead;
            [MBProgressHUD HUDForView:[UIApplication sharedApplication].windows[0]].progress = progress;
        }];
        [downloadOperation start];
    } else {
        completion(path);
    }
}

- (void)addDownload:(NSString*)fullfilename saveToAlbum:(BOOL)saveToAlbum {
    NSString *uid = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT uid FROM Collection WHERE type = '%@' AND filename = '%@'; ", [self getType:[fullfilename pathExtension]], fullfilename]];
    NSString *file = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT file FROM Downloading WHERE file = '%@'; ", fullfilename]];
    if (uid.length == 0 && file.length == 0) {
        [[DataManager sharedInstance].database sqliteInsert:@"Downloading" keys:@ {
            @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
            @"type" : [self getType:[fullfilename pathExtension]],
            @"progress" : @"0",
            @"downloading" : @"FALSE",
            @"result" : @"",
            @"save_to_album" : (saveToAlbum ? @"TRUE" : @"FALSE")
        }];
    }else{
        NSString *ext = [NSString stringWithFormat:@".%@",[fullfilename pathExtension]];
        NSString *fileName = [[fullfilename lastPathComponent] stringByDeletingPathExtension];
        NSString *folder = [fullfilename stringByReplacingOccurrencesOfString:fileName withString:@""];
        folder = [folder stringByReplacingOccurrencesOfString:ext withString:@""];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSDate *date = [NSDate date];
        [formatter setDateFormat:@"YYYYMMddhhmmss'"];
        NSString *today = [formatter stringFromDate:date];
        
        fileName = [NSString stringWithFormat:@"%@%@_%@.%@", folder, fileName, today, [fullfilename pathExtension]];
        LogMessage(nil, 0, @"%@", fileName);
        
        [[DataManager sharedInstance].database sqliteInsert:@"Downloading" keys:@ {
            @"file" : [fileName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
            @"type" : [self getType:[fileName pathExtension]],
            @"progress" : @"0",
            @"downloading" : @"COPY",
            @"result" : @"",
            @"save_to_album" : (saveToAlbum ? @"TRUE" : @"FALSE")
        }];
    }
}

- (void)addUpload:(NSString*)fullfilename {
    NSString *file = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT file FROM Uploading WHERE file = '%@'; ", fullfilename]];
    if (file.length == 0) {
        [[DataManager sharedInstance].database sqliteInsert:@"Uploading" keys:@ {
            @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
            @"type" : [self getType:[fullfilename pathExtension]],
            @"progress" : @"0",
            @"uploading" : @"FALSE",
            @"result" : @"",
        }];
    }
}

//從Album上傳時，先複製到temp資料夾
- (void)addUploadByImage:(UIImage*)image tImageName:(NSString*)tImageName {
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [[tImageName pathComponents] lastObject];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:YES];
}

- (void)addUploadByVideo:(ALAssetRepresentation *)rep videoName:(NSString*)videoName {
    // 將video儲存下來
    NSString *filePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), videoName];
    NSLog(@"%@",filePath);
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) {
    }
    
    static const NSUInteger BufferSize = 1024*1024;
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    do {
        @try {
            bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:nil];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            
            offset += bytesRead;
            //NSLog(@"%lu",(unsigned long)data.length);
        } @catch (NSException *exception) {
            break;
        }
    } while (bytesRead > 0);
    
    [[DataManager sharedInstance].database sqliteInsert:@"Uploading" keys:@ {
        @"file" : [videoName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        @"type" : @"",
        @"progress" : @"0",
        @"uploading" : @"FALSE",
        @"result" : @"Album",
    }];
}

- (void)addPhotoByImage:(UIImage*)image tImageName:(NSString*)tImageName{
    NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]];
    
    NSString *filePath = [resourceDocPath stringByAppendingPathComponent:tImageName];
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:YES];
    
    //存入到資料庫
    NSString *uid = [NSString stringWithFormat:@"%d%d", (int)[[NSDate date] timeIntervalSince1970], arc4random() % 99999];
    [[DataManager sharedInstance].database sqliteInsert:@"Collection" keys:@ {
        @"uid" : uid,
        @"type" : [[DataManager sharedInstance] getType:[tImageName pathExtension]],
        @"filename" : [tImageName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        @"isdownload" : @"1",
        @"isfolder" : @"0",
        @"parentfolder" : @"/"
    }];
}

- (void)doDownload{
    NSArray *items = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Downloading WHERE (downloading = 'FALSE' OR downloading = 'COPY') AND result == ''; "]];
    if (items.count > 0) {
        self.tagDownloadStatus = YES;
        NSDictionary *task = [items objectAtIndex:0];
        
        NSString *fullfilename = task[@"file"];
        self.uploadDownloadFile = fullfilename;//記錄目前上傳的檔案名稱
        
        NSString *type = task[@"type"];
        NSString *downloading = task[@"downloading"];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filename = [[fullfilename pathComponents] lastObject];
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
        
        if ([downloading isEqualToString:@"COPY"]) {
            NSString *ext = [NSString stringWithFormat:@".%@",[fullfilename pathExtension]];
            fullfilename = [fullfilename stringByReplacingOccurrencesOfString:ext withString:@""];
            fullfilename = [fullfilename substringWithRange:NSMakeRange(0, fullfilename.length-15)];
            fullfilename = [NSString stringWithFormat:@"%@%@",fullfilename,ext];
        }
        
        [[DataManager sharedInstance].database sqliteUpdate:@"Downloading" keys:@ {
            @"file" : [task[@"file"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        } params:@ {
            @"downloading" : @"TRUE",
        }];
        
        NSString *file = [[fullfilename urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
        NSString *str = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], file];
        //LogMessage(nil, 0, @"%@", str);
        NSLog(@"%@", str);
        fullfilename = task[@"file"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
        downloadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
        __weak typeof(self) weakSelf = self;
        [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary* res = [[operation response] allHeaderFields];
            NSLog(@"RES: %@", res);
            
            NSError *error;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
            
            if (error) {
                NSLog(@"ERR: %@", [error description]);
                [weakSelf doDownloadFailed:task :fullfilename];
            }else{
                NSLog(@"FileAttributes: %@",fileAttributes);
                if ([[res objectForKey:@"Content-Length"] longLongValue] != [[fileAttributes objectForKey:NSFileSize] longLongValue]) {
                    NSLog(@"Size ERR - Content-Length: %lld ,FileSize: %lld",[[res objectForKey:@"Content-Length"] longLongValue],[[fileAttributes objectForKey:NSFileSize] longLongValue]);
                    [weakSelf doDownloadFailed:task :fullfilename];
                }else{
                    weakSelf.reDownloadCount = 0;
                    // 下載成功
                    if ([task[@"save_to_album"] boolValue] == TRUE && ([task[@"type"] isEqualToString:@"PICTURE"] || [task[@"type"] isEqualToString:@"VIDEO"])) {
                        // 儲存至 Album
                        if ([task[@"type"] isEqualToString:@"PICTURE"]) {
                            UIImage *image = [UIImage imageWithContentsOfFile:path];
                            UIImageWriteToSavedPhotosAlbum(image, weakSelf, nil, nil);
                        } else if ([task[@"type"] isEqualToString:@"VIDEO"]) {
                            UISaveVideoAtPathToSavedPhotosAlbum (path, weakSelf, nil, nil);
                        }
                    } else {
                        // 寫入資料庫中
                        srandom(time(NULL));
                        NSString *uid = [NSString stringWithFormat:@"%d%d", (int)[[NSDate date] timeIntervalSince1970], arc4random() % 99999];
                        [weakSelf.database sqliteInsert:@"Collection" keys:@ {
                            @"uid" : uid,
                            @"type" : type,
                            @"filename" : [filename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                            @"isdownload" : @"1",
                            @"isfolder" : @"0",
                            @"parentfolder" : @"/"
                        }];
                    }
                    
                    //LogMessage(nil, 0, @"Successfully downloaded file to %@", path);
                    NSLog(@"Successfully downloaded file to %@", path);
                    [[DataManager sharedInstance].database sqliteUpdate:@"Downloading" keys:@ {
                        @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                    } params:@ {
                        @"progress" : @"1",
                        @"downloading" : @"FALSE",
                        @"result" : @"OK"
                    }];
                    
                    weakSelf.tagDownloadStatus = NO;
                    [weakSelf doDownload];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
            // 下載失敗
            NSLog(@"Download Error: %@", err);
            [weakSelf doDownloadFailed:task :fullfilename];
        }];
        [downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            // 更新下載的百分比
            //LogMessage(nil, 0, @"%@ %d %@ %@", fullfilename, bytesRead, @(totalBytesRead), @(totalBytesExpectedToRead));
            //double progress = ((double)(totalBytesRead) / (double)(totalBytesExpectedToRead));
            float progress = ((float)totalBytesRead) / totalBytesExpectedToRead;
            //double progress = ((double)(totalBytesRead) / (double)(totalBytesExpectedToRead)) * 0.99;
            //LogMessage(nil, 0, @"%f", progress);
            NSLog(@"bytesRead: %u, totalBytesRead: %lld, totalBytesExpectedToRead: %lld", bytesRead, totalBytesRead, totalBytesExpectedToRead);
            NSLog(@"%f", progress);
            weakSelf.progressFloat = progress;
        }];
        [downloadOperation start];

    }
}

-(void)doDownloadFailed:(NSDictionary*)task :(NSString*)fullfilename{
    [[DataManager sharedInstance].database sqliteUpdate:@"Downloading" keys:@ {
        @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
    } params:@ {
        @"downloading" : @"FALSE",
        @"result" : @"FAILED"
    }];
    self.tagDownloadStatus = NO;
}

- (void)doDownload:(NSString*)fullfilename
                            filename:(NSString*)filename
                    withSuccessBlock:(void (^)())success
                        failureBlock:(void (^)())failure
                         saveToAlbum:(BOOL)saveToAlbum
                                type:(NSString*)type
{
    self.tagDownloadStatus = YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    NSString *file = [[fullfilename urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
    NSString *str = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], file];
    //LogMessage(nil, 0, @"%@", str);
    NSLog(@"%@", str);
    //        fullfilename = task[@"file"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
    downloadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    __weak typeof(self) weakSelf = self;
    [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* res = [[operation response] allHeaderFields];
        NSLog(@"RES: %@", res);
        
        NSError *error;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        
        if (error) {
            NSLog(@"ERR: %@", [error description]);
            //                [weakSelf doDownloadFailed:task :fullfilename];
            if(failure!=nil){
                failure();
            }
        }else{
            NSLog(@"FileAttributes: %@",fileAttributes);
            if ([[res objectForKey:@"Content-Length"] longLongValue] != [[fileAttributes objectForKey:NSFileSize] longLongValue]) {
                NSLog(@"Size ERR - Content-Length: %lld ,FileSize: %lld",[[res objectForKey:@"Content-Length"] longLongValue],[[fileAttributes objectForKey:NSFileSize] longLongValue]);
                //                    [weakSelf doDownloadFailed:task :fullfilename];
                if(failure!=nil){
                    failure();
                }
            }else{
                weakSelf.reDownloadCount = 0;
                // 下載成功
                if (saveToAlbum) {
                    // 儲存至 Album
                    if ([type isEqualToString:@"PICTURE"]) {
                        UIImage *image = [UIImage imageWithContentsOfFile:path];
                        UIImageWriteToSavedPhotosAlbum(image, weakSelf, nil, nil);
                    } else if ([type isEqualToString:@"VIDEO"]) {
                        UISaveVideoAtPathToSavedPhotosAlbum (path, weakSelf, nil, nil);
                    }
                    
                } else {
                    // 寫入資料庫中
                    srandom(time(NULL));
                    NSString *uid = [NSString stringWithFormat:@"%d%d", (int)[[NSDate date] timeIntervalSince1970], arc4random() % 99999];
                    [weakSelf.database sqliteInsert:@"Collection" keys:@ {
                        @"uid" : uid,
                        @"type" : type,
                        @"filename" : [filename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        @"isdownload" : @"1",
                        @"isfolder" : @"0",
                        @"parentfolder" : @"/"
                    }];
                    
                }
                
                NSLog(@"Successfully downloaded file to %@", path);
                weakSelf.tagDownloadStatus = NO;
                if(success!=nil){
                    success();
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
        // 下載失敗
        NSLog(@"Download Error: %@", err);
        //            [weakSelf doDownloadFailed:task :fullfilename];
        if(failure!=nil){
            failure();
        }
    }];
    [downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        // 更新下載的百分比
        float progress = ((float)totalBytesRead) / totalBytesExpectedToRead;
        NSLog(@"bytesRead: %u, totalBytesRead: %lld, totalBytesExpectedToRead: %lld", bytesRead, totalBytesRead, totalBytesExpectedToRead);
        NSLog(@"%f", progress);
        weakSelf.progressFloat = progress;
    }];
    [downloadOperation start];
}

- (void)doUpload{
    NSLog(@"Do Upload");
    NSArray *uploads = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Uploading WHERE uploading = 'FALSE' AND (result == '' or result == 'Album'); "]];
    if (uploads.count > 0) {
        self.tagUploadStatus = YES;
        
        NSDictionary *task = [uploads objectAtIndex:0];
        [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
            @"file" : [task[@"file"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        } params:@ {
            @"uploading" : @"TRUE",
        }];
        
        NSString *fullfilename = task[@"file"];
        self.uploadDownloadFile = fullfilename;//記錄目前上傳的檔案名稱
        
        NSString *pathSource;
        if ([task[@"result"] isEqualToString:@"Album"]) {//判斷要從那個資料夾取檔案，Documents或tmp
            pathSource = NSTemporaryDirectory();
        }else{
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            pathSource = [paths objectAtIndex:0];
        }
        
        NSString *filename = [[fullfilename pathComponents] lastObject];
        NSString *path = [pathSource stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path] == TRUE) {
            NSString *str = [NSString stringWithFormat:@"http://%@/upload.html", [[DeviceClass sharedInstance] getUploadUrl]];
            //上傳位置 192.168.0.1:2000/upload.html
            NSLog(@"STR : %@", str);
            
            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];

            AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
            NSDictionary *params = @{@"page" : @"upload",
                                     @"path" : [NSString stringWithFormat:@"/www%@/%@", self.usbUploadPath, filename],
                                     @"totalsize" : [NSString stringWithFormat:@"%llu", fileSize]};
            
            //LogMessage(nil, 0, @"%@", params);
            NSLog(@"PARMS : %@", params);
            
            NSURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST"
                                                                     URLString:str
                                                                    parameters:params
                                                     constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                         [formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"webUpload" error:nil];
                                                         //LogMessage(nil, 0, @"%@", filename);
                                                         NSLog(@"FILENAME : %@", filename);
                                                     }
                                                                         error:nil];
            
            uploadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            __weak typeof(self) weakSelf = self;
            [uploadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString *response = [operation responseString];
                //LogMessage(nil, 0, @"response: %@", response);
                NSLog(@"response: %@", response);
                
                if ([[response lowercaseString] rangeOfString:@"success"].length>0) {
                    //LogMessage(nil, 0, @"Successfully upload file: %@", fullfilename);
                    NSLog(@"Successfully upload file: %@", fullfilename);
                    [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
                        @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                    } params:@ {
                        @"progress" : @"1",
                        @"uploading" : @"TRUE",
                        @"result" : @"OK"
                    }];
                   
                    weakSelf.tagUploadStatus = NO;
                    [weakSelf doUpload];
                    
                }else{ //上傳失敗
                    //失敗的話，重新做，做三次就不做
                    weakSelf.uploadCount++;
                    if (weakSelf.uploadCount <= CONNECT_RETRY_COUNT) {
                        NSLog(@"Re Do Upload count %d",weakSelf.uploadCount);
                        sleep(weakSelf.resendDelay);
                        [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
                            @"file" : [task[@"file"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        } params:@ {
                            @"uploading" : @"FALSE",
                        }];
        
                        
                        weakSelf.tagUploadStatus = NO;
                        [weakSelf doUpload];
                    }else{
                        RouterGlobal *global = [[RouterGlobal alloc]init];
                        
                        [global getStorageInfo:^(NSDictionary *resultDictionary) {
                            NSLog(@"StorageInfo : %@",resultDictionary);
                            if (resultDictionary != nil) {
                                NSArray* storageArray = [resultDictionary objectForKey:@"StorageInformation"];
                                for (NSDictionary* usbInfo in storageArray) {
                                    if ([[usbInfo objectForKey:@"UsbPath"] isEqualToString:weakSelf.diskPath]) {
                                        long long leftSize = [[usbInfo objectForKey:@"LeftSize"] longLongValue];
                                        NSLog(@"LS:%lld , FS: %llu",leftSize,(fileSize/1024));
                                        if (leftSize < (fileSize/1024)) {
                                            weakSelf.needShow = 2;
                                        }else{
                                            weakSelf.needShow = 1;
                                        }
                                        break;
                                    }else{
                                        NSLog(@"FS : %llu",fileSize);
                                        weakSelf.needShow = 1;
                                    }
                                }
                            }else{
                                weakSelf.needShow = 1;
                            }
                            
                            [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
                                @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                            } params:@ {
                                @"uploading" : @"FAILED",
                                @"result" : @"FAILED"
                            }];
                            weakSelf.tagUploadStatus = NO;
                            weakSelf.uploadCount = 0;
                        }];
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) { //上傳失敗
                //LogMessage(nil, 0, @"Error: %@", error);
                NSLog(@"Error: %@", error);
                    //失敗的話，重新做，做三次就不做
                    weakSelf.uploadCount++;
                    if (weakSelf.uploadCount <= CONNECT_RETRY_COUNT) {
                        NSLog(@"Re Do Upload count %d",weakSelf.uploadCount);
                        sleep(weakSelf.resendDelay);
                        [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
                            @"file" : [task[@"file"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        } params:@ {
                            @"uploading" : @"FALSE",
                        }];
                        
                        weakSelf.tagUploadStatus = NO;
                        [weakSelf doUpload];
                    }else{
                        RouterGlobal *global = [[RouterGlobal alloc]init];
                        [global getStorageInfo:^(NSDictionary *resultDictionary) {
                            if (resultDictionary != nil) {
                                NSArray* storageArray = [resultDictionary objectForKey:@"StorageInformation"];
                                for (NSDictionary* usbInfo in storageArray) {
                                    if ([[usbInfo objectForKey:@"UsbPath"] isEqualToString:weakSelf.diskPath]) {
                                        long long leftSize = [[usbInfo objectForKey:@"LeftSize"] longLongValue];
                                        NSLog(@"LS:%lld , FS: %llu",leftSize,(fileSize/1024));
                                        if (leftSize < (fileSize/1024)) {
                                            weakSelf.needShow = 2;
                                        }else{
                                            weakSelf.needShow = 1;
                                        }
                                        break;
                                    }else{
                                        NSLog(@"FS : %llu",fileSize);
                                        weakSelf.needShow = 1;
                                    }
                                }
                            }else{
                                weakSelf.needShow = 1;
                            }
                            
                            [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
                                @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                            } params:@ {
                                @"uploading" : @"FALSE",
                                @"result" : @"FAILED"
                            }];
                            weakSelf.tagUploadStatus = NO;
                            weakSelf.uploadCount = 0;
                        }];
                    }
            }];
            [uploadOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) { //更新上傳的百分比
                //LogMessage(nil, 0, @"%@ %d %@ %@", fullfilename, bytesWritten, @(totalBytesWritten), @(totalBytesExpectedToWrite));
                NSLog(@"fullfilename : %@ bytesWritten : %d totalBytesWritten : %@ totalBytesExpectedToWrite : %@", fullfilename, bytesWritten, @(totalBytesWritten), @(totalBytesExpectedToWrite));
                double progress = ((double)(totalBytesWritten) / (double)(totalBytesExpectedToWrite)) * 0.99;
                weakSelf.progressFloat = progress;
            }];
            [uploadOperation start];
        } else {
            // 檔案不存在
            [[DataManager sharedInstance].database sqliteUpdate:@"Uploading" keys:@ {
                @"file" : [fullfilename stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
            } params:@ {
                @"uploading" : @"FALSE",
                @"result" : @"FAILED"
            }];
            self.tagUploadStatus = NO;
        }
    }else{
        
    }
}

- (void)doUpload:(NSString*)fullfilename withSuccessBlock:(void (^)())success
                                             failureBlock:(void (^)())failure
                                              isFromAlbum:(bool)isFromAlbum
{
    NSLog(@"Do Upload");

    self.tagUploadStatus = YES;
    
    self.uploadDownloadFile = fullfilename;//記錄目前上傳的檔案名稱
    
    NSString *pathSource;
    if (isFromAlbum) {//判斷要從那個資料夾取檔案，Documents或tmp
        pathSource = NSTemporaryDirectory();
    }else{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        pathSource = [paths objectAtIndex:0];
    }
    //fileSource = tagFileSource;
    
    NSString *filename = [[fullfilename pathComponents] lastObject];
    NSString *path = [pathSource stringByAppendingPathComponent:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == TRUE) {
        //NSString *uploadURL = [[[DataManager sharedInstance] getUploadURL] stringByReplacingOccurrencesOfString:@"9000" withString:@"2000"];
        NSString *str = [NSString stringWithFormat:@"http://%@/upload.html", [[DeviceClass sharedInstance] getUploadUrl]];
        //上傳位置 192.168.0.1:2000/upload.html
        //LogMessage(nil, 0, @"%@", str);
        NSLog(@"STR : %@", str);
        
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
        
        AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
        NSDictionary *params = @{@"page" : @"upload",
                                 @"path" : [NSString stringWithFormat:@"/www%@/%@", self.usbUploadPath, filename],
                                 @"totalsize" : [NSString stringWithFormat:@"%llu", fileSize]};
        
        //LogMessage(nil, 0, @"%@", params);
        NSLog(@"PARMS : %@", params);
        
        NSURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST"
                                                                 URLString:str
                                                                parameters:params
                                                 constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                     [formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"webUpload" error:nil];
                                                     //LogMessage(nil, 0, @"%@", filename);
                                                     NSLog(@"FILENAME : %@", filename);
                                                 }
                                                                     error:nil];
        
        uploadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        __weak typeof(self) weakSelf = self;
        [uploadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *response = [operation responseString];
            //LogMessage(nil, 0, @"response: %@", response);
            NSLog(@"response: %@", response);
            
            if ([[response lowercaseString] rangeOfString:@"success"].length>0) {
                //LogMessage(nil, 0, @"Successfully upload file: %@", fullfilename);
                NSLog(@"Successfully upload file: %@", fullfilename);
                
                weakSelf.tagUploadStatus = NO;
                if(success!=nil){
                    success();
                }
            }else{ //上傳失敗
                //失敗的話，重新做，做三次就不做
                weakSelf.uploadCount++;
                if (weakSelf.uploadCount <= CONNECT_RETRY_COUNT) {
                    if(uploadOperation.isCancelled){
                        weakSelf.tagUploadStatus = NO;
                        NSLog(@"Upload isCancelled");
                        return;
                    }
                        
                    NSLog(@"Re Do Upload count %d",weakSelf.uploadCount);
                    sleep(weakSelf.resendDelay);
                    
                    weakSelf.tagUploadStatus = NO;
                    [weakSelf doUpload:fullfilename withSuccessBlock:success failureBlock:failure isFromAlbum:isFromAlbum];
                }else{
                    RouterGlobal *global = [[RouterGlobal alloc]init];
                    
                    [global getStorageInfo:^(NSDictionary *resultDictionary) {
                        NSLog(@"StorageInfo : %@",resultDictionary);
                        if (resultDictionary != nil) {
                            NSArray* storageArray = [resultDictionary objectForKey:@"StorageInformation"];
                            for (NSDictionary* usbInfo in storageArray) {
                                if ([[usbInfo objectForKey:@"UsbPath"] isEqualToString:weakSelf.diskPath]) {
                                    long long leftSize = [[usbInfo objectForKey:@"LeftSize"] longLongValue];
                                    NSLog(@"LS:%lld , FS: %llu",leftSize,(fileSize/1024));
                                    if (leftSize < (fileSize/1024)) {
                                        weakSelf.needShow = 2;
                                    }else{
                                        weakSelf.needShow = 1;
                                    }
                                    break;
                                }else{
                                    NSLog(@"FS : %llu",fileSize);
                                    weakSelf.needShow = 1;
                                }
                            }
                        }else{
                            weakSelf.needShow = 1;
                        }
                        
                        weakSelf.tagUploadStatus = NO;
                        if(failure!=nil){
                            failure();
                        }
                        weakSelf.uploadCount = 0;
                    }];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) { //上傳失敗
            //LogMessage(nil, 0, @"Error: %@", error);
            NSLog(@"Error: %@", error);
            //失敗的話，重新做，做三次就不做
            weakSelf.uploadCount++;
            if (weakSelf.uploadCount <= CONNECT_RETRY_COUNT) {
                if(uploadOperation.isCancelled){
                    weakSelf.tagUploadStatus = NO;
                    NSLog(@"Upload isCancelled");
                    return;
                }
                
                NSLog(@"Re Do Upload count %d",weakSelf.uploadCount);
                sleep(weakSelf.resendDelay);
                
                weakSelf.tagUploadStatus = NO;
                [weakSelf doUpload:fullfilename withSuccessBlock:success failureBlock:failure isFromAlbum:isFromAlbum];
            }else{
                RouterGlobal *global = [[RouterGlobal alloc]init];
                [global getStorageInfo:^(NSDictionary *resultDictionary) {
                    if (resultDictionary != nil) {
                        NSArray* storageArray = [resultDictionary objectForKey:@"StorageInformation"];
                        for (NSDictionary* usbInfo in storageArray) {
                            if ([[usbInfo objectForKey:@"UsbPath"] isEqualToString:weakSelf.diskPath]) {
                                long long leftSize = [[usbInfo objectForKey:@"LeftSize"] longLongValue];
                                NSLog(@"LS:%lld , FS: %llu",leftSize,(fileSize/1024));
                                if (leftSize < (fileSize/1024)) {
                                    weakSelf.needShow = 2;
                                }else{
                                    weakSelf.needShow = 1;
                                }
                                break;
                            }else{
                                NSLog(@"FS : %llu",fileSize);
                                weakSelf.needShow = 1;
                            }
                        }
                    }else{
                        weakSelf.needShow = 1;
                    }
                    
                    weakSelf.tagUploadStatus = NO;
                    weakSelf.uploadCount = 0;
                    if(failure!=nil){
                        failure();
                    }
                }];
            }
        }];
        [uploadOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) { //更新上傳的百分比
            //LogMessage(nil, 0, @"%@ %d %@ %@", fullfilename, bytesWritten, @(totalBytesWritten), @(totalBytesExpectedToWrite));
            NSLog(@"fullfilename : %@ bytesWritten : %d totalBytesWritten : %@ totalBytesExpectedToWrite : %@", fullfilename, bytesWritten, @(totalBytesWritten), @(totalBytesExpectedToWrite));
            double progress = ((double)(totalBytesWritten) / (double)(totalBytesExpectedToWrite)) * 0.99;
            weakSelf.progressFloat = progress;
        }];
        [uploadOperation start];
    } else {
        // 檔案不存在
        self.tagUploadStatus = NO;
        if(failure!=nil){
            failure();
        }
    }
}

- (void)stopDownload{
    [self stopDownloadAndDoNext:YES];
}

- (void)stopDownloadAndDoNext:(bool)doNext{
    [downloadOperation cancel];
    if(doNext)
        [self doDownload];
}

- (void)stopUpload{
    [self stopUploadAndDoNext:YES];
}

- (void)stopUploadAndDoNext:(bool)doNext{
    self.tagUploadStatus = NO;
    [uploadOperation cancel];
    if(doNext)
        [self doUpload];
}

- (NSString *)replaceUnicode:(NSString *)unicodeStr {
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *returnStr = [NSPropertyListSerialization propertyListFromData:tempData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}

- (UIImage*)imageByScalingForSize:(CGSize)targetSize image:(UIImage*)sourceImage
{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        
        scaledWidth= width * scaleFactor;
        scaledHeight = height * scaleFactor;
//        // center the image
//        if (widthFactor < heightFactor)
//        {
//            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
//        }
//        else if (heightFactor < widthFactor)
//        {
//            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
//        }
    }
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width= scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    UIGraphicsBeginImageContext(thumbnailRect.size); // this will crop
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil)
        NSLog(@"could not scale image");
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
    
}

- (UIImage*)smallPhoto:(NSString*)filePath width:(float)width height:(float)height{
    NSString *tempFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [[filePath pathComponents] lastObject]];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tempFile];
    NSData *image;
    if (fileExists) {
        NSLog(@"從快取中取得原圖 : %@",filePath);
        image = [[NSData alloc] initWithContentsOfFile:tempFile];
    }else{
        NSLog(@"下載原圖 : %@",filePath);
        image = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:filePath]];
    }
    
    if (image != nil) {
        
    UIImage *tImage = [UIImage imageWithData:image];
    
    float w=width,h=height;
    if (tImage.size.width>=width*2 && tImage.size.height>=height*2) {
        if( tImage.size.width > tImage.size.height ){
            w = ((float)(tImage.size.height/tImage.size.width))*height*2;
            h = height*2;
        }else{
            w = width*2;
            h = ((float)(tImage.size.width/tImage.size.height))*width*2;;
        }
        UIGraphicsBeginImageContext(CGSizeMake(w, h));
        [tImage drawInRect:CGRectMake(0,0,width*2,height*2)];
    }else{
        UIGraphicsBeginImageContext(CGSizeMake(w, h));
        [tImage drawInRect:CGRectMake(0,0,tImage.size.width,tImage.size.height)];
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
        
        //儲存到tmp
        NSData *saveData = UIImagePNGRepresentation(newImage);
        [saveData writeToFile:tempFile atomically:YES];
        
    image = nil;tImage = nil;
        
        return newImage;
    }else{
        //return nil;
        return [UIImage imageNamed:@"img_photo.jpg"];
    }
}

- (BOOL)checkFileName:(NSString*)name{
    if ([name rangeOfString:@"<"].length>0 || [name rangeOfString:@">"].length>0 || [name rangeOfString:@"/"].length>0 || [name rangeOfString:@"\\"].length>0 ||
        [name rangeOfString:@"|"].length>0 || [name rangeOfString:@":"].length>0 || [name rangeOfString:@"\""].length>0 || [name rangeOfString:@"*"].length>0 ||
        [name rangeOfString:@"?"].length>0) {
        return YES;
    }else{
        return NO;
    }
}

-(NSDictionary*)fetchSSIDInfo
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    NSDictionary* info = nil;
    for (NSString* ifnam in ifs) {
        NSLog(@"%s: %@ => %@", __func__, ifnam, info);
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    return info;
}

-(NSString*)getLocalIP{
    //取得local ip
    NSString *ip = @"";
    struct in_addr gatewayaddr;
    int r;
    r = getdefaultgateway(&(gatewayaddr.s_addr));
    if(r>=0){
       ip = [NSString stringWithFormat:@"%s",inet_ntoa(gatewayaddr)];
    }
    return ip;
}

-(void) startfindDeviceByUDP {
    [deviceFinderByUDP stopFindDeviceByUDP];
    [deviceFinderByUDP startfindDeviceByUDP];
}

-(void) stopFindDeviceByUDP {
    [deviceFinderByUDP stopFindDeviceByUDP];
}

#pragma mark - IPFinderByUDPDelegate
- (void)didUDPFindDeviceIP:(NSString *)_strIPAddr fwVersion:(NSString *)_fwVersion deviceModel:(NSString *)_deviceModel macAddr:(NSString *)_macAddress meshID:(NSString *)_meshID message:(NSString *)msg
{
    if (deviceFinderByUDP) {
        NSLog(@"ipAddressFindByUDP : %@", _strIPAddr);
        [DataManager sharedInstance].ipAddressFindByUDP = _strIPAddr;
        [deviceFinderByUDP stopFindDeviceByUDP];
//        deviceFinderByUDP.delegate = nil;
//        deviceFinderByUDP = nil;
    }
}

- (void)didFinishFind
{
    [deviceFinderByUDP stopFindDeviceByUDP];
//    deviceFinderByUDP.delegate = nil;
//    deviceFinderByUDP = nil;
}

#pragma mark - open tunnel

-(void)resetTunnel{
    [self.pjTunnel stopTunnels:YES];
}

@end
