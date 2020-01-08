//
//  AppDelegate.m
//  CloudBox
//
//  Created by Wowoya on 13/2/7.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "AppDelegate.h"

#import "DocumentListViewController.h"
#import "KxMovieViewController.h"
#import "KxVideoViewController.h"

#import "LoggerClient.h"
#import "DataManager.h"
#import <MediaPlayer/MPMoviePlayerController.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <QuickLook/QuickLook.h>

#ifdef enshare
//#import <Google/Analytics.h>
#endif

#import "EnShareTools.h"
#import "MainPageViewController.h"
//#import <OneSignal/OneSignal.h>
#import "CommonTools.h"
#import "dataDefine.h"

//@class FGalleryViewController;

@implementation AppDelegate{
    BOOL mFlag;
    NSTimer* backgroundTimer;
    SCNetworkReachabilityRef proxyReachability;
}

- (void) handleTimer: (NSTimer *) timer{
    [backgroundTimer invalidate];
    backgroundTimer = nil;
    if (![DataManager sharedInstance].isAudioPlaying) {
        [[DataManager sharedInstance] resetTunnel];
        NSLog(@"Time out stop all tunnel");
        [[DataManager sharedInstance].uiViewController popToRootViewControllerAnimated:YES];
    }else{
        backgroundTimer=[NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(handleTimer:) userInfo:nil repeats:NO];
        NSLog(@"Restart timer");
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    //    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge)];
    
    //當App沒有運行或者被kill掉的時候，推送會調用這個
//    NSDictionary *pushDict = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//    if (pushDict) {
//        NSLog(@"Received Notification");
//        if([CommonTools getIosVersionNumber] < 10)
//            [self application:application didReceiveRemoteNotification:pushDict];
//    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        [[SecurityPinManager sharedInstance] removePinCode];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    LogoViewController *sview = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"LogoViewController"];
    sview.delegate = self;
    [((UINavigationController*)self.window.rootViewController)setToolbarHidden:NO animated:NO];
    [((UINavigationController*)self.window.rootViewController) pushViewController:sview animated:NO];
    
    /*
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge categories:nil]];
    }
 
    
    [OneSignal initWithLaunchOptions:launchOptions appId:@"2e08dcb7-ae09-4223-89bf-970856c7f2e3" handleNotificationReceived:^(OSNotification *notification) {
        // This block gets called when the user reacts to a notification received
        if([CommonTools getIosVersionNumber] < 10){
            [self saveNotification:notification.payload];
        }
    } handleNotificationAction:^(OSNotificationOpenedResult *result) {
        NSLog(@"Notification result - %@", result.notification.payload.notificationID);
        
        //Need add this to make sure notification opened when app closed.
        NSDictionary *pushDict = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        // This block gets called when the user reacts to a notification received
        if([CommonTools getIosVersionNumber] < 10 && result.action.type == OSNotificationActionTypeOpened && pushDict){
            [self saveNotification:result.notification.payload];
        }
        
    } settings:@{kOSSettingsKeyInFocusDisplayOption : @(OSNotificationDisplayTypeNotification), kOSSettingsKeyAutoPrompt : @NO}];
    
    [OneSignal IdsAvailable:^(NSString *userId, NSString *pushToken) {
        if(pushToken) {
            NSLog(@"Received push token - %@", pushToken);
            NSLog(@"User ID - %@", userId);
        }
    }];
     */
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        [self saveNotificationIfExistInActionExtention];
        [self saveImageIfExistInActionExtention];
        
    });
    
    [self setupNetworkReachabilityCallback];
    
    signal(SIGPIPE, SIG_IGN);
    
    return YES;
}
/*
-(void)saveNotification:(OSNotificationPayload*) payload{
    NSString* messageTitle = payload.title;
    NSString* messageSubtitle = payload.subtitle;
    NSString* fullMessage = [payload.body copy];
    NSDate* date = [self notificationStringToDate:messageSubtitle];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableArray *notificationItems = [NSMutableArray arrayWithArray:[userDefault arrayForKey:@"Notification"]];
    
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setValue:messageTitle forKey:@"title"];
    [dic setValue:messageSubtitle forKey:@"subtitle"];
    [dic setValue:fullMessage  forKey:@"message"];
    
    if(date)
        [dic setValue:date  forKey:@"date"];
    else
        [dic setValue:[NSDate date] forKey:@"date"];
    
    [notificationItems addObject:dic];
    
    [userDefault setObject:notificationItems forKey:@"Notification"];
    [userDefault synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendNotification" object:dic];
}
*/
- (NSDate*)notificationStringToDate: (NSString*) theString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate *dateFromString = [[NSDate alloc] init];
    
    dateFromString = [dateFormatter dateFromString:theString];
    
    return dateFromString;
}

- (void)applicationWillResignActive:(UIApplication *)application{
    NSLog(@"WillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    NSLog(@"DidEnterBackground");
    
    backgroundTimer=[NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(handleTimer:) userInfo:nil repeats:NO];
    NSLog(@"Start timer");
    
    if (!mFlag) {
        mFlag = YES;
        
        // 時間到了會執行這個block
        __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
            mFlag = NO;
        }];
        
        // 在背景執行一些東西...
        // 在這邊我用一個無窮迴圈來測試
        // backgroundTimeRemaining 會開始倒數10分鐘
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // run something background
            NSLog(@"App in BG!");
            //int i = 0;
            while (YES) {
                [NSThread sleepForTimeInterval:1];
            }
            // when finish, call this method
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
            mFlag = NO;
        });
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
    NSLog(@"applicationWillEnterForeground");
    
    [self openSecurityPinPage];
    
    if (backgroundTimer) {
        [backgroundTimer invalidate];
        backgroundTimer = nil;
        NSLog(@"STOP TIMER");
    }
    
    [[DataManager sharedInstance] startfindDeviceByUDP];
    
//    [self saveNotificationIfExistInActionExtention];
    [self saveImageIfExistInActionExtention];
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    NSLog(@"applicationDidBecomeActive");
}

- (void)openSecurityPinPage {
    if ([SecurityPinManager sharedInstance].pinCode)
        [[SecurityPinManager sharedInstance] presentSecurityPinViewControllerForUnlockWithAnimated:YES completion:nil result:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application{
    NSLog(@"WillTerminate");
}

-(UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (NSUInteger) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if ([window.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]] == TRUE){
        return UIInterfaceOrientationMaskAll;
    }else if ([window.rootViewController.presentedViewController isKindOfClass:MPMoviePlayerViewController.class] == TRUE){
        return UIInterfaceOrientationMaskAll;
    }else if ([window.rootViewController.presentedViewController isKindOfClass:QLPreviewController.class] == TRUE){
        return UIInterfaceOrientationMaskAll;
//    }else if ([window.rootViewController.presentedViewController isKindOfClass:FGalleryViewController.class] == TRUE){
//        return UIInterfaceOrientationMaskAll;
    }
    else if ([[[(UINavigationController*)self.window.rootViewController viewControllers]lastObject] isKindOfClass:KxMovieViewController.class] == TRUE){
        return UIInterfaceOrientationMaskAll;
    }
    else if ([[[(UINavigationController*)self.window.rootViewController viewControllers]lastObject] isKindOfClass:KxVideoViewController.class] == TRUE){
        return UIInterfaceOrientationMaskAll;
    }
    else if([[[self topMostController] class].description isEqualToString:@"KxMovieViewController"]){
        return UIInterfaceOrientationMaskAll;
    }
    else
        return UIInterfaceOrientationMaskPortrait;
}

//別的APP share資料到enShare
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

#ifdef MESSHUDrive
    if ([url.scheme isEqualToString:@"MESSHUDriveByEnGenius"]) {
#else
    if ([url.scheme isEqualToString:@"EnFileByEnGenius"]) {
#endif
        [self handleLoginInfoFromEnMesh:url];
        return YES;
    }

#ifdef MESSHUDrive
    if([url.scheme isEqualToString:@"MESSHUDriveByEnGeniusForShare"]){
#else
    if([url.scheme isEqualToString:@"EnFileByEnGeniusForShare"]){
#endif
        [self handleImportFileFromActionExtention];
    }else{
        [self handleImportFileFromUrl:url];
    }
    
    return YES;
}

- (void)handleLoginInfoFromEnMesh:(NSURL*)url
{
    NSString *strUrl = [url absoluteString];
    
    NSArray *aryUrl = [strUrl componentsSeparatedByString:@"?"];
    NSArray *aryParms = [((NSString *)[aryUrl objectAtIndex:1]) componentsSeparatedByString:@"&"];
    NSDictionary *jsonDict = nil;
    
    for (NSString *tmpstr in aryParms)
    {
        NSArray *aryData = [tmpstr componentsSeparatedByString:@"="];
        if([@"list" isEqualToString:[aryData objectAtIndex:0]])
        {
            NSData *dt = [self dataForHexString:[aryData objectAtIndex:1]];
            
            NSString* newStr = [[NSString alloc] initWithData:dt
                                                     encoding:NSUTF8StringEncoding];
            
            NSError *error;
            jsonDict = [NSJSONSerialization JSONObjectWithData:[newStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        }
    }
    
    self.EnMeshInfoDictionary = [jsonDict copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:EnMeshLinkNotification object:nil];
}

- (void)handleImportFileFromActionExtention
{
    [self saveFileFromActionExtentionThenOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ImportFileAndOpenNotification object:nil];
}

- (void)handleImportFileFromUrl:(NSURL*)url
{
    [self saveImportFileIntoDB:url autoOpenFileWhileAPPapear:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ImportFileAndOpenNotification object:nil];
}

- (NSData*)dataForHexString:(NSString*)hexString
{
    if (hexString == nil) {
        return nil;
    }
    
    const char* ch = [[hexString lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* data = [NSMutableData data];
    while (*ch) {
        char byte = 0;
        if ('0' <= *ch && *ch <= '9') {
            byte = *ch - '0';
        } else if ('a' <= *ch && *ch <= 'f') {
            byte = *ch - 'a' + 10;
        }
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9') {
                byte += *ch - '0';
            } else if ('a' <= *ch && *ch <= 'f') {
                byte += *ch - 'a' + 10;
            }
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}

//share from NotificationActionExtention
-(void)saveNotificationIfExistInActionExtention{
#ifdef MESSHUDrive
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.fujitsu.MESSHUDrive"];
#else
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.senao.EnShare"];
#endif
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    directoryURL = [directoryURL URLByAppendingPathComponent:@"Library/NotificationCaches" isDirectory:YES]; // URL pointing to the directory you want to browse
    NSLog(@"%@", [NSString stringWithFormat:@"directoryURL:%@" , directoryURL]);
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    if(!directoryURL)
        return;
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *url in enumerator) {
        NSLog(@"url:%@", url);
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (! [isDirectory boolValue]) {
            NSData *dbFile = [[NSData alloc] initWithContentsOfURL:url];
            NSArray *json = [NSJSONSerialization JSONObjectWithData:dbFile options:kNilOptions error:nil];
            
            for(NSDictionary *notification in json){
                NSString* messageTitle = [notification objectForKey:@"title"];
                NSString* messageSubtitle = [notification objectForKey:@"subtitle"];
                NSString* fullMessage = [notification objectForKey:@"message"];
                NSDate* date = [self notificationStringToDate:messageSubtitle];
                
                NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                NSMutableArray *notificationItems = [NSMutableArray arrayWithArray:[userDefault arrayForKey:@"Notification"]];
                
                NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
                [dic setValue:messageTitle forKey:@"title"];
                [dic setValue:messageSubtitle forKey:@"subtitle"];
                [dic setValue:fullMessage  forKey:@"message"];
                
                if(date)
                    [dic setValue:date  forKey:@"date"];
                else
                    [dic setValue:[NSDate date] forKey:@"date"];
                
                [notificationItems addObject:dic];
                
                [userDefault setObject:notificationItems forKey:@"Notification"];
                [userDefault synchronize];
            }
            
            /* //can notify other view controller.
             [[NSNotificationCenter defaultCenter] postNotificationName: @"SendNotification" object:nil];
            */
        }
        
        [urlsToDelete addObject:url];
    }
    
    for(NSURL *url in urlsToDelete){
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
}

//share from ShareExtention
-(void)saveImageIfExistInActionExtention{
#ifdef MESSHUDrive
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.fujitsu.MESSHUDrive"];
#else
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.senao.EnShare"];
#endif
    NSFileManager *fileManager = [NSFileManager defaultManager];
    directoryURL = [directoryURL URLByAppendingPathComponent:@"Library/Caches" isDirectory:YES]; // URL pointing to the directory you want to browse
    NSLog(@"%@", [NSString stringWithFormat:@"directoryURL:%@" , directoryURL]);
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    if(!directoryURL)
        return;
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *url in enumerator) {
        NSLog(@"url:%@", url);
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (! [isDirectory boolValue]) {
            [self saveImportFileIntoDB:url autoOpenFileWhileAPPapear:NO];
        }
        
        [urlsToDelete addObject:url];
    }
    
    if(urlsToDelete.count > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName: @"ReloadNotificationHandle" object:nil];
        });
    }
    
    for(NSURL *url in urlsToDelete){
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
}

//share from ActionExtention
-(void)saveFileFromActionExtentionThenOpen{
#ifdef MESSHUDrive
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.fujitsu.MESSHUDrive"];
#else
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.senao.EnShare"];
#endif
    NSFileManager *fileManager = [NSFileManager defaultManager];
    directoryURL = [directoryURL URLByAppendingPathComponent:@"Library/NeedOpenFileCaches" isDirectory:YES]; // URL pointing to the directory you want to browse
    NSLog(@"%@", [NSString stringWithFormat:@"directoryURL:%@" , directoryURL]);
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    if(!directoryURL)
        return;
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *url in enumerator) {
        NSLog(@"url:%@", url);
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (! [isDirectory boolValue]) {
            [self saveImportFileIntoDB:url autoOpenFileWhileAPPapear:YES];
        }
        
        [urlsToDelete addObject:url];
    }
    
    for(NSURL *url in urlsToDelete){
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
}

-(void)saveImportFileIntoDB:(NSURL*)url autoOpenFileWhileAPPapear:(BOOL)autoOpen{
    // No error and it’s not a directory; do something with the file
//    NSData *dbFile = [[NSData alloc] initWithContentsOfURL:url];
    
    NSString *fileName = [[url absoluteString] lastPathComponent];
    fileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]];
    
    fileName = [self getNewFileNameIfExistsByFileName:fileName];
    
    NSString *filePath = [resourceDocPath stringByAppendingPathComponent:fileName];
    
//    [dbFile writeToFile:filePath atomically:YES];
    [[NSFileManager defaultManager] copyItemAtPath:[url path] toPath:filePath error:nil];
    
    NSString *fileTypeString = [[DataManager sharedInstance] getType:[fileName pathExtension]];
    //存入到資料庫
    NSString *uid = [NSString stringWithFormat:@"%d%d", (int)[[NSDate date] timeIntervalSince1970], arc4random() % 99999];
    [[DataManager sharedInstance].database sqliteInsert:@"Collection" keys:@ {
        @"uid" : uid,
        @"type" : fileTypeString,
        @"filename" : [fileName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        @"isdownload" : @"1",
        @"isfolder" : @"0",
        @"parentfolder" : @"/"
    }];
    
    if(!autoOpen)
        return;
    
    NSArray* readFromDB = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Collection WHERE type = '%@' AND isfolder = '%@' AND uid = '%@'; ", fileTypeString, @"0", uid]];
    
    NSDictionary* dic = [readFromDB firstObject];
    CollectionDataFile* file = [[CollectionDataFile alloc] initWithDatabaseNSDictionary:dic fileSize:[EnShareTools getFileSize:filePath] fileCreatedDate:[EnShareTools getFileCreationTimeFromPath:filePath]];
    self.importFile = file;
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

- (void)setupNetworkReachabilityCallback {
    SCNetworkReachabilityContext *ctx=NULL;
    //any internet cnx
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    if (proxyReachability) {
        NSLog(@"Cancelling old network reachability");
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(proxyReachability);
        proxyReachability = nil;
    }
    
    proxyReachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    
    if (!SCNetworkReachabilitySetCallback(proxyReachability, (SCNetworkReachabilityCallBack)networkReachabilityCallBack, ctx)){
        NSLog(@"Cannot register reachability cb: %s", SCErrorString(SCError()));
        return;
    }
    
    if(!SCNetworkReachabilityScheduleWithRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)){
        NSLog(@"Cannot register schedule reachability cb: %s", SCErrorString(SCError()));
        return;
    }
    
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
        networkReachabilityCallBack(proxyReachability,flags,(__bridge void *)(self));
    }
}

void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* targetObject){
    // Observed flags:
    // - nearly gone: kSCNetworkFlagsReachable alone (ignored)
    // - gone: kSCNetworkFlagsTransientConnection | kSCNetworkFlagsReachable | kSCNetworkFlagsConnectionRequired
    // - connected: kSCNetworkFlagsIsDirect | kSCNetworkFlagsReachable
    
    SCNetworkReachabilityFlags networkDownFlags=kSCNetworkReachabilityFlagsConnectionRequired |kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand;
    
    
    if ((flags == 0) || (flags & networkDownFlags)) {
        NSLog(@"Network DisConnected");
    }else{
        NSLog(@"Network Connected");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[DataManager sharedInstance] startfindDeviceByUDP];
        });
    }
}

- (void)didFinishedLogoAnim{
    if ([SecurityPinManager sharedInstance].pinCode)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
            [self openSecurityPinPage];
        });
}
        
@end
