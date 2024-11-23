//
//  AppDelegate.m
//  IR_FileManager
//
//  Created by Phil on 2019/7/1.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "AppDelegate.h"
#import "WelcomeViewController.h"
#import <IRShareManager/IRShare.h>
#import <IRPasscode/IRPasscode.h>
#import "FileTypeUtility.h"
#import "DBManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil]];
    [self.window makeKeyAndVisible];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        [[IRSecurityPinManager sharedInstance] removePinCode];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Setup CoreData with MagicalRecord
    // Step 1. Setup Core Data Stack with Magical Record
    // Step 2. Relax. Why not have a beer? Surely all this talk of beer is making you thirsty…
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"IRFileManager"];
    
    [self saveImageIfExistInActionExtention];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    [self saveImageIfExistInActionExtention];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)saveImageIfExistInActionExtention {
    [IRShare sharedInstance].groupID = @"group.IRMusicPlayer-AppStore";
    NSURL *directoryURL = [IRShare sharedInstance].directoryURL;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
    
    for(NSURL *url in urlsToDelete){
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
}

- (void)saveImportFileIntoDB:(NSURL *)url autoOpenFileWhileAPPapear:(BOOL)autoOpen {
    NSString *fileName = [[url absoluteString] lastPathComponent];
    fileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]];
    
    fileName = [[DBManager sharedInstance] getNewFileNameIfExistsByFileName:fileName];
    
    NSString *filePath = [resourceDocPath stringByAppendingPathComponent:fileName];

    [[NSFileManager defaultManager] copyItemAtPath:[url path] toPath:filePath error:nil];

    NSString *fileTypeString = [FileTypeUtility getFileType:[fileName pathExtension]];
    File *file = [File MR_createEntity];
    file.name = fileName;
    file.type = fileTypeString;
    file.size = [[FileTypeUtility getFileSize:filePath] longLongValue];
    file.createTime = [FileTypeUtility getFileCreationTimeFromPath:filePath];
    
    [[DBManager sharedInstance] save];
    
    if(!autoOpen)
        return;
    
//    self.importFile = file;
}



@end
