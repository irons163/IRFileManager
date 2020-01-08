//
//  MainPageViewController.m
//  EnSmart
//
//  Created by Phil on 2015/8/17.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "MainPageViewController.h"
#import "EnShareTools.h"
#import "DocumentListViewController.h"
#import "PhotoCollectionViewController.h"
#import "LoginViewController.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "NotificationCenterMainViewController.h"
#import "CommonTools.h"
#import "IntroductionViewController.h"
#import "AppDelegate.h"
#import "dataDefine.h"
#import "PasscodeLockSettingViewController.h"

@interface MainPageViewController ()
{
    LoginViewController* loginView;
}
@end

@implementation MainPageViewController{
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
    self.passcodeLockButton.selected = [SecurityPinManager sharedInstance].pinCode;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    loginView = nil;
    [self gotEnMeshInfo];
    [self gotImportFileInfo];
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
#ifdef MESSHUDrive
            [[UILabel appearanceWhenContainedIn:[DocumentListViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
#endif
    
    self.allButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.title = _(@"EnFile_TITLE");
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor]];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
    UIButton* introdoctionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
    UIImage *image = [UIImage imageNamed:@"info_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(24, 24)];
    [introdoctionButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"info_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(24, 24)];
    [introdoctionButton setImage:image forState:UIControlStateHighlighted];
    [introdoctionButton addTarget:self action:@selector(introdoctionButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:introdoctionButton];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-8];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight, rightItem, nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.documentTitleLabel.text = _(@"Document");
    self.videoTitleLabel.text = _(@"Video");
    self.albumTitleLabel.text = _(@"Photo");
    self.musicTitleLabel.text = _(@"Music");
    self.allTitleLabel.text = _(@"All");
    [self.messageCenterButton setTitle:_(@"NOTIFICATION_CENTER_TITLE") forState:UIControlStateNormal];
    [self.personalStorageButton setTitle:[NSString stringWithFormat:@"%@ >", _(@"PERSONAL_CLOUD_STORAGE_TITLE")] forState:UIControlStateNormal];
        
    [[DataManager sharedInstance].database sqliteDelete:@"Uploading" keys:nil];
    [[DataManager sharedInstance].database sqliteDelete:@"Downloading" keys:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotEnMeshInfo) name:EnMeshLinkNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotImportFileInfo) name:ImportFileAndOpenNotification object:nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
    
    for(NSLayoutConstraint *c in self.view.constraints){
        if(c.secondAttribute == NSLayoutAttributeTopMargin){
            NSLog(@"TopMargin");
            [NSLayoutConstraint deactivateConstraints:@[c]];
            [NSLayoutConstraint constraintWithItem:c.firstItem attribute:c.firstAttribute relatedBy:c.relation toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:c.multiplier constant:c.constant].active = YES;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)gotoDocumentPageClick:(id)sender {
    DocumentListViewController* mainPageViewController = [[DocumentListViewController alloc] initWithNibName:@"DocumentListViewController" bundle:nil];
    mainPageViewController.fileType = DOCUMENT_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoVideoPageClick:(id)sender {
    DocumentListViewController * mainPageViewController = [[DocumentListViewController alloc] initWithNibName:@"DocumentListViewController" bundle:nil];
    mainPageViewController.fileType = VIDEO_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoMusicPageClick:(id)sender {
    DocumentListViewController * mainPageViewController = [[DocumentListViewController alloc] initWithNibName:@"DocumentListViewController" bundle:nil];
    mainPageViewController.fileType = MUSIC_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoAlbumPageClick:(id)sender {
    PhotoCollectionViewController * mainPageViewController = [[PhotoCollectionViewController alloc] initWithNibName:@"PhotoCollectionViewController" bundle:nil];
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoAllPageClick:(id)sender {
    DocumentListViewController * mainPageViewController = [[DocumentListViewController alloc] initWithNibName:@"DocumentListViewController" bundle:nil];
    mainPageViewController.fileType = ALL_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoOnlineModeClick:(id)sender {
    loginView = [self.navigationController.storyboard  instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self.navigationController pushViewController:loginView animated:YES];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (IBAction)notificationClick:(id)sender {
    NotificationCenterMainViewController* noficationPage = [[NotificationCenterMainViewController alloc] initWithNibName:@"NotificationCenterMainViewController" bundle:nil];
    [self.navigationController pushViewController:noficationPage animated:YES];
}

- (IBAction)passcodeLockClick:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem.tintColor = UIColor.whiteColor;
    
    PasscodeLockSettingViewController *passcodeLockSettingViewController = [PasscodeLockSettingViewController new];
    [self.navigationController pushViewController:passcodeLockSettingViewController animated:YES];
}

- (void)introdoctionButtonDidClick{
    IntroductionViewController *introductionViewController = [[IntroductionViewController alloc] initWithNibName:@"IntroductionViewController" bundle:nil];
    [self.navigationController pushViewController:introductionViewController animated:YES];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)gotEnMeshInfo{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.EnMeshInfoDictionary) {
        if (loginView) {
            [self.navigationController popToViewController:loginView animated:NO];
            [loginView doLoginWithEnMesh];
        }else{
            [self.navigationController popToRootViewControllerAnimated:NO];
            [self gotoOnlineModeClick:nil];
        }
    }
}

- (void)gotImportFileInfo{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.importFile) {
        if(loginView){
            [[NSNotificationCenter defaultCenter] postNotificationName:LogoutNotification object:nil];
            [self.navigationController popToRootViewControllerAnimated:NO];
        }else{
            [self.navigationController popToRootViewControllerAnimated:NO];
            
            if ([appDelegate.importFile.type isEqualToString:@"MUSIC"]) {
                [self gotoMusicPageClick:nil];
            } else if ([appDelegate.importFile.type isEqualToString:@"VIDEO"]) {
                [self gotoVideoPageClick:nil];
            } else if ([appDelegate.importFile.type isEqualToString:@"PICTURE"]) {
                [self gotoAlbumPageClick:nil];
            } else if ([appDelegate.importFile.type isEqualToString:@"DOCUMENT"]) {
                [self gotoDocumentPageClick:nil];
            }
        }
    }
}

@end
