//
//  DataManager.h
//  CloudBox
//
//  Created by Wowoya on 13/3/9.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Databases.h"
#include <AssetsLibrary/AssetsLibrary.h>
#import "PlayerViewController.h"
//#import "VideoViewController.h"
#import "KxMovieViewController.h"

#import "PJTunnel.h"

@interface DataManager : NSObject<PJTunnelDelegate>

#define ConnectionType 1

#if ConnectionType
@property (strong, nonatomic) NSString *connectionType;
#endif

@property (strong, nonatomic) NSString *token;
@property (nonatomic) BOOL offline;//判斷是否為離線模式
@property (nonatomic) BOOL login;
@property (assign,nonatomic) int needShow;
@property (strong, nonatomic) NSDate *loginTime;
//@property (strong, nonatomic) NSString *rotuerURL;
//@property (strong, nonatomic) NSString *redirectDownloadRouterURL;//當router為雙層架構時，取得另一個下載的URL
//@property (strong, nonatomic) NSString *redirectUploadRouterURL;//當router為雙層架構時，取得另一個上傳的URL
//@property (strong, nonatomic) NSString *usbPath;
@property (strong, nonatomic) NSString *usbUploadPath;
@property (strong, nonatomic) Databases *database;
@property (strong, nonatomic) id uiViewController;//取得目前APP所在的ViewController
@property (strong, nonatomic) PlayerViewController *playerViewController;
@property (strong, nonatomic) NSString *diskPath,*diskGuestPath;//目前所在磁碟
@property int timeOut;

@property (strong, nonatomic) NSString *uploadDownloadFile;//目前上傳的檔案名稱
@property BOOL tagDownloadStatus, tagUploadStatus, isAudioPlaying;//是否有上傳或下載或正在播音樂
@property float progressFloat;//上傳下載進度條

@property (strong, nonatomic) UIImage *autoUploadImage;//自動上傳目前縮圖
@property (strong, nonatomic) NSString *autoUploadName;//自動上傳照片名稱
@property float autoUploadProgressFloat;//自動上傳功能的上傳進度
@property int autoUploadLeft;//自動上傳剩餘幾張
@property int modelType;
@property (strong, nonatomic) NSString *lanIPAddress;
@property (strong, nonatomic) NSString *ipAddressFindByUDP;

@property (strong, nonatomic) PJTunnel *pjTunnel;
//@property BOOL uidLoginStatus, isUidLoginPortSuccess, isTunnelStopping;
@property (nonatomic) int tunnelInterval , delayTime, resendDelay, retryCount, lastRetryCount, reDownloadCount, uploadCount;

+ (DataManager*)sharedInstance;
- (NSString*)getType:(NSString*)ext;
- (UIImage*)getImageWithType:(NSString*)type ext:(NSString*)ext;
- (NSString*)getUTI:(NSString*)type;
//- (NSString*)getDownloadURL;
//- (NSString*)getUploadURL;

// 預覽使用的下載函式
- (void)download:(NSString*)fullfilename type:(NSString*)type completion:(void (^)(NSString *file))completion error:(void (^)(void))error;
- (void)download:(NSString*)fullfilename completion:(void (^)(NSString *file))completion error:(void (^)(void))error;

// 加入下載 list
- (void)addDownload:(NSString*)fullfilename saveToAlbum:(BOOL)saveToAlbum;
- (void)doDownload;
- (void)doDownload:(NSString*)fullfilename
          filename:(NSString*)filename
  withSuccessBlock:(void (^)())success
      failureBlock:(void (^)())failure
       saveToAlbum:(BOOL)saveToAlbum
              type:(NSString*)type;

// 加入上傳 list
- (void)addUpload:(NSString*)fullfilename;
- (void)addUploadByImage:(UIImage*)image tImageName:(NSString*)tImageName;
- (void)addUploadByVideo:(ALAssetRepresentation *)rep videoName:(NSString*)videoName;

- (void)doUpload;
- (void)doUpload:(NSString*)fullfilename withSuccessBlock:(void (^)())success
    failureBlock:(void (^)())failure
     isFromAlbum:(bool)isFromAlbum;

- (void)stopDownload;
- (void)stopDownloadAndDoNext:(bool)doNext;
- (void)stopUpload;
- (void)stopUploadAndDoNext:(bool)doNext;

- (UIImage*)smallPhoto:(NSString*)filePath width:(float)width height:(float)height;

//判斷是否有特殊字元
- (BOOL)checkFileName:(NSString*)name;

-(NSDictionary*)fetchSSIDInfo;
-(NSString*)getLocalIP;

-(void)resetTunnel;

- (UIImage*)getImageOfflineWithType:(NSString*)type ext:(NSString*)ext;

- (void)addPhotoByImage:(UIImage*)image tImageName:(NSString*)tImageName;

- (void)startfindDeviceByUDP;

- (UIImage*)imageByScalingForSize:(CGSize)targetSize image:(UIImage*)sourceImage;
@end
