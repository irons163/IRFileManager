//
//  MainPageViewController.m
//
//  Created by Phil on 2015/8/17.
//

#import "MainPageViewController.h"
#import "DocumentListViewController.h"
#import "PhotoCollectionViewController.h"
//#import "LoginViewController.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "CommonTools.h"
//#import "IntroductionViewController.h"
#import "AppDelegate.h"
//#import "dataDefine.h"
//#import "PasscodeLockSettingViewController.h"
//#import "SecurityPinManager.h"
//#import "StaticLanguage.h"
#import "IRLanguageManager.h"
#import <IRPasscode/IRPasscode.h>

@interface MainPageViewController ()
{
    
}
@end

@implementation MainPageViewController{
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
    self.passcodeLockButton.selected = [IRSecurityPinManager sharedInstance].pinCode;
    if (self.passcodeLockButton.selected) {
        [[IRSecurityPinManager sharedInstance] presentSecurityPinViewControllerForUnlockWithAnimated:YES completion:nil result:nil];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self gotImportFileInfo];
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
#ifdef MESSHUDrive
            [[UILabel appearanceWhenContainedIn:[DocumentListViewController class], nil] setTextColor:[UIColor colorWithColorCodeString:TextColor]];
#endif
    
    self.allButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.title = _(@"IRFileManagerTitle");
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor]];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.documentTitleLabel.text = _(@"Document");
    self.videoTitleLabel.text = _(@"Video");
    self.albumTitleLabel.text = _(@"Photo");
    self.musicTitleLabel.text = _(@"Music");
    self.allTitleLabel.text = _(@"All");
    [self.messageCenterButton setTitle:_(@"NOTIFICATION_CENTER_TITLE") forState:UIControlStateNormal];
    [self.personalStorageButton setTitle:[NSString stringWithFormat:@"%@ >", _(@"PERSONAL_CLOUD_STORAGE_TITLE")] forState:UIControlStateNormal];
    
    [self.navigationController.navigationBar setNeedsLayout];
    
    for(NSLayoutConstraint *c in self.view.constraints) {
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

- (IBAction)passcodeLockClick:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem.tintColor = UIColor.whiteColor;
    
    NSBundle *xibBundle = [NSBundle bundleForClass:[IRPasscodeLockSettingViewController class]];
    IRPasscodeLockSettingViewController *vc = [[IRPasscodeLockSettingViewController alloc] initWithNibName:@"IRPasscodeLockSettingViewController" bundle:xibBundle];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)gotImportFileInfo{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.importFile) {
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

@end
