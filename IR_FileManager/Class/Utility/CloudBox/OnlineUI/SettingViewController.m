//
//  SettingViewController.m
//  EnShare
//
//  Created by Phil on 2016/12/2.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "SettingViewController.h"
#import "WirelessSettingViewController.h"
#import "ClientManagerViewController.h"
#import "AdvancedStatusViewController.h"
#import "DeviceClass.h"
#import "UIColor+Helper.h"
#import "ColorDefine.h"
#import "KGModal.h"
#import "SenaoGA.h"
#import "RouterGlobal.h"
#import "dataDefine.h"
#import "FirmwareDialogView.h"
#import "firmwareViewController.h"
#import "CommonTools.h"
#import "SettingTableViewCell.h"
#import "AppDelegate.h"

@interface SettingViewController ()<UITableViewDelegate, UITableViewDataSource>{
    UIView *footerView;
    UIButton *logoutBtn;
    NSDictionary *FwCheckResponse;
}

@property (strong, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UILabel *offLineLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(retain,nonatomic) NSMutableArray *tableArray;

@end

@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    
//    self.navigationController.textColor = [UIColor colorWithRGB:0x00b4f5];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine]];
    self.navigationItem.title = _(@"ROUTER_TITLE");
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.titleBackgroundView.backgroundColor = self.navigationController.navigationBar.barTintColor;
    CGRect frame = self.titleBackgroundView.frame;
    frame.size.height = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    self.titleBackgroundView.frame = frame;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        self.mainView.frame = CGRectMake(0, 20, self.mainView.frame.size.width, self.mainView.frame.size.height-20);
//        [self.tableView setContentInset:UIEdgeInsetsMake(-36,0,0,0)];
    } else {// iOS 6
    }
    [UIView setAnimationsEnabled:YES];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingTableViewCell" bundle:nil] forCellReuseIdentifier:@"SettingTableViewCell"];
    
    if ([DataManager sharedInstance].offline == TRUE)
    {
        self.tableView.hidden = YES;
        self.offLineLabel.hidden = NO;
        self.backBtn.hidden = NO;
    }
    else if (![[DeviceClass sharedInstance] isAdminUser])
    {
        self.tableView.hidden = YES;
        self.offLineLabel.hidden = NO;
        self.backBtn.hidden = YES;
        self.offLineLabel.text = _(@"Administrative");
    }
    else
    {
        self.tableView.hidden = NO;
        self.offLineLabel.hidden = YES;
        self.backBtn.hidden = YES;
        
        self.tableArray = [[NSMutableArray alloc]initWithObjects:_(@"Wireless Settings"),_(@"Client Manager"),_(@"Advanced Settings"), nil];
    }
    
    modelNameLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:MODEL_NAME_KEY];
    
    if ( [modelNameLabel.text isEqualToString:@"ESR300"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"ESR300_60x48"]];
    }else if ( [modelNameLabel.text isEqualToString:@"ESR350"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"ESR350_60x48"]];
    }else if ( [modelNameLabel.text isEqualToString:@"ESR600"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"ESR600_60x48"]];
    }else if ( [modelNameLabel.text isEqualToString:@"ESR900"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"ESR900_60x48"]];
    }else if ( [modelNameLabel.text isEqualToString:@"ESR1200"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"ESR1200_60x48"]];
    }else if ( [modelNameLabel.text isEqualToString:@"ESR1750"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"ESR1750_60x48"]];
    }else if ( [modelNameLabel.text isEqualToString:@"EPG600"] ) {
        [modelImageView setImage:[UIImage imageNamed:@"epg600"]];
    }else if ([modelNameLabel.text isEqualToString:@"EPG5000"]) {
        [modelImageView setImage:[UIImage imageNamed:@"EPG5000_50x40"]];
    }else if ([modelNameLabel.text isEqualToString:@"EMR3000"]) {
        [modelImageView setImage:[UIImage imageNamed:@"emr3000"]];
    }else if ([modelNameLabel.text isEqualToString:@"EMR3500"]) {
        [modelImageView setImage:[UIImage imageNamed:@"emr3000"]];
    }else if ([modelNameLabel.text isEqualToString:@"EMR5000"]) {
        [modelImageView setImage:[UIImage imageNamed:@"emr3000"]];
    }else if ([modelNameLabel.text isEqualToString:@"RT500"]) {
        [modelImageView setImage:[UIImage imageNamed:@"RT500"]];
    }
    
    publicIPTitleLabel.text = _(@"INTERNET_IP");
    localIPTitleLabel.text = _(@"INTRANET_IP");
    storageSizeTitleLabel.text = _(@"STORAGE");
    updateTitleLabel.text = _(@"SOFTWARE_UPDATE");
    [updateButton setTitle: _(@"UPDATE") forState:UIControlStateNormal];
    
    if([DataManager sharedInstance].modelType == 1)
        updateButton.hidden = YES;
    
    footerView  = [[UIView alloc] init];
    logoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [DataManager sharedInstance].uiViewController = self.navigationController;
}

- (void)viewWillAppear:(BOOL)animated{
#ifdef enshare
    [SenaoGA setScreenName:@"RouterPage"];
#endif
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self getDeviceStatus];
    });
}

- (void)dealloc{
    footerView = nil;logoutBtn = nil;
    self.offLineLabel = nil;
    self.tableView = nil;
    self.tableArray = nil;
}

- (void)viewDidAppear:(BOOL)animated{
    [self.tableView reloadData];
}

- (IBAction)updateClick:(id)sender {
    updateButton.enabled = NO;
    [loadingView startAnimating];
    loadingView.hidden = NO;
    [self checkFirmwareVesrion];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([DataManager sharedInstance].modelType == 1)
        return 60;
    else
        return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return [self.tableArray count];
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SettingTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"SettingTableViewCell" forIndexPath:indexPath];
    
    cell.titleLabel.text =  [self.tableArray objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if([DataManager sharedInstance].modelType == 1){
        cell.hintLabel.hidden = YES;
        cell.contentView.alpha = 1.0f;
        CGRect tmp = cell.seperatorLineImageView.frame;
        tmp.origin.y = 58;
        cell.seperatorLineImageView.frame = tmp;
        cell.userInteractionEnabled = YES;
        
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-33.png"] scaledToSize:CGSizeMake(30, 25)];
                cell.hintLabel.hidden = NO;
                cell.hintLabel.text = _(@"MeshRouterSettingHintTitle");
#ifdef MESSHUDrive
                [cell.hintLabel setTextColor:[UIColor redColor]];
#endif
                cell.contentView.alpha = 0.5f;
                [cell changeToTwoLine];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.userInteractionEnabled = NO;
                break;
            case 1:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-35.png"] scaledToSize:CGSizeMake(29, 25)];
                cell.hintLabel.hidden = NO;
                cell.hintLabel.text = _(@"MeshRouterSettingHintTitle");
#ifdef MESSHUDrive
                [cell.hintLabel setTextColor:[UIColor redColor]];
#endif
                cell.contentView.alpha = 0.5f;
                [cell changeToTwoLine];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.userInteractionEnabled = NO;
                break;
            case 2:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-36.png"] scaledToSize:CGSizeMake(25, 25)];
                [cell changeToOneLine];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                break;
            case 3:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-34.png"] scaledToSize:CGSizeMake(28, 25)];
                [cell changeToOneLine];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
        }
    }else{
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-33.png"] scaledToSize:CGSizeMake(30, 25)];
                break;
            case 1:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-35.png"] scaledToSize:CGSizeMake(29, 25)];
                break;
            case 2:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-36.png"] scaledToSize:CGSizeMake(25, 25)];
                break;
            case 3:
                cell.imageView.image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-34.png"] scaledToSize:CGSizeMake(28, 25)];
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
        }
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
//    if (section==1) {
//        return 51;
//    }else{
//        return 10;
//    }
    return 0;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([DataManager sharedInstance].modelType == 1){
        if(indexPath.row == 0 || indexPath.row == 1) {
            return;
        }
    }
    
#ifdef enshare
    NSString* screenName;
    if (indexPath.row == 0) {
        screenName = @"RouterPage_DeviceStatus";
    }else if (indexPath.row == 1){
        screenName = @"RouterPage_WirelessSetting";
    }else if (indexPath.row == 1){
        screenName = @"RouterPage_DeviceStatus";
    }else {
        screenName = @"RouterPage_DeviceStatus";
    }
    [SenaoGA setScreenName:screenName];
#endif
    
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            WirelessSettingViewController *view = [[WirelessSettingViewController alloc] initWithNibName:@"WirelessSettingViewController" bundle:nil];
            [self.navigationController pushViewController:view animated:YES];
            [[KGModal sharedInstance] hideAnimated:YES];
        }else if (indexPath.row==1) {
            
            ClientManagerViewController *view = [[ClientManagerViewController alloc] initWithNibName:@"ClientManagerViewController" bundle:nil];
            [self.navigationController pushViewController:view animated:YES];
            [[KGModal sharedInstance] hideAnimated:YES];
        }else if (indexPath.row==2) {
            
            AdvancedStatusViewController *view = [[AdvancedStatusViewController alloc] initWithNibName:@"AdvancedStatusViewController" bundle:nil];
            [self.navigationController pushViewController:view animated:YES];
        }else if (indexPath.row==3) {
            
        }
    }
}

-(void)backToLoginPage{
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
//    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
//    [navController dismissViewControllerAnimated:YES completion:nil];
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)getDeviceStatus{
    NSString *GetDeviceStatusAPI = [[NSUserDefaults standardUserDefaults] stringForKey:GET_DEVICE_STATUS_API_KEY];
    dispatch_async(dispatch_get_main_queue(), ^{
        [loadingView startAnimating];
        loadingView.hidden = NO;
    });
    
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    if ([GetDeviceStatusAPI isEqualToString:@"YES"]) {
        [self newAPI];
    }else{
        
        [global getWanSettings:^(NSDictionary *resultDictionary) {
            if (resultDictionary) {
                publicIPLabel.text = [resultDictionary objectForKey:@"IPAddress"];
            }
            
            [self getStorageInfoAndCheckHasNewFW:global];
        }];
        
        [global getLanSettings:^(NSDictionary *resultDictionary) {
            if (resultDictionary) {
                localIPLabel.text = [resultDictionary objectForKey:@"IPAddress"];
            }
            
            [self getStorageInfoAndCheckHasNewFW:global];
        }];
        
        [global getSystemInformation:^(NSDictionary *resultDictionary) {
            if (resultDictionary) {
                firmwareLabel.text = [resultDictionary objectForKey:@"FirmwareVersion"];
            }
        }];
    }
}

-(void) getStorageInfoAndCheckHasNewFW:(RouterGlobal*)global{
    //取得USB資訊
    [global getStorageInfo:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            
            NSDictionary* tempDict = [resultDictionary objectForKey:@"StorageInformation"];
            if ([tempDict count]==0) {
                [totalSizeLabel setFont:[UIFont systemFontOfSize:13]];
                totalSizeLabel.text = _(@"No mounted device");
            }else{
                [totalSizeLabel setFont:[UIFont systemFontOfSize:14]];
                
                for (NSDictionary *i in tempDict) {
                    if ([[i objectForKey:@"UsbPath"] isEqualToString:[DataManager sharedInstance].diskPath]) {
                        
                        NSString *leftSize = nil,*totalSize = nil;
                        
                        if ([[i objectForKey:@"UsedPrecentage"] rangeOfString:@"M"].length == 0) {
                            if ([[i objectForKey:@"UsedPrecentage"] integerValue]>1024) {
                                //leftSizeLabel.text = [NSString stringWithFormat:@"%d %@",[[i objectForKey:@"UsedPrecentage"]integerValue]/1024, _(@"used2") ];
                                leftSize = [NSString stringWithFormat:@"%d %@",[[i objectForKey:@"UsedPrecentage"]integerValue]/1024, _(@"used2") ];
                            }else{
                                //leftSizeLabel.text = [NSString stringWithFormat:@"%@ %@",[i objectForKey:@"UsedPrecentage"], _(@"used2") ];
                                leftSize = [NSString stringWithFormat:@"%@ %@",[i objectForKey:@"UsedPrecentage"], _(@"used2") ];
                            }
                        }else{
                            //leftSizeLabel.text = [i objectForKey:@"UsedPrecentage"];
                            leftSize = [i objectForKey:@"UsedPrecentage"];
                        }
                        
                        if ([[i objectForKey:@"LeftSize"] rangeOfString:@"G"].length == 0) {
                            if ([[i objectForKey:@"LeftSize"] integerValue]>1024) {
                                //totalSizeLabel.text = [NSString stringWithFormat:@"%d MB %@",[[i objectForKey:@"TotalSize"]integerValue]/1024, _(@"available") ];
                                totalSize = [NSString stringWithFormat:@"%@ MB",[self setNumberFormate:[NSNumber numberWithInt:[[i objectForKey:@"LeftSize"]integerValue]/1024]]];
                            }else{
                                //totalSizeLabel.text = [NSString stringWithFormat:@"%@ KB %@",[i objectForKey:@"TotalSize"], _(@"available") ];
                                totalSize = [NSString stringWithFormat:@"%@ KB",[self setNumberFormate:[i objectForKey:@"LeftSize"]] ];
                            }
                        }else{
                            //totalSizeLabel.text = [i objectForKey:@"TotalSize"];
                            totalSize = [self setNumberFormate:[i objectForKey:@"LeftSize"]];
                        }
                        
                        totalSizeLabel.text = totalSize;
                    }
                }
            }
            
        }else{//訊息錯誤時，回到登入頁
//            [self.navigationController popToRootViewControllerAnimated:YES];
            [self backToLoginPage];
        }
        
        if([DataManager sharedInstance].modelType != 1)
            [self checkHasNewFirmwareVesrion];
        else{
            [loadingView stopAnimating];
            loadingView.hidden = YES;
        }
        
    }];
}

//FW v1.1.0 使用GetDeviceStatus API 可取得該頁面所用到的所有值
- (void)newAPI{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getDeviceStatus:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            
            LogMessage(nil, 0, @"GetDeviceStatus : %@", resultDictionary);
            
            publicIPLabel.text = [resultDictionary objectForKey:@"WanIPAddress"];
            localIPLabel.text = [resultDictionary objectForKey:@"LanIPAddress"];
            firmwareLabel.text = [NSString stringWithFormat:@"v%@", [resultDictionary objectForKey:@"FirmwareVersion"]];
            
        }else{//訊息錯誤時，回到登入頁
//            [self.navigationController popToRootViewControllerAnimated:YES];
            [self backToLoginPage];
        }
        
        [self getStorageInfoAndCheckHasNewFW:global];
    }];
}

-(NSString*)setNumberFormate:(NSNumber*)number{
    if ([number isKindOfClass:[NSString class]]) {
        return (NSString*)number;
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setGroupingSize:3];
    [formatter setGroupingSeparator:@","];
    [formatter setUsesGroupingSeparator:YES];
    return [formatter stringFromNumber:number];
}

//判斷是否有新版本
-(void)checkHasNewFirmwareVesrion
{
    NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
    [[StaticHttpRequest sharedInstance] checkNewFirmwareWithModel:[userPrefs objectForKey:MODEL_NAME_KEY]
                                                          Version:[[DeviceClass sharedInstance] firmwareVersion]
                                                    CompleteBlock:^(NSDictionary *resultDictionary) {
                                                        if (resultDictionary) {
                                                            updateButton.enabled = YES;
                                                            updateButton.hidden = NO;
                                                            firmwareLabel.hidden = YES;
                                                        }else{
                                                            updateButton.enabled = NO;
                                                            updateButton.hidden = YES;
                                                            firmwareLabel.hidden = NO;
                                                        }
                                                        
                                                        [loadingView stopAnimating];
                                                        loadingView.hidden = YES;
                                                    }];
}

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
                                                        
                                                        updateButton.enabled = YES;
                                                        [loadingView stopAnimating];
                                                        loadingView.hidden = YES;
                                                    }];
}

-(void)showFirmwareAlertWithVersion:(NSString*)version oldVersion:(NSString*) oldVersion firmwareId:(int)firmwareId
{
    //    DialogView *dialog = nil;
    //    VIEW(dialog, DialogView);
    
    firmwareId = firmwareId;
    
    FirmwareDialogView *dialog = nil;
    VIEW(dialog, FirmwareDialogView);
    
    dialog.delegate = self;
    
    //    dialog.okBtn.hidden = NO;
    //    dialog.helpBtn.hidden = YES;
    
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
//    AppDelegate* appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //    UIViewController* tmpViewController = (UIViewController*)appdelegate.mRootView;
    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    //UINavigationController* navigationController = appdelegate.mRootView.viewControllers[appdelegate.mRootView.m_currentTag];
    
    firmwareViewController* FWViewController = [[firmwareViewController alloc] initWithUpgradeResponse:FwCheckResponse device:[DeviceClass sharedInstance]];
    //    [tmpViewController presentViewController:FWViewController animated:YES completion:nil];
    [self presentViewController:FWViewController animated:YES completion:nil];
    //[navigationController pushViewController:FWViewController animated:YES];
}

@end
