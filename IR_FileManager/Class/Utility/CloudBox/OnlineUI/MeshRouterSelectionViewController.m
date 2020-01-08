//
//  MeshRouterSelectionViewController.m
//  EnShare
//
//  Created by Phil on 2017/3/16.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import "MeshRouterSelectionViewController.h"
#import "RouterGlobal.h"
#import "MeshRouterSelectionTableViewCell.h"
#import "DeviceClass.h"
#import "dataDefine.h"
#import "KGModal.h"
#import "DialogView.h"
#import "UIColor+Helper.h"
#import "ColorDefine.h"
#import "AutoUpload.h"

@interface MeshRouterSelectionViewController ()

@end

@implementation MeshRouterSelectionViewController{
    NSMutableArray *tableArray;
    UIBarButtonItem *leftItem, *rightItem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self doMeshRouter];
    
    meshRouterSelectMsgLabel.text = _(@"MESH_ROUTER_SELECT_MESSAGE");
    tableArray = [[NSMutableArray alloc]init];
    [self setNavigatinItem];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[DeviceClass sharedInstance] useCurrentConntectionDetail];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setNavigatinItem{
    self.navigationItem.title = _(@"MeshRouterSelectionTitle");
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
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
    
    leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [table registerNib:[UINib nibWithNibName:@"MeshRouterSelectionTableViewCell" bundle:nil] forCellReuseIdentifier:@"MeshRouterSelectionTableViewCell"];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
//    int h = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
//    table.frame = CGRectMake(table.frame.origin.x, h, table.frame.size.width, self.view.bounds.size.height - h);
}

-(void)backBtnDidClick{
    [[DeviceClass sharedInstance] stopLogin];
    [self back];
}

-(void)back{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doMeshRouter {
    [loadingView startAnimating];
    loadingView.hidden = NO;
    [self.view setUserInteractionEnabled:NO];
    
    if([DataManager sharedInstance].lanIPAddress == nil)
        [self getDeviceStatus];
    else{
        [self getMeshRouter];
    }
}

- (void)getDeviceStatus{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getDeviceStatus:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            LogMessage(nil, 0, @"GetDeviceStatus : %@", resultDictionary);
            [DataManager sharedInstance].lanIPAddress = [resultDictionary objectForKey:@"LanIPAddress"];
            
            [self getMeshRouter];
        }else{
            [self showAlert:@"Operation_Failed"];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

- (void)getMeshRouter{
    
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [[DeviceClass sharedInstance] useMasterConntectionDetail];
    
    [global getMeshNodeSimplifyInfo:^(NSDictionary *resultDictionary) {
        [[DeviceClass sharedInstance] useCurrentConntectionDetail];
        
        if (resultDictionary != nil) {
            if ([resultDictionary[GET_MESH_NODE_SIMPLIFY_INFO_ACKTAG] isEqualToString:@"OK"]) {
                for (NSDictionary *i in [resultDictionary objectForKey:@"MeshNodesList"]) {
                    if([[i objectForKey:@"DeviceType"] intValue] == 4)
                        continue;
                        
                    if([[i objectForKey:@"MeshRole"] isEqualToString:@"server"]){
                        [tableArray insertObject:i atIndex:0];
                    }else{
                        [tableArray addObject:i];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                    [table reloadData];
                    
                    [loadingView stopAnimating];
                    loadingView.hidden = YES;
                    [self.view setUserInteractionEnabled:YES];
                });
            }else{
                [self showAlert:@"Operation_Failed"];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }else{
            [self showAlert:@"Operation_Failed"];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MeshRouterSelectionTableViewCell";
    MeshRouterSelectionTableViewCell *cell = (MeshRouterSelectionTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ([tableArray count] != 0) {
        cell.meshRouterLabel.text = [NSString stringWithUTF8String:[[[tableArray objectAtIndex:indexPath.row] objectForKey:@"LocationName"] UTF8String]];
        
            if ([[[tableArray objectAtIndex:indexPath.row] objectForKey:@"LANIPAddress"] isEqualToString:[DataManager sharedInstance].lanIPAddress]) {
                //            cell.selected = YES;
//                cell.bgImageView.image = [UIImage imageNamed:@"tab_ibg.png"];
                if([[[tableArray objectAtIndex:indexPath.row] objectForKey:@"MeshRole"] isEqualToString:@"server"]){
                    [[DeviceClass sharedInstance] saveMasterConntectionDetail];
                }
                
                cell.checkedIcon.hidden = NO;
#ifdef MESSHUDrive
                cell.checkedIcon.image = [UIImage imageNamed:@"btn_list_check.png"];
#endif
                cell.meshRouterLabel.textColor = [UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine];
            }else{
//                cell.bgImageView.image = [UIImage imageNamed:@"tab_bg.png"];
#ifdef MESSHUDrive
                cell.checkedIcon.hidden = NO;
                cell.checkedIcon.image = [UIImage imageNamed:@"btn_list_uncheck.png"];
#else
                cell.checkedIcon.hidden = YES;
#endif
                
                cell.meshRouterLabel.textColor = UIColor.blackColor;
            }

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    [loadingView startAnimating];
    loadingView.hidden = NO;
    [self.view setUserInteractionEnabled:NO];
    
    [[AutoUpload sharedInstance] cancelUpload];
    
    [self.delegate doLoginWithUID:[[tableArray objectAtIndex:indexPath.row] objectForKey:@"UID"] WithLocalIP:[[tableArray objectAtIndex:indexPath.row] objectForKey:@"LANIPAddress"] loginDelegate:self];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
}

-(void)finishLogin:(DeviceClass *)device Success:(BOOL)success Message:(NSString *)message{
    if (success) {
        if ([message isEqualToString:@"OK"] || [message isEqualToString:@"GUEST"]) {
            [loadingView stopAnimating];
            loadingView.hidden = YES;
            [self.view setUserInteractionEnabled:YES];
            [self back];
            self.meshRouterChangedSuccessCallback();
        }else{
            [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        }
    }else{
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showAlert:(NSString*)str{
    DialogView *dialog = nil;
    VIEW(dialog, DialogView);
    dialog.delegate = self;
    dialog.titleLbl.text = NSLocalizedString(str, nil);
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

@end
