//
//  GuestManagerViewController.m
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "ClientManagerViewController.h"
#import "RouterGlobal.h"
#import "ClientManagerTableViewCell.h"
#import "RebootingViewController.h"

#import "KGModal.h"
#import "SuccessView.h"
#import "StaticHttpRequest.h"
#import "dataDefine.h"
#import "UIColor+Helper.h"
#import "Masonry.h"
#ifdef enshare
#import "SenaoGA.h"
#endif
@interface ClientManagerViewController (){
    NSMutableDictionary *listDictionary;
    NSMutableDictionary *blockListDictionary, *hideBlockListDictionary;
    NSArray *listKeys, *blockListKeys;
    
    UIView *saveView;
    UIButton *saveBtn,*cancelBtn;
    
//    int timerCount;
//    NSTimer *autoTimer;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ClientManagerViewController

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
    
#ifdef MESSHUDrive
    self.titleLabel.textColor = [UIColor whiteColor];
#endif
    
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
//    [backButton setTitle:_(@"Back") forState:UIControlStateNormal];
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    [UIView setAnimationsEnabled:YES];
    
    self.titleLabel.text = _(@"Client Manager");
    self.loadingView.hidden = NO;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ClientManagerTableViewCell" bundle:nil] forCellReuseIdentifier:@"ClientManagerTableViewCell"];
    
    saveView  = [[UIView alloc] init];
    saveView.backgroundColor = [UIColor whiteColor];
    saveView.hidden = YES;
    saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //[saveView setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 44 - 60, 320, 60)];
    saveView.backgroundColor = [UIColor whiteColor];
//    [saveBtn setFrame:CGRectMake(200, 13, 100, 33)];
    [saveBtn setTitle:_(@"SAVE") forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor colorWithRGB:0x007aff] forState:UIControlStateNormal];
//    [saveBtn.titleLabel setTextAlignment:NSTextAlignmentRight];
//    saveBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
//    [saveBtn setImage:[UIImage imageNamed:_(@"rbtn_savenreboot")] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveBlocked) forControlEvents:UIControlEventTouchUpInside];
//    [cancelBtn setFrame:CGRectMake(20, 13, 100, 33)];
    [cancelBtn setTitle:_(@"Cancel") forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor colorWithRGB:0x35424b] forState:UIControlStateNormal];
//    [cancelBtn.titleLabel setTextAlignment:NSTextAlignmentLeft];
//    cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
//    [cancelBtn setImage:[UIImage imageNamed:_(@"rbtn_cancel")] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelBlocked) forControlEvents:UIControlEventTouchUpInside];
//    UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    UIImageView *line = [UIImageView new];
    [line setBackgroundColor:[UIColor colorWithRGB:0xE5E5E5]];
    [saveView addSubview:saveBtn];
    [saveView addSubview:cancelBtn];
    [saveView addSubview:line];
    [self.view addSubview:saveView];
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(saveView).mas_offset(-20);
        make.leading.equalTo(saveView.mas_centerX);
        make.top.bottom.equalTo(saveView);
    }];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(saveView).mas_offset(20);
        make.trailing.equalTo(saveView.mas_centerX);
        make.top.bottom.equalTo(saveView);
    }];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.leading.trailing.top.equalTo(saveView);
    }];
    [saveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_bottomLayoutGuide);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(60);
    }];
    
    [DataManager sharedInstance].uiViewController = self.navigationController;
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)viewDidAppear:(BOOL)animated{
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
//        [self.navigationController popToRootViewControllerAnimated:YES];
        [self backToLoginPage];
        return;
    }
    [self performSelectorInBackground:@selector(getTableData) withObject:nil];
}

- (void)backBtnDidClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getTableData{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    listDictionary = [NSMutableDictionary dictionary];
    blockListDictionary = [NSMutableDictionary dictionary];
    hideBlockListDictionary = [NSMutableDictionary dictionary];
    
    
    [global getClientStatus:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            
            //LogMessage(nil, 0, @"GetClientStatus : %@", clientDict);
            NSLog(@"GetClientStatus : %@", resultDictionary);
            NSDictionary* clientDict = [resultDictionary objectForKey:@"ClientStatuses"];
            
            for (NSDictionary *i in clientDict) {
                [listDictionary setObject:i forKey:[i objectForKey:@"MacAddress"]];
            }
            
            [self setBlockedList];
        }else{
            //self.loadingView.hidden = YES;
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

-(void)setBlockedList{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    [global getBlockedClientList:^(NSDictionary *resultDictionary) {
        //LogMessage(nil, 0, @"GetBlockedClientList : %@", blockedClientDict);
        NSLog(@"GetBlockedClientList : %@", resultDictionary);
        if ([[resultDictionary objectForKey:@"Enabled"] boolValue]) {
            NSDictionary* blockedClientDict = [resultDictionary objectForKey:@"BlockedClientList"];
            for (NSDictionary *i in blockedClientDict) {
                [blockListDictionary setObject:i forKey:[i objectForKey:@"MacAddress"]];
                [listDictionary removeObjectForKey:[i objectForKey:@"MacAddress"]];
            }
        }else{
            NSDictionary* blockedClientDict = [resultDictionary objectForKey:@"BlockedClientList"];
            for (NSDictionary *i in blockedClientDict) {
                [hideBlockListDictionary setObject:i forKey:[i objectForKey:@"MacAddress"]];
            }
        }
        
        listKeys = [listDictionary allKeys];
        blockListKeys = [blockListDictionary allKeys];
        
        self.loadingView.hidden = YES;
        [self.tableView reloadData];
    }];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return [listDictionary count];
            break;
        case 1:
            return [blockListDictionary count];
            break;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier = @"ClientManagerTableViewCell";
    ClientManagerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    
    cell.statusTitleLabel.text = _(@"STATUS");
    
        if (indexPath.section == 0) {
            NSString* tHostName;
            if ([[listDictionary objectForKey:listKeys[indexPath.row]] objectForKey:@"DeviceName"]) {
                tHostName = [[listDictionary objectForKey:listKeys[indexPath.row]] objectForKey:@"DeviceName"];
//                cell.detailTextLabel.text = listKeys[indexPath.row];
                cell.macInfoLabel.text = listKeys[indexPath.row];
            }
            if ([[listDictionary objectForKey:listKeys[indexPath.row]] objectForKey:@"Hostname"]) {
                tHostName = [[listDictionary objectForKey:listKeys[indexPath.row]] objectForKey:@"Hostname"];
//                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@    %@",[[listDictionary objectForKey:listKeys[indexPath.row]] objectForKey:@"IPAddress"],listKeys[indexPath.row]];
                cell.ipInfoLabel.text = [[listDictionary objectForKey:listKeys[indexPath.row]] objectForKey:@"IPAddress"];
                cell.macInfoLabel.text = listKeys[indexPath.row];
            }
            if (tHostName.length > 20) {
                tHostName =  [tHostName substringWithRange:NSMakeRange(0, 20)];
                tHostName = [NSString stringWithFormat:@"%@...",tHostName];
            }
            cell.titleLabel.text = tHostName;
//            [cell.detailTextLabel setFont:[UIFont fontWithName:@"Arial" size:13]];
//            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            
//            [button setFrame:CGRectMake(230, 5, 73, 26)];
            [cell.blockButton setTitle:_(@"Disconnect") forState:UIControlStateNormal];
            cell.blockButton.tag=indexPath.row;
            cell.isConnected = YES;
//            cell.imageView.image = [UIImage imageNamed:@"router_cut-41.png"];
            [cell.iconImageView setHighlighted:YES];
            
            
            cell.statusInfoLabel.text = _(@"Connected");
//            [cell.blockButton addTarget:self action:@selector(doEditBlockedClient:) forControlEvents:UIControlEventTouchUpInside];
            
//            [cell addSubview:cell.blockButton];
            
            
        }else if (indexPath.section==1){
            NSString* tHostName;
            if ([[blockListDictionary objectForKey:blockListKeys[indexPath.row]] objectForKey:@"DeviceName"]) {
                tHostName = [[blockListDictionary objectForKey:blockListKeys[indexPath.row]] objectForKey:@"DeviceName"];
//                cell.detailTextLabel.text = blockListKeys[indexPath.row];
                cell.macInfoLabel.text = blockListKeys[indexPath.row];
            }
            if ([[blockListDictionary objectForKey:blockListKeys[indexPath.row]] objectForKey:@"Hostname"]) {
                tHostName = [[blockListDictionary objectForKey:blockListKeys[indexPath.row]] objectForKey:@"Hostname"];
//                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@    %@",[[blockListDictionary objectForKey:blockListKeys[indexPath.row]] objectForKey:@"IPAddress"],blockListKeys[indexPath.row]];
                cell.ipInfoLabel.text = [[blockListDictionary objectForKey:blockListKeys[indexPath.row]] objectForKey:@"IPAddress"];
                cell.macInfoLabel.text = blockListKeys[indexPath.row];
            }
            
            if (tHostName.length > 20) {
                tHostName =  [tHostName substringWithRange:NSMakeRange(0, 20)];
                tHostName = [NSString stringWithFormat:@"%@...",tHostName];
            }
            cell.titleLabel.text = tHostName;
//            UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
//            [button2 setFrame:CGRectMake(230, 10, 73, 26)];
            [cell.blockButton setTitle:_(@"Connect") forState:UIControlStateNormal];
            cell.blockButton.tag=indexPath.row;
            cell.isConnected = NO;
            [cell.iconImageView setHighlighted:NO];
            cell.statusInfoLabel.text = _(@"Blocked");
//            [cell.blockButton addTarget:self action:@selector(doDeleteBlockedClient:) forControlEvents:UIControlEventTouchUpInside];
//            [cell addSubview:button2];
        }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title=nil;
    switch (section) {
        case 0:
//            if ([listDictionary count] != 0) {
//                title = _(@"Connected Device(s)");
//            }
            break;
        case 1:
            if ([blockListDictionary count] != 0) {
                title = _(@"Blocked Device(s)");
            }
            break;
    }
    return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section==1) {
        return nil;
    }else{
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section==1) {
        if(saveView.hidden)
            return 5;
        else
            return 60;
    }else{
        return 5;
    }
}

- (void)cancelBlocked{
    saveView.hidden = YES;
    self.loadingView.hidden = NO;
    listDictionary = [NSMutableDictionary dictionary];
    blockListDictionary = [NSMutableDictionary dictionary];
    hideBlockListDictionary = [NSMutableDictionary dictionary];
    
    [self.tableView reloadData];
    [self performSelectorInBackground:@selector(getTableData) withObject:nil];
}

- (void)saveBlocked{
    
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"RouterPage_ClientManager_Block" Label:nil Value:nil];
#endif
    saveView.hidden = YES;
    
    for (NSString* macAddress in blockListDictionary) {
        if (![hideBlockListDictionary objectForKey:macAddress]) {
            [hideBlockListDictionary setObject:[blockListDictionary objectForKey:macAddress] forKey:macAddress];
        }
    }
    
    RouterGlobal *global = [[RouterGlobal alloc]init];
    NSMutableArray* blockedListArray = [NSMutableArray array];
    
    for (NSString* macAddress in hideBlockListDictionary) {
        NSMutableDictionary* t = [NSMutableDictionary dictionary];
        if ([[hideBlockListDictionary objectForKey:macAddress] objectForKey:@"DeviceName"]) {
            [t setObject:[[hideBlockListDictionary objectForKey:macAddress] objectForKey:@"DeviceName"] forKey:@"DeviceName"];
        }
        if ([[hideBlockListDictionary objectForKey:macAddress] objectForKey:@"Hostname"]) {
            [t setObject:[[hideBlockListDictionary objectForKey:macAddress] objectForKey:@"Hostname"] forKey:@"DeviceName"];
        }
        [t setObject:macAddress forKey:@"MacAddress"];
        [blockedListArray addObject:t];
    }
    
    if ([blockedListArray count] > 8) {
        [self showWarnning:@"Blocked_Limit"];
        [self cancelBlocked];
        return;
    }
    
    if([blockedListArray count] > 0){
        NSMutableDictionary* jsonDictionary =[NSMutableDictionary dictionary];
        [jsonDictionary setObject:@"true" forKey:@"Enabled"];
        [jsonDictionary setObject:blockedListArray forKey:@"BlockedClientList"];
        NSError* error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        //LogMessage(nil, 0, @"jsonString : %@", jsonString);
        NSLog(@"jsonString : %@", jsonString);
        [global editBlockedClientListWithJsonString:jsonString CompleteBlock:^(NSDictionary *resultDictionary) {
            //LogMessage(nil, 0, @"EditBlockedClientList : %@", result);
            NSLog(@"EditBlockedClientList : %@", resultDictionary);
            
            if ([resultDictionary[EDIT_BLOCKED_CLIENT_LIST_ACKTAG] isEqualToString:@"OK"]) {
    //            [self showTime];
                
                //    AppDelegate *appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                self.navigationController.parentViewController.definesPresentationContext = YES;
                RebootingViewController *view = [[RebootingViewController alloc] initWithNibName:@"RebootingViewController" bundle:nil];
                //    self.definesPresentationContext = YES; //self is presenting view controller
                view.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                view.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.4];
                [self.navigationController.parentViewController presentViewController:view animated:NO completion:nil];
                
            }else{
                if ([resultDictionary[@"LoginResult"] isEqualToString:@"ERROR"] || [[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
                    [self backToLoginPage];
                }else{
                    [self showWarnning:@"Operation_Failed"];
                    [self cancelBlocked];
                }
            }
        }];
    }else{
        [global deleteBlockedClientList:^(NSDictionary *resultDictionary) {
            NSLog(@"DeleteBlockedClientList : %@", resultDictionary);
            
            if ([resultDictionary[DELETE_BLOCKED_CLIENT_LIST_ACKTAG] isEqualToString:@"OK"]) {
                self.navigationController.parentViewController.definesPresentationContext = YES;
                RebootingViewController *view = [[RebootingViewController alloc] initWithNibName:@"RebootingViewController" bundle:nil];
                view.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                view.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.4];
                [self.navigationController.parentViewController presentViewController:view animated:NO completion:nil];
                
            }else{
                if ([resultDictionary[@"LoginResult"] isEqualToString:@"ERROR"] || [[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
                    [self backToLoginPage];
                }else{
                    [self showWarnning:@"Operation_Failed"];
                    [self cancelBlocked];
                }
            }
        }];
    }
}

- (void)doEditBlockedClient:(id)sender{
    saveView.hidden = NO;
//    UIButton *tButton = (UIButton*)sender;
//    tButton.enabled = NO;
    NSString* key = [listKeys objectAtIndex:[sender tag]];
    [blockListDictionary setObject:[listDictionary objectForKey:key] forKey:key];
    [listDictionary removeObjectForKey:key];
    listKeys = [listDictionary allKeys];
    blockListKeys = [blockListDictionary allKeys];
    [self.tableView reloadData];
}

- (void)doDeleteBlockedClient:(id)sender{
    saveView.hidden = NO;
//    UIButton *tButton = (UIButton*)sender;
//    tButton.enabled = NO;
    NSString* key = [blockListKeys objectAtIndex:[sender tag]];
    [listDictionary setObject:[blockListDictionary objectForKey:key] forKey:key];
    [blockListDictionary removeObjectForKey:key];
    listKeys = [listDictionary allKeys];
    blockListKeys = [blockListDictionary allKeys];
    [self.tableView reloadData];
}

//- (void)showTime{
//    self.mainView.alpha = 0.5;
//    self.mainView.userInteractionEnabled = NO;
//    self.rebootView.hidden = NO;
//    timerCount = 59;
//    autoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(goTimer:) userInfo:nil repeats:YES];
//}
//
//- (void)goTimer:(NSTimer *)theTimer{
//    if (timerCount == 59) {
//        [self performSelectorInBackground:@selector(reboot) withObject:nil];
//    }
//    
//    self.timerLbl.text = [NSString stringWithFormat:@"%d",timerCount];
//    if (timerCount == 0) {
//        [autoTimer invalidate];
//        autoTimer = nil;
//        [self logout];
//    }
//    timerCount --;
//}
//
//- (void)reboot{
//    RouterGlobal *global = [[RouterGlobal alloc]init];
//    [global reboot:^(NSDictionary *resultDictionary) {
//        NSLog(@"%@",resultDictionary);
//    }];
//}
//
-(void)backToLoginPage{
    //    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    //    [navController dismissViewControllerAnimated:YES completion:nil];
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

@end
