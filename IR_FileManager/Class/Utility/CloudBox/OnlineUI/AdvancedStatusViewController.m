//
//  AdvancedStatusViewController.m
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "AdvancedStatusViewController.h"
#import "RouterGlobal.h"
#import "AboutViewController.h"
#import "KGModal.h"
#import "LoadingView.h"
#import "AutoUpload.h"
#import "AutoUploadFolderNameView.h"
#import "SuccessView.h"
#import "dataDefine.h"
#import "DeviceClass.h"
#import "FirmwareSwitchDialogView.h"
#import "AppDelegate.h"
#import "UIColor+Helper.h"
#ifdef enshare
#import "SenaoGA.h"
#endif
#import "UIImageView+WebCache.h"
#import "FGalleryPhoto.h"
#import "Masonry.h"

@interface AdvancedStatusViewController () {
    CustomDataPicker* dataPickerController;
    
    NSMutableArray *tableArray;
    UIAlertView *alertView;
    
    UISwitch *autoUploadSwitch, *wifiSwitch, *firmwareAlertSwitch;
    UILabel *folderNameLbl;
    UIButton *editfolderNameBtn,*configBtn, *cleanBtn, *QRBtn;
    
    NSString *cacheSize;
    UIButton *changeLanguageBtn;
    UILabel  *currentLanguageLbl;
    UIView* dataPickerView;
    
    NSString* currentShowLanguage, * currentChangeLanguage;
}

@end

@implementation AdvancedStatusViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef MESSHUDrive
    self.titleLabel.textColor = [UIColor whiteColor];
#endif
    
    [UIView setAnimationsEnabled:YES];
    
    self.titleBackgroundView.backgroundColor = self.navigationController.navigationBar.barTintColor;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    self.navigationItem.hidesBackButton = YES;
    UIView* leftview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage* backImage = [UIImage imageNamed:@"router_cut-27.png"];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:backImage forState:UIControlStateNormal];
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect backButtonFrame = backButton.frame;
    backButtonFrame.origin.x = 0;
    backButtonFrame.origin.y = 5;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    self.titleLabel.text = _(@"Advanced Settings");
    
    tableArray = [[NSMutableArray alloc]initWithObjects:_(@"Configuration Backup"),_(@"Clean Cache")/*,_(@"QR_BUTTON")*/,nil];
    
    autoUploadSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(248, 8, 0, 0)];
    autoUploadSwitch.tintColor = [UIColor grayColor];
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_KEY] isEqualToString:@"YES"]) {
        [autoUploadSwitch setOn:YES];
    }else{
        [autoUploadSwitch setOn:NO];
    }
    
    folderNameLbl = [[UILabel alloc]initWithFrame:CGRectMake(120, 7, 130, 30)];
    editfolderNameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    wifiSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(248, 4, 0, 0)];
    wifiSwitch.tintColor = [UIColor grayColor];
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"YES"]) {
        [wifiSwitch setOn:YES];
    }else if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"NO"]) {
        [wifiSwitch setOn:NO];
    }else{
        [wifiSwitch setOn:YES];
    }
    
    firmwareAlertSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(248, 8, 0, 0)];
    firmwareAlertSwitch.tintColor = [UIColor grayColor];
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:FIRMWARE_ALERT_KEY] isEqualToString:@"YES"]) {
        [firmwareAlertSwitch setOn:YES];
    }else{
        [firmwareAlertSwitch setOn:NO];
    }
    
    currentLanguageLbl = [[UILabel alloc]initWithFrame:CGRectMake(15, 8, 120, 30)];
    if([[NSUserDefaults standardUserDefaults] stringForKey:CHANGE_LANGUAGE_KEY]){
        currentShowLanguage = [[NSUserDefaults standardUserDefaults] stringForKey:CHANGE_LANGUAGE_KEY];
        currentLanguageLbl.text = currentShowLanguage;
    }else{
        currentShowLanguage = _(@"LANGUAGE_AUTO");
        currentLanguageLbl.text = currentShowLanguage;
    }
    currentLanguageLbl.textColor = [UIColor colorWithRed:159.f/255.f green:160.f/255.f blue:160.f/255.f alpha:1];
    [currentLanguageLbl setFont:[UIFont fontWithName:@"Arial" size:13]];
    
    dataPickerView = [UIView new];
    [self.view addSubview:dataPickerView];
    [dataPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.mas_bottomLayoutGuide).mas_offset(210);
        make.height.mas_equalTo(210);
    }];
    dataPickerView.hidden = YES;
    
    [self setDataPickerController];
    
    configBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cleanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    QRBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self getCacheSize];
    
    [DataManager sharedInstance].uiViewController = self.navigationController;
    
    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)dealloc {
    tableArray = nil;
}

- (void)backBtnDidClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getCacheSize {
    NSString *tPath=[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/"];
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:tPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[tPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    fileSize += [[SDImageCache sharedImageCache] getSize];
    fileSize += [FGalleryPhoto getCacheSize];
    
    if (fileSize > 1024) {
        fileSize = fileSize / 1024;
        if (fileSize > 1024) {
            fileSize = fileSize / 1024;
            cacheSize = [NSString stringWithFormat:@"%llu MB",fileSize];
        }else{
            cacheSize = [NSString stringWithFormat:@"%llu KB",fileSize];
        }
    }else{
        cacheSize = [NSString stringWithFormat:@"%llu bytes",fileSize];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#ifndef smalink
    return 5;
#endif
    
#ifdef smalink
    return 4;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (autoUploadSwitch.isOn) {
            return 2;
        }else{
            return 0;
        }
    }else if (section == 2 || section == 3 || section == 4) {
        return 1;
    }else{
        return 0;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *titleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    
    if (section == 0) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        label.text = [NSString stringWithFormat:_(@"Camera_Upload")];
        [titleView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(15);
            make.centerY.equalTo(label.superview);
        }];
        [autoUploadSwitch addTarget:self action:@selector(openAutoUpload) forControlEvents:UIControlEventValueChanged];
        [titleView addSubview:autoUploadSwitch];
        [autoUploadSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-20);
            make.left.equalTo(label.mas_right).mas_offset(15);
            make.centerY.equalTo(label.superview);
        }];
    }else if (section == 1) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        label.text = [NSString stringWithFormat:_(@"FIRMWARE_ALERT_SWITCH_TITLE")];
        [titleView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(15);
            make.centerY.equalTo(label.superview);
        }];
        [firmwareAlertSwitch addTarget:self action:@selector(openFirmwareSwitchAlert) forControlEvents:UIControlEventValueChanged];
        [titleView addSubview:firmwareAlertSwitch];
        [firmwareAlertSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-20);
            make.left.equalTo(label.mas_right).mas_offset(15);
            make.centerY.equalTo(label.superview);
        }];
        if([DataManager sharedInstance].modelType == 1){
            titleView.alpha = 0.5f;
            firmwareAlertSwitch.enabled = NO;
        }
    }else if (section == 2) {
        
    }else if (section == 3){
        
    }else if (section == 4) {
        
    }
    
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor colorWithRGB:0xE5E5E5];
    [titleView addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(view.superview);
        make.height.mas_equalTo(1);
    }];
    
    return titleView;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 2 || section == 3 || section == 4)
        return 0.1f;
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [NSString stringWithFormat:@"%ld_%d",(long)indexPath.section,indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if([DataManager sharedInstance].modelType == 1){
        cell.userInteractionEnabled = YES;
        cell.contentView.alpha = 1.0f;
    }
    
    if (indexPath.section == 0) {
        
        if (indexPath.row==0) {
            cell.textLabel.text = _(@"Folder_Name");
            folderNameLbl.textAlignment = NSTextAlignmentRight;
            folderNameLbl.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
            folderNameLbl.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
            folderNameLbl.text = [[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY];
            
#ifdef MESSHUDrive
            [editfolderNameBtn setBackgroundImage:[UIImage imageNamed:@"router_cut-32.png"] forState:UIControlStateNormal];
            [editfolderNameBtn setTitle:_(@"Edit") forState:UIControlStateNormal];
#else
            [editfolderNameBtn setImage:[UIImage imageNamed:_(@"c_btn_edit")] forState:UIControlStateNormal];
#endif
            
            [editfolderNameBtn addTarget:self action:@selector(showAddfolderName) forControlEvents:UIControlEventTouchUpInside];
            
            [cell addSubview:editfolderNameBtn];
            [cell addSubview:folderNameLbl];
            [editfolderNameBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.mas_equalTo(-20);
                make.left.equalTo(folderNameLbl.mas_right).mas_offset(10);
                make.height.mas_equalTo(32);
                make.width.mas_equalTo(51);
                make.centerY.equalTo(editfolderNameBtn.superview);
            }];
            [folderNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(folderNameLbl.superview);
            }];
        }else if (indexPath.row==1) {
            cell.textLabel.text = _(@"WiFi_Only");
            [wifiSwitch addTarget:self action:@selector(checkWifiOnly) forControlEvents:UIControlEventValueChanged];
            [cell addSubview:wifiSwitch];
            [wifiSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.mas_equalTo(-20);
                make.centerY.equalTo(wifiSwitch.superview);
            }];
        }
        
    }else if (indexPath.section == 2) {
        
        if (indexPath.row==0) {
            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 7, 200, 30)];
            label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
            label.text = _(@"Backup_Configuration");
            [configBtn setFrame:CGRectMake(230, 7, 74, 30)];
            [configBtn setBackgroundImage:[UIImage imageNamed:@"router_cut-32.png"] forState:UIControlStateNormal];
            [configBtn setTitle:_(@"Active") forState:UIControlStateNormal];
            [configBtn setTitleColor:[UIColor colorWithRGB:0x00b4f5] forState:UIControlStateNormal];
            [configBtn addTarget:self action:@selector(doBackup) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:configBtn];
            [cell addSubview:label];
            [cell addSubview:configBtn];
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(15);
                make.centerY.equalTo(label.superview);
            }];
            [configBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(74);
                make.height.mas_equalTo(30);
                make.right.mas_equalTo(-20);
                make.centerY.equalTo(configBtn.superview);
            }];
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            if([DataManager sharedInstance].modelType == 1){
                cell.contentView.alpha = 0.5f;
                label.alpha = 0.5f;
                configBtn.alpha = 0.5f;
                cell.userInteractionEnabled = NO;
            }
        }
    }else  if (indexPath.section == 3){
        if (indexPath.row==0) {
            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 7, 135, 30)];
            [cell addSubview:label];
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(15);
                make.centerY.equalTo(label.superview);
            }];
            
            label.text = _(@"Clean_Cache");
            [cleanBtn setFrame:CGRectMake(230, 5, 74, 30)];
            [cleanBtn setBackgroundImage:[UIImage imageNamed:@"router_cut-32.png"] forState:UIControlStateNormal];
            [cleanBtn setTitle:_(@"Active") forState:UIControlStateNormal];
            [cleanBtn setTitleColor:[UIColor colorWithRGB:0x00b4f5] forState:UIControlStateNormal];
            [cleanBtn addTarget:self action:@selector(doCleanCache) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:cleanBtn];
            [cleanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(74);
                make.height.mas_equalTo(30);
                make.right.mas_equalTo(-20);
                make.centerY.equalTo(cleanBtn.superview);
            }];
            
            UILabel *detailTextLabel = [[UILabel alloc]initWithFrame:CGRectMake(165, 7, 100, 30)];
            detailTextLabel.text = cacheSize;
            detailTextLabel.textColor = [UIColor colorWithRed:159.f/255.f green:160.f/255.f blue:160.f/255.f alpha:1];
            [detailTextLabel setFont:[UIFont fontWithName:@"Arial" size:13]];
            [cell addSubview:detailTextLabel];
            [detailTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(label.mas_right).offset(20);
                make.right.mas_equalTo(-110);
                make.centerY.equalTo(detailTextLabel.superview);
            }];
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }else  if (indexPath.section == 4){
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 7, 150, 30)];
        [cell addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(15);
            make.centerY.equalTo(label.superview);
        }];
        
        label.text = _(@"CHANGE_LANGUAGE");
        
        UILabel *detailTextLabel = [[UILabel alloc]initWithFrame:CGRectMake(165, 7, 100, 30)];
        detailTextLabel.text = currentLanguageLbl.text;
        detailTextLabel.textColor = [UIColor colorWithRed:159.f/255.f green:160.f/255.f blue:160.f/255.f alpha:1];
        [detailTextLabel setFont:[UIFont fontWithName:@"Arial" size:13]];
        [cell addSubview:detailTextLabel];
        [detailTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-110);
            make.centerY.equalTo(detailTextLabel.superview);
        }];
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor colorWithRGB:0xE5E5E5];
    [cell addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(view.superview);
        make.height.mas_equalTo(1);
    }];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section==2){
        if (indexPath.row==0) {
            [self doBackup];
        }
    } else if (indexPath.section==3){
        if (indexPath.row==0) {
            [self doCleanCache];
        }
    } else if (indexPath.section==4) {
        if (indexPath.row==0) {
            [self changeLanguage:nil];
        }
    }
}

//開關auto upload功能
- (void)openAutoUpload {
    if (autoUploadSwitch.isOn) {
        [self.tableView reloadData];
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"YES" forKey:AUTO_UPLOAD_KEY];
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"YES"]) {
            [userDefault setObject:@"YES" forKey:@"wifiOnly"];
        }else if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"NO"]) {
            [userDefault setObject:@"NO" forKey:WIFI_ONLY_KEY];
        }else{
            [userDefault setObject:@"YES" forKey:WIFI_ONLY_KEY];
        }
        [userDefault synchronize];
        
        if ([[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY] == nil) {
            [self showAddfolderName];
        }else{
            //[[AutoUpload sharedInstance] doUpload:[[NSUserDefaults standardUserDefaults] stringForKey:@"autoUploadFolderName"]];
        }
    }else{
        [[AutoUpload sharedInstance] cancelUpload];
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"NO" forKey:AUTO_UPLOAD_KEY];
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"YES"]) {
            [userDefault setObject:@"YES" forKey:WIFI_ONLY_KEY];
        }else if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"NO"]) {
            [userDefault setObject:@"NO" forKey:WIFI_ONLY_KEY];
        }else{
            [userDefault setObject:@"YES" forKey:WIFI_ONLY_KEY];
        }
        [userDefault synchronize];
    }
    
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *cell1 = [self.tableView cellForRowAtIndexPath:indexPath1];
    NSIndexPath *indexPath2 = [NSIndexPath indexPathForRow:1 inSection:0];
    UITableViewCell *cell2 = [self.tableView cellForRowAtIndexPath:indexPath2];
    
    if (autoUploadSwitch.isOn) {
        cell1.frame = CGRectMake(0, 0, cell1.frame.size.width, cell1.frame.size.height);
        cell1.alpha = 0;
        cell2.frame = CGRectMake(0, 0, cell1.frame.size.width, cell1.frame.size.height);
        cell2.alpha = 0;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            cell1.frame = CGRectMake(0, 44, cell1.frame.size.width, cell1.frame.size.height);
            cell1.alpha = 1;
        } completion:^(BOOL d){
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                cell2.frame = CGRectMake(0, 84, cell2.frame.size.width, cell2.frame.size.height);
                cell2.alpha = 1;
            } completion:^(BOOL d){
            }];
        }];
    }else{
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            cell2.frame = CGRectMake(0, 0, cell2.frame.size.width, cell2.frame.size.height);
            cell2.alpha = 0;
        } completion:^(BOOL d){
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                cell1.frame = CGRectMake(0, 0, cell1.frame.size.width, cell1.frame.size.height);
                cell1.alpha = 0;
            } completion:^(BOOL d){
                [self.tableView reloadData];
            }];
        }];
    }
}

- (void)showAddfolderName {
    //正在上傳中
    if ([[DataManager sharedInstance] autoUploadLeft] > 0) {
        [self showWarnning:_(@"AUTO_UPLOAD_DO_EDIT")];
        return;
    }
    
    AutoUploadFolderNameView *autoUploadFolderNameView;
    VIEW(autoUploadFolderNameView, AutoUploadFolderNameView);
    autoUploadFolderNameView.delegate = self;
    autoUploadFolderNameView.folderNameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY];
    [[KGModal sharedInstance] setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:autoUploadFolderNameView andAnimated:YES];
}

//是否有連上wifi才上傳album
- (void)checkWifiOnly {
    NSString *tag = [[StaticHttpRequest sharedInstance] detect3GWifi];
    if (wifiSwitch.isOn) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"YES" forKey:WIFI_ONLY_KEY];
        [userDefault synchronize];
        
        if ([tag isEqualToString:@"3G"]) {//等待wifi
            
        }else if ([tag isEqualToString:@"WIFI"]) {//可以傳
            
        }else{//沒有網路
            
        }
    }else{
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"NO" forKey:WIFI_ONLY_KEY];
        [userDefault synchronize];
        
        if ([tag isEqualToString:@"3G"]) {//可以傳
            
        }else if ([tag isEqualToString:@"WIFI"]) {//可以傳
            
        }else{//沒有網路
            
        }
    }
}

- (void)doAutoUpload:(NSString*)folder {
    NSLog(@"%@", folder);
    
    if ([[folder stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""] ) { //為空白
        [self cancelClk];
        [self showWarnning:_(@"AUTO_UPLOAD_ALERT_EMPTY")];
    }else if ( [[DataManager sharedInstance] checkFileName:folder] ) { //含有特殊字元
        [self cancelClk];
        [self showWarnning:_(@"AUTO_UPLOAD_ALERT_ERROR")];
    }else if ( folder.length>128 ) { //長度太長
        [self cancelClk];
        [self showWarnning:_(@"RENAME_ALERT_LENGTH")];
    }else{
        
        [[KGModal sharedInstance] hideAnimated:YES];
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:folder forKey:AUTO_UPLOAD_FOLDER_NAME_KEY];
        [userDefault synchronize];
        
        [self.tableView reloadData];
    }
}

- (void)cancelClk {
    [autoUploadSwitch setOn:NO];
    [self openAutoUpload];
}

- (void)showWarnning:(NSString*)info {
    SuccessView *successView;
    VIEW(successView, SuccessView);
    successView.delegate = self;
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

- (void)doBackup {
    LoadingView *loadingView;;
    VIEW(loadingView, LoadingView);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:loadingView andAnimated:YES];
    
    [self performSelectorInBackground:@selector(backgroundDoBackup) withObject:nil];
}

- (void)backgroundDoBackup {
    RouterGlobal *global = [[RouterGlobal alloc]init];
    [global downloadDeviceConfigFile:^(NSDictionary *resultDictionary) {
        NSLog(@"%@",resultDictionary);
        
        if ([resultDictionary objectForKey:@"ConfigFilePath"]) {
            NSString *configFilePath = [resultDictionary objectForKey:@"ConfigFilePath"];
            NSString *modelName = [[NSUserDefaults standardUserDefaults] stringForKey:MODEL_NAME_KEY];
            
            if([modelName isEqualToString:@"EMR3000"]||[modelName isEqualToString:@"EMR3500"]||[modelName isEqualToString:@"EMR5000"]){
                NSMutableArray * urlComponents = [NSMutableArray arrayWithArray:[configFilePath pathComponents]];
                [urlComponents removeObjectAtIndex:1]; //remove "www"
                configFilePath = [NSString pathWithComponents:urlComponents];
            }
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", [[DeviceClass sharedInstance] getDownloadUrl], configFilePath]];
            
            NSLog(@"%@",url);
            
            NSData *dbFile = [[NSData alloc] initWithContentsOfURL:url];
            NSLog(@"FILE: %@",dbFile);
            if (dbFile == nil) {
                for (int i=0; i < [DataManager sharedInstance].retryCount; i++) {
                    dbFile = [[NSData alloc] initWithContentsOfURL:url];
                    NSLog(@"(%d)FILE: %@",i,dbFile);
                    if (dbFile != nil) {
                        break;
                    }
                    
                }
                if (dbFile == nil) {
                    [self showWarnning:_(@"Operation_Failed")];
                    return;
                }
            }
            
            NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"tmp"]];
            NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[resultDictionary objectForKey:@"ConfigFilePath"]];
            [dbFile writeToFile:filePath atomically:YES];
            
            [self getCacheSize];
            [self.tableView reloadData];
            
            
            if ([MFMailComposeViewController canSendMail]) {
                [[KGModal sharedInstance] hideAnimated:YES];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                NSDate *date = [NSDate date];
                [formatter setDateFormat:@"YYYY/MM/dd'"];
                NSString *today = [formatter stringFromDate:date];
                today = [today stringByReplacingOccurrencesOfString:@"/0" withString:@"/"];
                
                NSString *modelName = [[NSUserDefaults standardUserDefaults] stringForKey:MODEL_NAME_KEY];
                NSString *version = [[NSUserDefaults standardUserDefaults] stringForKey:FIRWARE_VERSION_KEY];
                
                NSData *binData = [NSData dataWithContentsOfFile:filePath];
                MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
                controller.mailComposeDelegate = self;
                [controller setSubject: [NSString stringWithFormat:_(@"%@ Configuration Backup - %@"), modelName, today] ];
                [controller setMessageBody: [NSString stringWithFormat:_(@"Router Model: %@<br>Firmware Version: %@<br>"), modelName, version] isHTML:YES];
                [controller addAttachmentData:binData mimeType:@"application/octet-stream" fileName:@"config.dlf"];
                [self presentViewController:controller animated:YES completion:nil];
            }else{
                NSLog(@"no mail");
                SuccessView *successView;;
                VIEW(successView, SuccessView);
                successView.infoLabel.text = NSLocalizedString(@"BACKUP_ALERT", nil);
                [[KGModal sharedInstance] setShowCloseButton:FALSE];
                [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
            }
            
        }else{//訊息錯誤時，回到登入頁
            [self backToLoginPage];
        }
    }];
}

- (void)doCleanCache {
    NSString *tPath=[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/"];
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:tPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    
    while (fileName = [filesEnumerator nextObject]) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",tPath,fileName] error:nil];
    }
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
    
    [FGalleryPhoto resetImageCache];
    
    [self getCacheSize];
    [self.tableView reloadData];
}

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultFailed:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultSaved:
            break;
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openFirmwareSwitchAlert {
    if (firmwareAlertSwitch.isOn) {
        [self.tableView reloadData];
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"YES" forKey:FIRMWARE_ALERT_KEY];
        [userDefault synchronize];
        
    }else{
        [self showFirmwareSwitchAlertDialog];
    }
}

- (void)showFirmwareSwitchAlertDialog {
    
    FirmwareSwitchDialogView *firmwareSwitchDialogView;
    VIEW(firmwareSwitchDialogView, FirmwareSwitchDialogView);
    firmwareSwitchDialogView.delegate = self;
    firmwareSwitchDialogView.titleLbl.text = NSLocalizedString(@"FIRMWARE_ALERT_NOTIFICATION_DIALOG_TITLE", nil);
    firmwareSwitchDialogView.messageLbl.text = NSLocalizedString(@"FIRMWARE_ALERT_NOTIFICATION_DIALOG_INFO", nil);
    
    [[KGModal sharedInstance] setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:firmwareSwitchDialogView andAnimated:YES];
}

- (void)turnOffFirmwareSwitchAlert {
    
    [[KGModal sharedInstance] hideAnimated:YES];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"NO" forKey:FIRMWARE_ALERT_KEY];
    
    [userDefault synchronize];
    
}

- (void)cancelTurnOffFirmwareSwitchAlert {
    [firmwareAlertSwitch setOn:YES];
    [self openFirmwareSwitchAlert];
    
}

- (void)changeLanguage:(id)sender {
    if (dataPickerView.hidden) {
        [dataPickerController setCurrentLanguage:currentShowLanguage caller:currentShowLanguage];
        [self.view bringSubviewToFront:dataPickerView];
        [self setDataPickerHide:NO];
    }
}

- (void)setDataPickerController {
    if (dataPickerView) {
        [dataPickerController.view removeFromSuperview];
        dataPickerController = nil;
    }
    
    dataPickerController = [[CustomDataPicker alloc] init];
    [dataPickerView addSubview:dataPickerController.view];
    [dataPickerController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(dataPickerView);
    }];
    dataPickerController.delegate = self;
}

- (void)backToLoginPage {
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark CustomDataPickerDelegate
-(void) didDataPickerCancel {
    [self setDataPickerHide:YES];
}

-(void)didDataPickerDoneWithLanguage:(NSString *)Language caller:(id)caller {
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"RouterPage_Advanced Settings" Label:nil Value:nil];
#endif
    if (![Language isEqualToString:currentShowLanguage]) {
        currentChangeLanguage = [[NSString alloc] initWithString:Language];
        
        NSString * titleString = nil;
        if ([currentChangeLanguage isEqualToString:NSLocalizedString(@"LANGUAGE_EN", nil)])
        {
            titleString = _(@"ShowChangeToEnglishLanguageChangelertMessageTitle");
        }else if ([currentChangeLanguage isEqualToString:NSLocalizedString(@"LANGUAGE_TC", nil)])
        {
            titleString = _(@"ShowChangeToTCLanguageChangelertMessageTitle");
        }
        else if ([currentChangeLanguage isEqualToString:NSLocalizedString(@"LANGUAGE_SC", nil)])
        {
            titleString = _(@"ShowChangeToSCLanguageChangelertMessageTitle");
        }else{
            titleString = _(@"ShowChangeToAutoLanguageChangelertMessageTitle");
        }
        
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@" ,titleString]
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"NO"
                                              otherButtonTitles:@"YES", nil];
        [alert show];
    }
    [self setDataPickerHide:YES];
    
}

-(void)setDataPickerHide:(BOOL)_blnHide {
    if (!_blnHide) {
        dataPickerView.hidden = _blnHide;
    }
    
    [dataPickerView mas_updateConstraints:^(MASConstraintMaker *make) {
        if (_blnHide) {
            make.bottom.equalTo(self.mas_bottomLayoutGuide).mas_offset(210);
        }else{
            make.bottom.equalTo(self.mas_bottomLayoutGuide);
        }
    }];
    
    [dataPickerView setNeedsUpdateConstraints];
    
    if (_blnHide) {
        [UIView beginAnimations:@"bucketsOff" context:nil];
    }else{
        [UIView beginAnimations:@"bucketsOn" context:nil];
    }
    
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(myAnimationStopped:finished:context:)];
    
    [dataPickerView.superview layoutIfNeeded];
    [UIView commitAnimations];
}

-(void)myAnimationStopped:(NSString *)animationID
                 finished:(NSNumber *)finished
                  context:(void *)context {
    if ([animationID isEqualToString:@"bucketsOff"]) {
        dataPickerView.hidden = YES;
    }else{ //on
        dataPickerView.hidden = NO;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (currentChangeLanguage && buttonIndex==1) {
        
        NSString* languageId = nil;
        
        if ([currentChangeLanguage isEqualToString:NSLocalizedString(@"LANGUAGE_EN", nil)])
        {
            languageId = @"en";
        }
        if ([currentChangeLanguage isEqualToString:NSLocalizedString(@"LANGUAGE_TC", nil)])
        {
            languageId = @"zh-Hant";
        }
        if ([currentChangeLanguage isEqualToString:NSLocalizedString(@"LANGUAGE_SC", nil)])
        {
            languageId = @"zh-Hans";
        }
        
        currentShowLanguage = currentChangeLanguage;
        
        if(!languageId){
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:SYSTEM_LANGUAGES_KEY];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:CHANGE_LANGUAGE_KEY];
        }else{
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObject:languageId] forKey:SYSTEM_LANGUAGES_KEY];
            [[NSUserDefaults standardUserDefaults] setObject:currentShowLanguage forKey:CHANGE_LANGUAGE_KEY];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize]; //to make the change immediate
        
        currentLanguageLbl.text = currentShowLanguage;
        [self.tableView reloadData];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@" ,_(@"LanguageChangedAlertTitle")]
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"YES"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

@end
