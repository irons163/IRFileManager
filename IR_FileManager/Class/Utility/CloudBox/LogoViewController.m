//
//  LogoViewController.m
//  CloudBox
//
//  Created by Wowoya on 13/2/28.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "LogoViewController.h"
#import "LoginViewController.h"
#import "MainPageViewController.h"
#import "UIColor+Helper.h"

#import "FirmwareSwitchDialogView.h"
#import "StorageSelectWarningView.h"
#import "StorageDeleteView.h"
#import "AutoUploadFolderNameView.h"
#import "SuccessView.h"
#import "LoadingView.h"
#import "FirmwareDialogView.h"
#import "firmwareViewController.h"
#import "DialogView.h"
#import "IntroductionViewController.h"
#import "dataDefine.h"
#import "PasscodeLockSettingViewController.h"

#ifdef MESSHUDrive
#import "ColorDefine.h"
#import "DiskViewController.h"
#import "OnLineFilesViewController.h"
#import "DocumentListViewController_online.h"
#import "PhotoCollectionViewController_online.h"
#import "UploadingViewController_online.h"
#import "FirmwareSwitchDialogView.h"
#import "StorageDeleteView.h"
#import "AboutDetailViewController.h"
#import "EncryptionTypeViewController.h"
#import "InfoViewController.h"
#import "RebootingViewController.h"
#import "PhotoCollectionViewController.h"
#import "MainPageViewController.h"
#import "OnLineTabBarViewController.h"
#import "ClientManagerViewController.h"
#import "AdvancedStatusViewController.h"
#import "AboutViewController.h"
#import "WirelessSettingViewController.h"
#import "SettingViewController.h"
#import "AZAPreviewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "ClientManagerTableViewCell.h"
#import "UIButton+appearence.h"
#endif

@interface LogoViewController ()

@end

@implementation LogoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    int64_t delayTime = 5;
#ifdef MESSHUDrive
    delayTime = 3;
    [[UILabel appearanceWhenContainedIn:[OnLineTabBarViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[MainPageViewController_online class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[DiskViewController class], nil] setHighlightedTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[OnLineFilesViewController class],[OnLineTabBarViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[DocumentListViewController_online class], nil] setHighlightedTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[PhotoCollectionViewController_online class],[OnLineTabBarViewController class], nil] setTextColor:[UIColor whiteColor]];


    [[UILabel appearanceWhenContainedIn:[UploadingViewController_online class], nil] setHighlightedTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[DownloadingViewController_online class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[OnlineFGalleryViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[FirmwareSwitchDialogView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[FirmwareDialogView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[firmwareViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[DialogView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[StorageSelectWarningView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[StorageDeleteView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[AutoUploadFolderNameView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[SuccessView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[LoadingView class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[CustomDataPicker class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    
    [[UILabel appearanceWhenContainedIn:[AboutDetailViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[AboutViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    //setting
    [[UILabel appearanceWhenContainedIn:[AdvancedStatusViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[ClientManagerViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[EncryptionTypeViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[WirelessSettingViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[RebootingViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[SettingViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    //offline
    [[UILabel appearanceWhenContainedIn:[LoginViewControllerForOffline class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[InfoViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[UploadingViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[OfflineFGalleryViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[PhotoCollectionViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[MainPageViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[IntroductionViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
    [[UILabel appearanceWhenContainedIn:[PlayerViewController class], nil] setTextColor:[UIColor whiteColor]];
    
    [[UISwitch appearance] setOnTintColor:[UIColor colorWithColorCodeString:SwitchColor]];
    [[UIActivityIndicatorView appearance] setColor:[UIColor colorWithColorCodeString:ProgressBarColor]];
    [[UIActivityIndicatorView appearanceWhenContainedIn:[LoginViewController class], nil] setColor:[UIColor whiteColor]];
    [[UIActivityIndicatorView appearanceWhenContainedIn:[PlayerViewController class], nil] setColor:[UIColor whiteColor]];
    
//    [[UIButton appearanceWhenContainedIn:[UIWindow class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
//    [[UIButton appearanceWhenContainedIn:[UIWindow class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UINavigationBar class],[UIWindow class], nil] setAppearanceTitleColor:[UIColor whiteColor]                                                                                       forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[KxVideoViewController class],[UIWindow class], nil] setAppearanceTitleColor:[UIColor whiteColor]                                                                                       forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[KxMovieViewController class],[UIWindow class], nil] setAppearanceTitleColor:[UIColor whiteColor]                                                                                       forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[OnLineTabBarViewController class],[UIPresentationController class],[UIWindow class],  nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UIPresentationController class],[UIWindow class],  nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[DownloadingViewController_online class],[UIPresentationController class],[UIWindow class],  nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UploadingViewController class],[UIPresentationController class],[UIWindow class],  nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UploadingViewController_online class],[UIPresentationController class],[UIWindow class],  nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
//    [[UIButton appearanceWhenContainedIn:[UINavigationBar class],  nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [[UIButton appearanceWhenContainedIn:[OnLineTabBarViewController class],  nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [[UIButton appearanceWhenContainedIn:[UINavigationBar class],[OnLineTabBarViewController class],[UIPresentationController class],  nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [[UIButton appearanceWhenContainedIn:[OnLineTabBarViewController class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[PhotoCollectionViewController_online class], [OnLineTabBarViewController class],[UIPresentationController class], [UIWindow class],nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[CustomDataPicker class],[OnLineTabBarViewController class], [UIWindow class],nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UINavigationBar class],[AZAPreviewController class],[UIPresentationController class],[UIWindow class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[AZAPreviewController class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UIWindow class], nil] setAppearanceTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[LoginViewController class],[UIWindow class], nil] setAppearanceTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[MainPageViewController class],[UIWindow class], nil] setAppearanceTitleColor:[UIColor colorWithColorCodeString:TextColor] forState:UIControlStateNormal];
    
    
    [[UINavigationBar appearanceWhenContainedIn:[AZAPreviewController class], nil] setTintColor:[UIColor colorWithColorCodeString:SwapTextColor]];
    [[UIButton appearanceWhenContainedIn:[ClientManagerTableViewCell class], [ClientManagerViewController class],[UIWindow class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn: [AdvancedStatusViewController class],[UIWindow class], nil] setTitleColor:[UIColor colorWithColorCodeString:SwapTextColor] forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearanceWhenContainedIn: [QBImagePickerController class],[UIWindow class], nil] setTintColor:[UIColor whiteColor]];
    
//    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[[UIPresentationController class], [UINavigationBar class]]] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //    [[UITextField appearance].attributedPlaceholder setValue:[UIColor colorWithRGB:0xCC0000] forKey:NSForegroundColorAttributeName];
    //    [[UITextField appearance] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}]];
    
    //    [[UILabel appearanceWhenContainedIn:[UINavigationBar class], nil] setTextColor:[UIColor colorWithRGB:0xCC0000]];
    
    //    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRGB:0xCC0000]];
    //    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
#else
    [[UIActivityIndicatorView appearance] setColor:[UIColor colorWithRGB:0x00b4f5]];
    [[UISwitch appearance] setOnTintColor:[UIColor colorWithRGB:0x00b4f5]];
    [[UISwitch appearanceWhenContainedIn:[PasscodeLockSettingViewController class], nil] setOnTintColor:[UIColor colorWithRGB:0x66DD00]];
#endif
    
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationNone];
    NSString * welcomeGifFileStr;
    if([[UIScreen mainScreen] bounds].size.height == 480){ //4s
        welcomeGifFileStr = @"EnFile_welcome_960";
    }else
        welcomeGifFileStr = @"EnFile_welcome_1136";
    
    self.webViewToDisplayGIF.scrollView.scrollEnabled = NO;
    self.webViewToDisplayGIF.scrollView.bounces = NO;
    
    NSData *data = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:welcomeGifFileStr ofType:@"gif"]];
    [self.webViewToDisplayGIF loadData:data MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
    self.webViewToDisplayGIF.scalesPageToFit = YES;
    [self.webViewToDisplayGIF setOpaque:NO];
    
    //**************** Add Static loading image to prevent white "flash" ****************/
    UIImage *loadingImage = [UIImage imageNamed:welcomeGifFileStr];
    UIImageView *loadingImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    loadingImageView.image = loadingImage;
    [self.view insertSubview:loadingImageView atIndex:0];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:[[self navigationController] viewControllers]];
        [viewControllers removeLastObject];

        MainPageViewController *sview = [[MainPageViewController alloc] initWithNibName:@"MainPageViewController" bundle:nil];
        [viewControllers addObject:sview];
        
        if ([[NSUserDefaults standardUserDefaults] stringForKey:INTRODUCTION_KEY] == nil){
            IntroductionViewController *introductionViewController = [[IntroductionViewController alloc] initWithNibName:@"IntroductionViewController" bundle:nil];
            [viewControllers addObject:introductionViewController];
        }
        
        [[self navigationController] setViewControllers:viewControllers animated:YES];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationNone];
        
        if(self.delegate)
            [self.delegate didFinishedLogoAnim];
    });
    
}

- (void)viewDidAppear:(BOOL)animated{
}

- (void)viewWillAppear:(BOOL)animated{
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
