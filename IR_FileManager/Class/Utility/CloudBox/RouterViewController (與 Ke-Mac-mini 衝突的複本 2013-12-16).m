//
//  RouterViewController.m
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "RouterViewController.h"
#import "RouterGlobal.h"
#import "ThroughputViewController.h"
#import "StorageViewController.h"
#import "CollectionViewController.h"
#import "StatusViewController.h"
#import "AboutViewController.h"
#import "WirelessSettingViewController.h"
#import "DeviceStatusViewController.h"
#import "ClientManagerViewController.h"
#import "AdvancedStatusViewController.h"
#import "KGModal.h"

@interface RouterViewController (){
    ThroughputViewController *throughputViewController;
    UIView *footerView;
    UIButton *logoutBtn;
}

@property (strong, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UILabel *offLineLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(retain,nonatomic) NSMutableArray *tableArray;

@end

@implementation RouterViewController

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
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        self.mainView.frame = CGRectMake(0, 20, self.mainView.frame.size.width, self.mainView.frame.size.height-20);
        [self.tableView setContentInset:UIEdgeInsetsMake(-36,0,0,0)];
    } else {// iOS 6
    }
    
    if ([DataManager sharedInstance].offline == TRUE) {
        self.tableView.hidden = YES;
        self.offLineLabel.hidden = NO;
    } else {
        self.tableView.hidden = NO;
        self.offLineLabel.hidden = YES;
        
        throughputViewController = [[ThroughputViewController alloc] initWithNibName:@"ThroughputViewController" bundle:[NSBundle mainBundle]];
        throughputViewController.view.frame = CGRectMake(0, 45 + self.mainView.frame.origin.y, throughputViewController.view.frame.size.width, throughputViewController.view.frame.size.height);
        [self.view addSubview:throughputViewController.view];
        
        self.tableArray = [[NSMutableArray alloc]initWithObjects:_(@"Device Status"),_(@"Wireless Settings"),_(@"Client Manager"),_(@"Advanced Settings"), nil];
    }
    
    footerView  = [[UIView alloc] init];
    logoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.throughputView.hidden = [DataManager sharedInstance].offline;
    self.backBtn.hidden = ![DataManager sharedInstance].offline;
    [DataManager sharedInstance].uiViewController = self.navigationController;
}

- (void)dealloc{
    throughputViewController = nil;
    footerView = nil;logoutBtn = nil;
    self.offLineLabel = nil;
    self.tableView = nil;
    self.tableArray = nil;
}

- (void)viewDidAppear:(BOOL)animated{
    [self.tableView reloadData];
}

- (IBAction)backClk:(id)sender {
    NSArray *views = self.navigationController.viewControllers;
    [self.navigationController setViewControllers:@[views[0], views[1]] animated:YES];
}

- (IBAction)storageClk:(id)sender {
    StorageViewController *sview = [self.storyboard instantiateViewControllerWithIdentifier:@"StorageViewController"];
    [self.navigationController setViewControllers:@[ self.navigationController.viewControllers[0], self.navigationController.viewControllers[1], sview] animated:FALSE];
}

- (IBAction)collectionClk:(id)sender {
    CollectionViewController *sview = [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionViewController"];
    [self.navigationController setViewControllers:@[ self.navigationController.viewControllers[0], self.navigationController.viewControllers[1], sview] animated:FALSE];
}

- (IBAction)statusClk:(id)sender {
    StatusViewController *sview = [self.storyboard instantiateViewControllerWithIdentifier:@"StatusViewController"];
    [self.navigationController setViewControllers:@[ self.navigationController.viewControllers[0], self.navigationController.viewControllers[1], sview] animated:FALSE];
}

- (IBAction)routerClk:(id)sender {
}

- (IBAction)aboutClk:(id)sender {
    AboutViewController *sview = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
    [self.navigationController setViewControllers:@[ self.navigationController.viewControllers[0], self.navigationController.viewControllers[1], sview] animated:FALSE];
}
/*
- (void)getSystemThroughput{
    RouterGlobal *global = [[RouterGlobal alloc]init:[DataManager sharedInstance].rotuerURL];
    NSArray *tArray = [global getSystemThroughput];
    if (tArray != nil) {
        if ([tArray count]==2) {
            throughputViewController.uploadLabel.text = [tArray objectAtIndex:0];
            throughputViewController.downloadLabel.text = [tArray objectAtIndex:1];
        }
    }else{
        NSArray *views = self.navigationController.viewControllers;
        [self.navigationController setViewControllers:@[views[0], views[1]] animated:YES];
    }
}
*/
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 49;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text =  [self.tableArray objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    return cell;
}

/*
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section==1) {
        [logoutBtn setFrame:CGRectMake(0, 0, 320, 51)];
        [logoutBtn setImage:[UIImage imageNamed:@"btn_logout.png"] forState:UIControlStateNormal];
        [logoutBtn addTarget:self action:@selector(doLogout) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:logoutBtn];
        return footerView;
    }else{
        return nil;
    }
}
*/
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section==1) {
        return 51;
    }else{
        return 10;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            DeviceStatusViewController *view = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceStatusViewController"];
            [self.navigationController pushViewController:view animated:YES];
            [[KGModal sharedInstance] hideAnimated:YES];
        }else if (indexPath.row==1) {
            WirelessSettingViewController *view = [self.storyboard instantiateViewControllerWithIdentifier:@"WirelessSettingViewController"];
            [self.navigationController pushViewController:view animated:YES];
            [[KGModal sharedInstance] hideAnimated:YES];
        }else if (indexPath.row==2) {
            ClientManagerViewController *view = [self.storyboard instantiateViewControllerWithIdentifier:@"ClientManagerViewController"];
            [self.navigationController pushViewController:view animated:YES];
        }else if (indexPath.row==3) {
            AdvancedStatusViewController *view = [self.storyboard instantiateViewControllerWithIdentifier:@"AdvancedStatusViewController"];
            [self.navigationController pushViewController:view animated:YES];
        }
    }
}
/*
- (void)doLogout{
    [self.navigationController popViewControllerAnimated:YES];
}
*/
@end
