//
//  DiskViewController.m
//  EnShare
//
//  Created by ke on 2013/12/3.
//  Copyright (c) 2013年 Senao. All rights reserved.
//

#import "DiskViewController.h"
#import "RouterGlobal.h"
#import "DiskTableViewCell.h"
#import "DeviceClass.h"
#import "KGModal.h"
#import "DialogView.h"
#ifdef enshare
#import "SenaoGA.h"
#endif

@interface DiskViewController ()

@end

@implementation DiskViewController{
    UIBarButtonItem *leftItem, *rightItem;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [UIView setAnimationsEnabled:YES];
    tableArray = [[NSMutableArray alloc]init];
    [self setNavigatinItem];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
#ifdef enshare
    [SenaoGA setScreenName:@"Storage_DiskChange"];
#endif
}

-(void)viewDidAppear:(BOOL)animated{
    [self performSelectorInBackground:@selector(getDisk) withObject:nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)setNavigatinItem{
    self.navigationItem.title = _(@"DiskSelectionTitle");
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
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [table registerNib:[UINib nibWithNibName:@"DiskTableViewCell" bundle:nil] forCellReuseIdentifier:@"DiskCell"];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    int h = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    table.frame = CGRectMake(table.frame.origin.x, h, table.frame.size.width, self.view.bounds.size.height - h);
}

-(void)backBtnDidClick{
    [[StaticHttpRequest sharedInstance] destroySharedInstance];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getDisk{
    NSString* url = nil;
    
    if ([[[DeviceClass sharedInstance] scheme] isEqualToString:@"http"]) {
        url = [NSString stringWithFormat:@"http://%@:%d",[[DeviceClass sharedInstance] commandDeviceAddress],[[DeviceClass sharedInstance] commandHttpAgentPort]];
    }else{
        url = [NSString stringWithFormat:@"https://%@:%d",[[DeviceClass sharedInstance] commandDeviceAddress],[[DeviceClass sharedInstance] commandHttpsAgentPort]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [loadingView startAnimating];
    });
    
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getStorageInfo:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            if ([[resultDictionary objectForKey:@"StorageInformation"] count] == 0) {
                [self showAlert:@"USB"];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }else{
                //LogMessage(nil, 0, @"StorageInformation : %@", [tDict objectForKey:@"StorageInformation"]);
                for (NSDictionary *i in [resultDictionary objectForKey:@"StorageInformation"]) {
                    LogMessage(nil, 0, @"GetStorageInfo : %@", i);
                    [tableArray addObject:i];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
                [table reloadData];
                [loadingView stopAnimating];
                loadingView.hidden = YES;
            });
        }else{//訊息錯誤時，回到登入頁
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
    static NSString *CellIdentifier = @"DiskCell";
    DiskTableViewCell *cell = (DiskTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ([tableArray count] != 0) {
        cell.partitionLabel.text = [[tableArray objectAtIndex:indexPath.row] objectForKey:@"UsbPath"];
        if ([[[tableArray objectAtIndex:indexPath.row] objectForKey:@"UsbPath"] isEqualToString:[DataManager sharedInstance].diskPath]) {
//            cell.bgImageView.image = [UIImage imageNamed:@"tab_ibg.png"];
            cell.checkedIcon.highlighted = YES;
        }else{
//            cell.bgImageView.image = [UIImage imageNamed:@"tab_bg.png"];
            cell.checkedIcon.highlighted = NO;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    [DataManager sharedInstance].diskPath = [[tableArray objectAtIndex:indexPath.row] objectForKey:@"UsbPath"];
    [DataManager sharedInstance].diskGuestPath = [[tableArray objectAtIndex:indexPath.row] objectForKey:@"UsbGuestPath"];
    
    if ([[DeviceClass sharedInstance] isAdminUser]) {
        [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskPath;
    }else{//guest
        [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskGuestPath;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
}

#pragma mark - showAlert
- (void)showAlert:(NSString*)str{
    DialogView *dialog = nil;
    VIEW(dialog, DialogView);
    dialog.delegate = self;
    dialog.titleLbl.text = NSLocalizedString(str, nil);
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

@end
