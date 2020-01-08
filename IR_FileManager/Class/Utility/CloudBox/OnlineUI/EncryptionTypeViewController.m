//
//  EncryptionTypeViewController.m
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "EncryptionTypeViewController.h"
#import "RouterGlobal.h"
#import "UIColor+Helper.h"
#import "ColorDefine.h"

@interface EncryptionTypeViewController (){
    NSMutableArray *tableArray;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation EncryptionTypeViewController

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
    
    self.navigationItem.title = _(@"Encryption Type");
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine]];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
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
    
    [UIView setAnimationsEnabled:YES];
    
    tableArray = [[NSMutableArray alloc]initWithObjects:@"Disable",@"WEP",@"WPA2(AES)",@"WPA(TKIP)",@"WPA2 Mixed",nil];
    
    [DataManager sharedInstance].uiViewController = self.navigationController;
    
    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated{
    [self.tableView reloadData];
}

- (void)dealloc{
    self.encryptionTag = nil;self.encryptionType = nil;
    tableArray = nil;
    self.tableView = nil;
}

- (void)backBtnDidClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [tableArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text =  [tableArray objectAtIndex:indexPath.row];
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    if ([[tableArray objectAtIndex:indexPath.row] isEqualToString:self.encryptionType]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    NSString *s=cell.textLabel.text;
    self.encryptionType = s;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
