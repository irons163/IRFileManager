//
//  LoginViewController.m
//  CloudBox
//
//  Created by Wowoya on 13/2/28.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import "LoginViewController.h"
#import "Reachability.h"
#import "MainPageViewController_online.h"
#import "KGModal.h"
#import "DialogView.h"
#import "RouterGlobal.h"
#import "dataDefine.h"
#import "FirmwareDialogView.h"
#import "AppDelegate.h"
#import "firmwareViewController.h"
#import "UIColor+Helper.h"
#import "FirmwareSwitchDialogView.h"
#import "StorageSelectWarningView.h"
#import "StorageDeleteView.h"
#import "AutoUploadFolderNameView.h"
#import "SuccessView.h"
#import "LoadingView.h"
#import "WirelessSettingViewController.h"
#import "ClientManagerViewController.h"
#import "AdvancedStatusViewController.h"
#import "AboutViewController.h"
#import "CommonTools.h"
#import "OnLineTabBarViewController.h"
#import "SettingViewController.h"
#import "EnShareTools.h"
#import "AutoUpload.h"

#ifdef enshare
#import "SenaoGA.h"
#endif

#define MixDdnsUid 1

@implementation NSURLRequest(DataController)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host{
	return YES; // Should probably return YES only for a specific host
}

@end

@interface LoginViewController (){
    double keyboardHeight;
    double scrollViewMoveHeight;
    NSTimer *keepAliveTimer;
    id<deviceClassDelegate> delegate;
    BOOL isFirstAppear;
//#if MixDdnsUid
//    int tryUID,tryDDNS; //-1:不使用 0:等待使用 1:使用中 2:成功 3:失敗
//#endif
}

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    #ifdef smalink
        informationViewBtn.hidden = YES;
    #endif
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        scrollView.frame = CGRectMake(0, 20, scrollView.frame.size.width, scrollView.frame.size.height-20);
    } else {// iOS 6
    }
    [UIView setAnimationsEnabled:YES];
    
    keyboardHeight=216;
    loadingView.hidden = YES;
    
    //設定DDNS提示的View
    dnsLabel.hidden = YES;
    dnsLabel.alpha = 0;
    [hostLbl addTarget:self action:@selector(hostLblChange) forControlEvents:UIControlEventEditingChanged];
    dnsLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dnsLabelTap)];
    [dnsLabel addGestureRecognizer:tapGesture];
    
    [usernameLbl addTarget:self action:@selector(userNameLblChange) forControlEvents:UIControlEventEditingChanged];
    [passwordLbl addTarget:self action:@selector(passwordLblChange) forControlEvents:UIControlEventEditingChanged];
    
    //從 NSUserDefaults 取得記憶資料
    usernameLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY];
    passwordLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:PASSWORD_KEY];
    rememberBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:REMEMBER_KEY];
    hostLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:UID_DDNS_KEY];
    selectRemoteBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:REMOTE_SELECTED_KEY];
    
    versionLabel.text = [NSString stringWithFormat:@"%@%@", @"v", [EnShareTools getAppVersionName]];
    
    [self checkUIBySelectRemoteBtnStatus];
    
    usernameLbl.placeholder = @"";
    passwordLbl.placeholder = @"";
    hostLbl.placeholder = @"";
    
    cancelUserNameBtn.hidden = YES;
    cancelPasswordBtn.hidden = YES;
    cancelHostBtn.hidden = YES;
    
    [selectRemoteBtn setImage:[selectRemoteBtn imageForState:UIControlStateSelected] forState:(UIControlStateDisabled | UIControlStateSelected)];
    [rememberBtn setImage:[rememberBtn imageForState:UIControlStateSelected] forState:(UIControlStateDisabled | UIControlStateSelected)];
    
    [self selectDDNSClk:nil];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.EnMeshInfoDictionary) {
        [self doLoginWithEnMesh];
    }
    
    isFirstAppear = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:YES];
    
    cancelHostBtn.alpha = 0;
    
    if (keepAliveTimer) {
        [keepAliveTimer invalidate];
        keepAliveTimer = nil;
    }
    
    [[DeviceClass sharedInstance] stopLogin];
    [[DeviceClass sharedInstance] resetMasterConntectionDetail];
    [[AutoUpload sharedInstance] cancelUpload];
    
    // offline mode can upload, so not resetTunnel.
//    [[DataManager sharedInstance] resetTunnel];
    
    [DataManager sharedInstance].offline = FALSE;
    [DataManager sharedInstance].login = FALSE;
    [DataManager sharedInstance].loginTime = nil;
    
    if(!isFirstAppear && ![[NSUserDefaults standardUserDefaults] boolForKey:REMEMBER_KEY]){
        usernameLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY];
        passwordLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:PASSWORD_KEY];
        hostLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:UID_DDNS_KEY];
        rememberBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:REMEMBER_KEY];
        selectRemoteBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:REMOTE_SELECTED_KEY];
        selectDDNSBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:DDNS_SELECTED_KEY];
        selectUIDBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:UID_SELECTED_KEY];
        
        [self checkUIBySelectRemoteBtnStatus];
    }

    isFirstAppear = NO;
    
#if ConnectionType
    [DataManager sharedInstance].connectionType = @"Offline";
#endif
    
#ifdef enshare
    [SenaoGA setScreenName:@"LoginPage"];
#endif
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    NSLog(@"ReceiveMemoryWarning");
}

//當輸入DDNS時
- (void)hostLblChange{
    if (dnsLabel.hidden) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.5];
        dnsLabel.hidden = NO;
        dnsLabel.alpha = 1;
        [UIView commitAnimations];
    }
    
    if ([hostLbl.text rangeOfString:@"."].length>0) {
        dnsLabel.text = hostLbl.text;
        dnsLabel.hidden = YES;
    }else if ([hostLbl.text isEqualToString:@""]) {
        dnsLabel.hidden = YES;
    }else{
        dnsLabel.text = [NSString stringWithFormat:@"%@.engeniusddns.com",hostLbl.text];
    }
    
    if (![hostLbl.text isEqualToString:@""]) {
        cancelHostBtn.alpha = 1;
    }else{
        cancelHostBtn.alpha = 0;
    }
    
    #ifdef smalink
    dnsLabel.hidden = YES;
    #endif
}

//按下DDNS提示View
- (void)dnsLabelTap{
    if (!dnsLabel.hidden) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.5];
        dnsLabel.hidden = YES;
        hostLbl.text = dnsLabel.text;
        [UIView commitAnimations];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentTextField = textField;
    
    if (textField == usernameLbl) {
        scrollView.frame = CGRectMake(0, (scrollView.frame.origin.y - 150), scrollView.frame.size.width, scrollView.frame.size.height + 150);
        scrollView.contentSize = CGSizeMake(320, scrollView.frame.size.height + 150);
        
        if (![usernameLbl.text isEqualToString:@""]) {
            cancelUserNameBtn.alpha = 1;
        }
        
        dnsLabel.hidden = YES;
    }else if (textField == passwordLbl) {
        scrollView.frame = CGRectMake(0, (scrollView.frame.origin.y - 160), scrollView.frame.size.width, scrollView.frame.size.height + 160);
        scrollView.contentSize = CGSizeMake(320, scrollView.frame.size.height + 160);
        
        if (![passwordLbl.text isEqualToString:@""]) {
            cancelPasswordBtn.alpha = 1;
        }
        
        dnsLabel.hidden = YES;
    }else{
        scrollView.frame = CGRectMake(0, (scrollView.frame.origin.y - 170), scrollView.frame.size.width, scrollView.frame.size.height + 170);
        scrollView.contentSize = CGSizeMake(320, scrollView.frame.size.height + 170);
        
        if (![hostLbl.text isEqualToString:@""]) {
            cancelHostBtn.alpha = 1;
        }

    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    currentTextField = nil;
    
    START_ANIM(0.5);
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        scrollView.frame = CGRectMake(0, 20 , scrollView.frame.size.width, self.view.frame.size.height);
    }else{
        scrollView.frame = CGRectMake(0, 0 , scrollView.frame.size.width, self.view.frame.size.height);
    }
    
    scrollView.contentSize = CGSizeMake(320, self.view.frame.size.height);
    
    cancelUserNameBtn.alpha = 0;
    cancelPasswordBtn.alpha = 0;
    cancelHostBtn.alpha = 0;
    END_ANIM();
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

//當輸入user name
- (void)userNameLblChange{
    if (![usernameLbl.text isEqualToString:@""]) {
        cancelUserNameBtn.alpha = 1;
    }else{
        cancelUserNameBtn.alpha = 0;
    }
}

- (void)passwordLblChange{
    if (![passwordLbl.text isEqualToString:@""]) {
        cancelPasswordBtn.alpha = 1;
    }else{
        cancelPasswordBtn.alpha = 0;
    }
}

- (IBAction)cancelUserNameClk:(id)sender {
    usernameLbl.text = @"";
    cancelUserNameBtn.alpha = 0;
}

- (IBAction)cancelPasswordClk:(id)sender {
    passwordLbl.text = @"";
    cancelPasswordBtn.alpha = 0;
}

- (IBAction)cancelHostClk:(id)sender {
    if (selectUIDBtn.selected) {
//        uidLbl.text = @"";
        hostLbl.text = @"";
    }else{
//        uidLbl.text = @"";
        hostLbl.text = @"";
    }
    
    cancelHostBtn.alpha = 0;
}

//離線按鈕
- (IBAction)offlineClk:(id)sender {
    [DataManager sharedInstance].offline = TRUE;
    [DataManager sharedInstance].login = FALSE;
    [DataManager sharedInstance].loginTime = nil;
    [self.navigationController popToRootViewControllerAnimated:YES];
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"OfflineMode_LoginPage" Label:nil Value:nil];
#endif
}

- (void)localLogin{
    
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
        [self showAlert:_(@"LOGIN_ALERT_INTERNET")];
        return;
    }
    
    [self setButton:NO];
    [usernameLbl resignFirstResponder];
    [passwordLbl resignFirstResponder];
    [hostLbl resignFirstResponder];
    
    [[DeviceClass sharedInstance] destroySharedInstance];
    [[DataManager sharedInstance] resetTunnel];
    
    if (usernameLbl.text.length == 0) {
        [self showAlert:@"LOGIN_ALERT_USERNAME"];
        [self setButton:YES];
        return;
    }
    if ([Tools checkNetworkStatus] == FALSE) {
        [self showAlert:@"LOGIN_ALERT_INTERNET"];
        [self setButton:YES];
        return;
    }
    
    [self doLoginLocal];
    
#if ConnectionType
    [DataManager sharedInstance].connectionType = @"Local";
#endif
}

-(void)doLoginLocal{
    NSString *ip;
    if([DataManager sharedInstance].ipAddressFindByUDP){
        ip = [DataManager sharedInstance].ipAddressFindByUDP;
        NSLog(@"doLoginLocal use ipAddressFindByUDP : %@", ip);
    }else{
        ip = [DataManager sharedInstance].getLocalIP;
        NSLog(@"doLoginLocal use getLocalIP : %@", ip);
    }
    
    [[DeviceClass sharedInstance] doLoginWithAddress:ip UserName:usernameLbl.text Password:passwordLbl.text Scheme:@"http" Target:self];
}

//DNS登入按鈕
- (IBAction)remoteLoginClk:(id)sender {
    if(!selectRemoteBtn.selected){
        [self localLogin];
        return;
    }
    
    if([hostLbl.text rangeOfString:@"engeniusddns.com"].location != NSNotFound){
        [self selectDDNSClk:nil];
    }else if([CommonTools checkStaticIPInfo:hostLbl.text Type:StaticIPInfoIPType]){
        [self selectDDNSClk:nil];
    }else if([CommonTools checkUIDFormateValid:hostLbl.text]){
        [self selectUIDClk:nil];
    }else{
        [self showAlert:_(@"LOGIN_ALERT_UID_DDNS")];
        return;
    }
    
#if ConnectionType
    [DataManager sharedInstance].connectionType = @"";
#endif
    
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
        [self showAlert:_(@"LOGIN_ALERT_INTERNET")];
        return;
    }
    
    dnsLabel.hidden = YES;
    [self setButton:NO];
    [usernameLbl resignFirstResponder];
    [passwordLbl resignFirstResponder];
    [hostLbl resignFirstResponder];
    
    if (usernameLbl.text.length == 0) {
        [self showAlert:@"LOGIN_ALERT_USERNAME"];
        [self setButton:YES];
        return;
    }
    if ([Tools checkNetworkStatus] == FALSE) {
        [self showAlert:@"LOGIN_ALERT_INTERNET"];
        [self setButton:YES];
        return;
    }

    if (hostLbl.text.length == 0) {
        [self showAlert:@"LOGIN_ALERT_UID_DDNS_EMPTY"];
        [self setButton:YES];
        return;
    }
    
    [self doRemoteLoginWithUID:hostLbl.text withDDNS:hostLbl.text];
}

-(void) doRemoteLoginWithUID:(NSString*)uidStr withDDNS:(NSString*)ddnsStr{
    [[DeviceClass sharedInstance] destroySharedInstance];
//    [[DataManager sharedInstance] resetTunnel];
    
    NSString* scheme = @"http";
    
    if (selectUIDBtn.selected) {//UID Login
        
        [[DeviceClass sharedInstance] doLoginWithUID:uidStr UserName:usernameLbl.text Password:passwordLbl.text Scheme:scheme Target:self];
        
    }else{
        NSString *ddns;
        ddns = ddnsStr;
        
        [[DeviceClass sharedInstance] doLoginWithAddress:ddns UserName:usernameLbl.text Password:passwordLbl.text Scheme:scheme Target:self];
    }
}

- (void)doLoginWithEnMesh
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LogoutNotification object:nil];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary* EnMeshInfo = [appDelegate.EnMeshInfoDictionary copy];
    appDelegate.EnMeshInfoDictionary = nil;
    
    usernameLbl.text = EnMeshInfo[@"Account"];
    passwordLbl.text = EnMeshInfo[@"Password"];
    if ([EnMeshInfo[@"IsRemote"] boolValue] != selectRemoteBtn.selected) {
        [self selectRemoteLoginClk:nil];
    }
    
    if (selectRemoteBtn.selected) {
        hostLbl.text = EnMeshInfo[@"Info"];
    }else{
        hostLbl.text = @"";
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!selectRemoteBtn.selected) {
            [DataManager sharedInstance].ipAddressFindByUDP = EnMeshInfo[@"Info"];
        }
        [self remoteLoginClk:nil];
    });
}

#pragma mark deviceClassDelegate
-(void)finishLogin:(DeviceClass *)device Success:(BOOL)success Message:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSLog(@"Login Finish %@",message);
        
        if (success) {
            if ([message isEqualToString:@"OK"] || [message isEqualToString:@"GUEST"]) {
                [self saveUserDefault];
                [self getModelName];
                keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(keepAlive) userInfo:nil repeats:YES];
                [DataManager sharedInstance].offline = FALSE;
                [DataManager sharedInstance].login = TRUE;
                [DataManager sharedInstance].loginTime = [NSDate date];
                [DataManager sharedInstance].diskPath = nil;
                [DataManager sharedInstance].diskGuestPath = nil;
                [DataManager sharedInstance].usbUploadPath = nil;
                [DataManager sharedInstance].lanIPAddress = nil;
                
                [self gotoStorageViewController];
            }else{
                [DataManager sharedInstance].offline = FALSE;
                [DataManager sharedInstance].login = FALSE;
                [DataManager sharedInstance].loginTime = nil;
                [self showAlert:@"LOGIN_ALERT_FAILED"];
            }
        }else{
            [DataManager sharedInstance].offline = FALSE;
            [DataManager sharedInstance].login = FALSE;
            [DataManager sharedInstance].loginTime = nil;
            [self showAlert:@"LOGIN_ALERT_CONNECTING"];
        }
        
        [self setButton:YES];
        
        if([DataManager sharedInstance].modelType == 1 && self.presentedViewController){
            if(delegate)
                [delegate finishLogin:device Success:success Message:message];
        }
    });
}

-(void)gotoStorageViewController{
    BOOL isPresentWithAnimate = YES;
    
    if([DataManager sharedInstance].modelType == 1 && self.presentedViewController){
        return;
    }
    
    MainPageViewController_online *sview = [[MainPageViewController_online alloc] initWithNibName:@"MainPageViewController_online" bundle:nil];
    UINavigationController* onLineNavigationViewController = [[UINavigationController alloc] initWithRootViewController:sview];
    sview.delegate = self;
    
    OnLineTabBarViewController* onLineTabBarViewController = [[OnLineTabBarViewController alloc] initWithNibName:@"OnLineTabBarViewController" bundle:nil];
    
    SettingViewController *settingViewController = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    UINavigationController* settingNavigationViewController = [[UINavigationController alloc] initWithRootViewController:settingViewController];
    
    AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    UINavigationController* aboutNavigationViewController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    
    NSArray *threeViewControllers = [[NSArray alloc]initWithObjects:settingNavigationViewController, onLineNavigationViewController, aboutNavigationViewController, nil];
    [onLineTabBarViewController setViewControllers:threeViewControllers];
    
    [self presentViewController:onLineTabBarViewController animated:isPresentWithAnimate completion:^{
    }];
}

- (IBAction)selectRemoteLoginClk:(id)sender {
    selectRemoteBtn.selected = !selectRemoteBtn.selected;
    [self checkUIBySelectRemoteBtnStatus];
}

- (void)checkUIBySelectRemoteBtnStatus{
    if (selectRemoteBtn.selected) {
        hostLbl.alpha = 0;
        dnsTitleLabel.hidden = NO;
        hostLbl.hidden = NO;
#ifdef MESSHUDrive
        hostView.hidden = NO;
#endif
        [UIView animateWithDuration:0.5 animations:^{
            dnsTitleLabel.alpha = 1;
            hostLbl.alpha = 1;
            dnsLabel.alpha = 1;
#ifdef MESSHUDrive
            hostView.alpha = 1;
#endif
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            dnsTitleLabel.alpha = 0;
            hostLbl.alpha = 0;
            dnsLabel.alpha = 0;
#ifdef MESSHUDrive
            hostView.alpha = 0;
#endif
        } completion: ^(BOOL finished) {
            dnsTitleLabel.hidden = YES;
            hostLbl.hidden = YES;
            dnsLabel.hidden = YES;
#ifdef MESSHUDrive
            hostView.hidden = finished;
#endif
        }];
    }
}

- (IBAction)rememberClk:(id)sender {
    rememberBtn.selected = !rememberBtn.selected;
}

- (IBAction)selectUIDClk:(id)sender {
    dnsLabel.hidden = YES;
    cancelHostBtn.alpha = 0;
    selectUIDBtn.selected = YES;
    selectDDNSBtn.selected = NO;
    if (currentTextField == hostLbl) {
        [self hostLblChange];
    }else{
        cancelHostBtn.alpha = 0;
    }
}

- (IBAction)selectDDNSClk:(id)sender {
    cancelHostBtn.alpha = 0;
    selectUIDBtn.selected  = NO;
    selectDDNSBtn.selected  = YES;
    
    if (currentTextField == hostLbl) {
        [self hostLblChange];
    }else{
        cancelHostBtn.alpha = 0;
    }
}

#pragma mark - QR result Call back
- (void)readResult:(NSString*)result{
    NSString *temp = [self formatQRString:result];
    if (temp != nil) {
        hostLbl.text = temp;
    }else{
        [self showAlert:@"LOGIN_ALERT_QR"];
    }
}

- (void)resultFromImage:(NSString*)result{
    NSString *temp = [self formatQRString:result];
    if (temp != nil) {
        hostLbl.text = temp;
    }else{
        [self showAlert:@"LOGIN_ALERT_QR"];
    }
}

- (NSString*)formatQRString:(NSString*)qrString{
    if([qrString hasPrefix:@"http://"]){
        if ([qrString rangeOfString:@".engeniusddns.com"].length > 0) {
            NSArray *array = [qrString componentsSeparatedByString:@"."];
            NSString *str = [array[0] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            return str;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

//按下登入按鈕，將按鈕設定成disable，並秀出Loading
- (void)setButton:(BOOL)tag{
    offlineBtn.enabled = informationViewBtn.enabled = tag;
    remoteLoginBtn.enabled = tag;
    selectRemoteBtn.enabled = rememberBtn.enabled = tag;
    usernameLbl.enabled = passwordLbl.enabled = hostLbl.enabled = tag;
    cancelHostBtn.alpha = 0;
    loadingView.hidden = tag;
}

//存入記憶資料到 NSUserDefaults
- (void)saveUserDefault{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    if (rememberBtn.selected) {
        [userDefault setObject:@(rememberBtn.selected) forKey:REMEMBER_KEY];
        [userDefault setObject:@(selectRemoteBtn.selected) forKey:REMOTE_SELECTED_KEY];
        [userDefault setObject:usernameLbl.text forKey:USERNAME_KEY];
        [userDefault setObject:passwordLbl.text forKey:PASSWORD_KEY];
        
        if (selectDDNSBtn.selected == TRUE) {
            [userDefault setObject:hostLbl.text forKey:UID_DDNS_KEY];
            [userDefault setBool:selectDDNSBtn.selected forKey:DDNS_SELECTED_KEY];
            [userDefault setBool:selectUIDBtn.selected forKey:UID_SELECTED_KEY];
        }
        
        if (selectUIDBtn.selected == TRUE) {
            [userDefault setObject:hostLbl.text forKey:UID_DDNS_KEY];
            [userDefault setBool:selectDDNSBtn.selected forKey:DDNS_SELECTED_KEY];
            [userDefault setBool:selectUIDBtn.selected forKey:UID_SELECTED_KEY];
        }
    } else {
        [userDefault setObject:@(rememberBtn.selected) forKey:REMEMBER_KEY];
        [userDefault setObject:@(NO) forKey:REMOTE_SELECTED_KEY];
        
        [userDefault setObject:@"" forKey:USERNAME_KEY];
        [userDefault setObject:@"" forKey:PASSWORD_KEY];
        
        [userDefault setObject:@"" forKey:UID_DDNS_KEY];
        [userDefault setBool:NO forKey:DDNS_SELECTED_KEY];
        [userDefault setBool:NO forKey:UID_SELECTED_KEY];
    }
    
    [userDefault synchronize];
}

- (void)dialogOk {

}

//取得 router 的 Model Name，並且判斷是否符合版本要求
- (void)getModelName{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getDeviceSettings:^(NSDictionary *resultDictionary) {
        NSString *modelName = [resultDictionary objectForKey:@"ModelName"];
        //LogMessage(nil, 0, @"GetDeviceSettings : %@", deviceDict);
        NSLog(@"GetDeviceSettings : %@", resultDictionary);
        NSMutableDictionary *modelNameDict = [[NSMutableDictionary alloc]init];
        [modelNameDict setObject:@"1.2.0" forKey:@"ESR300"];
        [modelNameDict setObject:@"1.2.0" forKey:@"ESR350"];
        [modelNameDict setObject:@"1.2.0" forKey:@"ESR600"];
        [modelNameDict setObject:@"1.2.0" forKey:@"ESR900"];
        [modelNameDict setObject:@"1.2.0" forKey:@"ESR1200"];
        [modelNameDict setObject:@"1.2.0" forKey:@"ESR1750"];
        
        [self checkGetDeviceStatusAPI:[modelNameDict objectForKey:modelName]];
        NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
        [userPrefs setObject:[resultDictionary objectForKey:@"ModelName"] forKey:MODEL_NAME_KEY];
        [userPrefs setObject:[resultDictionary objectForKey:@"WlanMacAddress"] forKey:WLAN_MAC_ADDRESS_KEY];
        if (![[NSUserDefaults standardUserDefaults] stringForKey:FIRMWARE_ALERT_KEY]) {
            [userPrefs setObject:@"YES" forKey:FIRMWARE_ALERT_KEY];
        }
        [userPrefs synchronize];
        
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:FIRMWARE_ALERT_KEY] isEqualToString:@"YES"]){
            if([DataManager sharedInstance].modelType != 1)
                [self checkFirmwareVesrion];
        }
    }];
}

//判斷是否支援GetDeviceStatusAPI
- (void)checkGetDeviceStatusAPI:(NSString*)modelVersion{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getSystemInformation:^(NSDictionary *resultDictionary) {
        //    LogMessage(nil, 0, @"GetSystemInformation : %@", deviceDict);
        NSLog(@"GetSystemInformation : %@", resultDictionary);
        
        if (resultDictionary != nil) {
            
            NSString *version = [resultDictionary objectForKey:@"FirmwareVersion"];
            NSArray *versionArray = [version componentsSeparatedByString:@"."];
            
            NSArray *modelVersionArray = [modelVersion componentsSeparatedByString:@"."];
            
            NSString *GetDeviceStatusAPI = @"NO";
            if ( [versionArray[0] integerValue] < [modelVersionArray[0] integerValue] ) {
                //[self showAlert:@"LOGIN_ALERT_FIRMWARE"];
                GetDeviceStatusAPI = @"NO";
            }else if ( [versionArray[0] integerValue] == [modelVersionArray[0] integerValue] && [versionArray[1] integerValue] < [modelVersionArray[1] integerValue] ) {
                //[self showAlert:@"LOGIN_ALERT_FIRMWARE"];
                GetDeviceStatusAPI = @"NO";
            }else if ( [versionArray[0] integerValue] == [modelVersionArray[0] integerValue] &&
                      [versionArray[1] integerValue] == [modelVersionArray[1] integerValue] &&
                      [versionArray[2] integerValue] < [modelVersionArray[2] integerValue] ) {
                [self showAlert:@""];
                GetDeviceStatusAPI = @"NO";
            }else{
                GetDeviceStatusAPI = @"YES";
            }
            
            NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
            [userPrefs setObject:version forKey:FIRWARE_VERSION_KEY];
            [userPrefs setObject:GetDeviceStatusAPI forKey:GET_DEVICE_STATUS_API_KEY];
            [userPrefs synchronize];
            
        }
    }];
}

NSDictionary *FwCheckResponse;

//判斷是否符合版本要求
-(void)checkFirmwareVesrion
{
    NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
    [[StaticHttpRequest sharedInstance] checkNewFirmwareWithModel:[userPrefs objectForKey:MODEL_NAME_KEY]
                                                          Version:[[DeviceClass sharedInstance] firmwareVersion]
                                                    CompleteBlock:^(NSDictionary *resultDictionary) {
                                                        if (resultDictionary) {
                                                            if ([[DeviceClass sharedInstance] firmwareVersion]) {
                                                                [self showFirmwareAlertWithVersion:[resultDictionary objectForKey:@"version"] oldVersion:[[DeviceClass sharedInstance] firmwareVersion] firmwareId:[[resultDictionary objectForKey:@"id"] intValue]];
                                                            }else{
                                                                [self showFirmwareAlertWithVersion:[resultDictionary objectForKey:@"version"] oldVersion:[[DeviceClass sharedInstance] firmwareVersion] firmwareId:0];
                                                            }
                                                            
                                                            FwCheckResponse = resultDictionary;
                                                        }
                                                    }];
}

- (void)showAlert:(NSString*)str{
    DialogView *dialog = nil;
    VIEW(dialog, DialogView);
    dialog.delegate = self;
    
    if ([str isEqualToString:@"LOGIN_ALERT_USERNAME"] || [str isEqualToString:@"LOGIN_ALERT_HOST_EMPTY"] || [str isEqualToString:@"LOGIN_ALERT_FIRMWARE"])
    {
        dialog.okBtn.hidden = NO;
        dialog.helpBtn.hidden = YES;
    }else if ([str isEqualToString:@"LOGIN_ALERT_INTERNET"] || [str isEqualToString:@"LOGIN_ALERT_FAILED"]  || [str isEqualToString:@"LOGIN_ALERT_CONNECTING"]  ||
              [str isEqualToString:@"LOGIN_ALERT_DDNS"] )
    {
        dialog.okBtn.hidden = NO;
        dialog.helpBtn.hidden = YES;
    }
    
    if (![str isEqualToString:@"LOGIN_ALERT_FIRMWARE"]) {
        dialog.titleNameLbl.text = _(@"Oops!");
    }
    
    dialog.titleLbl.text = NSLocalizedString(str, nil);
    
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

-(void)showFirmwareAlertWithVersion:(NSString*)version oldVersion:(NSString*) oldVersion firmwareId:(int)firmwareId
{
    firmwareId = firmwareId;
    
    FirmwareDialogView *dialog = nil;
    VIEW(dialog, FirmwareDialogView);
    
    dialog.delegate = self;
    dialog.cancelBtn.hidden = NO;
    dialog.detailBtn.hidden = NO;

    if (!oldVersion) {
        [dialog changeToSingleBtn];
        //    dialog.titleNameLbl.font = [UIFont boldSystemFontOfSize:18];
        dialog.titleLbl.text = _(@"OLD_FW_UPDATE_TITLE");
        dialog.messageLbl.text = [NSString stringWithFormat:_(@"OLD_FW_UPDATE_MESSAGE"), version];
    }else{
        NSString * s = [NSString stringWithFormat:_(@"FIRMWARE_ALERT_DIALOG_INFO"), version];
        dialog.messageLbl.text = NSLocalizedString(s, nil);
        dialog.titleLbl.text = [NSString stringWithFormat:_(@"FIRMWARE_ALERT_DIALOG_TITLE"),version];
    }
    
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

-(void)showFirmwareDetail
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    firmwareViewController* FWViewController = [[firmwareViewController alloc] initWithUpgradeResponse:FwCheckResponse device:[DeviceClass sharedInstance]];
    [self presentViewController:FWViewController animated:YES completion:nil];
}


- (void)keepAlive{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    [global checkAlive:^(NSDictionary *resultDictionary) {
        NSLog(@"keepAlive : %@", resultDictionary);
    }];
}

-(void)doLoginWithUID:(NSString *)uid WithLocalIP:(NSString *)ipAddress loginDelegate:(id<deviceClassDelegate>)loginDelegate{
    NSLog(@"doLoginWithIP : uid=%@ ipAddress=%@", uid, ipAddress);
    
    if (keepAliveTimer) {
        [keepAliveTimer invalidate];
        keepAliveTimer = nil;
    }
    
    [[StaticHttpRequest sharedInstance] destroySharedInstance];
    
    delegate = loginDelegate;
    if(uid==nil && ipAddress==nil){
        if(!selectRemoteBtn.selected){
            [self doLoginLocal];
        }else{
            [self doRemoteLoginWithUID:hostLbl.text withDDNS:hostLbl.text];
        }
    }else if(!selectRemoteBtn.selected){
        [self selectDDNSClk:nil];
        [self doRemoteLoginWithUID:ipAddress withDDNS:ipAddress];
    }else{
        [self selectUIDClk:nil];
        [self doRemoteLoginWithUID:uid withDDNS:ipAddress];
    }
}

@end
