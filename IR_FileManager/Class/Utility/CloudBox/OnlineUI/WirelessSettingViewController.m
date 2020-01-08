//
//  WirelessSettingViewController.m
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "WirelessSettingViewController.h"
#import "RouterGlobal.h"
#import "EncryptionTypeViewController.h"
#import "WirelessSettingTableViewCell.h"
#import "RebootingViewController.h"

#import "KGModal.h"
#import "SuccessView.h"

#import "UIColor+Helper.h"
#import "Masonry.h"

#ifdef enshare
#import "SenaoGA.h"
#endif

@interface WirelessSettingViewController (){
    UIView *footerView;
    
    NSMutableArray *tableArray1,*tableArray2;
    
    NSDictionary *_24Dict,*_5Dict;
//    NSDictionary *_24EncryptionDict,*_5EncryptionDict;
    
    NSString *radioID24,*radioID5;
    UISwitch *_24Switch,*_5Switch;
    UILabel *type24Label,*type5Label;
    UITextField *SSID24Field,*SSID5Field,*key24Field,*key5Field;
    UIButton *saveButton,*cancelButton;
    
    NSDictionary *WLanRadioSetting24Dict,*WLanRadioSetting5Dict;
    
    EncryptionTypeViewController *encryptionTypeViewController;
    
    int timerCount;
    NSTimer *autoTimer;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WirelessSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
#ifdef MESSHUDrive
    self.titleLabel.textColor = [UIColor whiteColor];
#endif
    
    self.titleBackgroundView.backgroundColor = self.navigationController.navigationBar.barTintColor;
    
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
    
    self.titleLabel.text = _(@"WIRELESS_SETTINGS_TITLE");
    self.hintTitleLabel.text = _(@"USERS_MANAGER_HINT_TITLE");
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        self.mainView.frame = CGRectMake(0, 20, self.mainView.frame.size.width, self.mainView.frame.size.height-20);
    } else {// iOS 6
    }
    [UIView setAnimationsEnabled:YES];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.loadingView.hidden = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"WirelessSettingTableViewCell" bundle:nil] forCellReuseIdentifier:@"WirelessSettingTableViewCell"];
    
    _24Switch = [[UISwitch alloc]initWithFrame:CGRectMake(234, 8, 0, 0)];
    _24Switch.tintColor = [UIColor grayColor];
    SSID24Field = [[UITextField alloc]initWithFrame:CGRectMake(150, 5, 150, 30)];
    [SSID24Field setFont:[UIFont systemFontOfSize:16]];
    type24Label = [[UILabel alloc]initWithFrame:CGRectMake(150, 5, 100, 30)];
    [type24Label setFont:[UIFont systemFontOfSize:16]];
    key24Field = [[UITextField alloc]initWithFrame:CGRectMake(150, 5, 160, 30)];
    [key24Field setFont:[UIFont systemFontOfSize:16]];
    key24Field.placeholder = _(@"PLEASEKEY");
    
    _5Switch = [[UISwitch alloc]initWithFrame:CGRectMake(234, 8, 0, 0)];
    _5Switch.tintColor = [UIColor grayColor];
    SSID5Field = [[UITextField alloc]initWithFrame:CGRectMake(150, 5, 150, 30)];
    [SSID5Field setFont:[UIFont systemFontOfSize:16]];
    type5Label = [[UILabel alloc]initWithFrame:CGRectMake(150, 5, 100, 30)];
    [type5Label setFont:[UIFont systemFontOfSize:16]];
    key5Field = [[UITextField alloc]initWithFrame:CGRectMake(150, 5, 160, 30)];
    [key5Field setFont:[UIFont systemFontOfSize:16]];
    key5Field.placeholder = _(@"PLEASEKEY");
    
    footerView  = [[UIView alloc] init];
    footerView.hidden = YES;
    saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [footerView setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 44 - 60, 320, 60)];
    footerView.backgroundColor = [UIColor whiteColor];
//    [saveButton setFrame:CGRectMake(200, 13, 100, 33)];
    [saveButton setTitle:_(@"SAVE") forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor colorWithRGB:0x007aff] forState:UIControlStateNormal];
//    [saveButton.titleLabel setTextAlignment:NSTextAlignmentRight];
//    saveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
//    [saveButton setFrame:CGRectMake(20, 8, 156, 30)];
//    [saveButton setImage:[UIImage imageNamed:_(@"rbtn_savenreboot")] forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(checkField) forControlEvents:UIControlEventTouchUpInside];
//    [cancelButton setFrame:CGRectMake(20, 13, 100, 33)];
    [cancelButton setTitle:_(@"Cancel") forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRGB:0x35424b] forState:UIControlStateNormal];
//    [cancelButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
//    cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
//    [cancelButton setFrame:CGRectMake(220, 8, 72, 30)];
//    [cancelButton setImage:[UIImage imageNamed:_(@"rbtn_cancel")] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(doCancel) forControlEvents:UIControlEventTouchUpInside];
//    UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    UIImageView *line = [UIImageView new];
    [line setBackgroundColor:[UIColor colorWithRGB:0xE5E5E5]];
    [footerView addSubview:saveButton];
    [footerView addSubview:cancelButton];
    [footerView addSubview:line];
    [self.view addSubview:footerView];
    [saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(footerView).mas_offset(-20);
        make.leading.equalTo(footerView.mas_centerX);
        make.top.bottom.equalTo(footerView);
    }];
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(footerView).mas_offset(20);
        make.trailing.equalTo(footerView.mas_centerX);
        make.top.bottom.equalTo(footerView);
    }];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.leading.trailing.top.equalTo(footerView);
    }];
    [footerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_bottomLayoutGuide);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(60);
    }];
    
    tableArray1 = [[NSMutableArray alloc]init];
    tableArray2 = [[NSMutableArray alloc]init];
    
    [tableArray1 addObject:_(@"Wireless SSID")];
    [tableArray1 addObject:_(@"Encryption Type")];
    
    //[self initData];
    [self performSelectorInBackground:@selector(initData) withObject:nil];
    
    [DataManager sharedInstance].uiViewController = self.navigationController;
    
     [self.navigationController.navigationBar setNeedsLayout];
}

- (void)dealloc{
    self.loadingView = nil;
    
    footerView = nil;
    tableArray1 = nil;tableArray2 = nil;
    _24Dict = nil;_5Dict = nil;
//    _24EncryptionDict = nil;_5EncryptionDict = nil;
    radioID24 = nil;radioID5 = nil;
    _24Switch = nil;_5Switch = nil;
    type24Label = nil;type5Label = nil;
    SSID24Field = nil;SSID5Field = nil;key24Field = nil;key5Field = nil;
    saveButton = nil;cancelButton = nil;
    WLanRadioSetting24Dict = nil;WLanRadioSetting5Dict = nil;
    encryptionTypeViewController = nil;
    
    self.tableView = nil;
}

- (void)viewDidAppear:(BOOL)animated{
    if ([encryptionTypeViewController.encryptionTag isEqualToString:@"2.4"]) {
        type24Label.text = encryptionTypeViewController.encryptionType;
        if (type24Label.text==nil || [type24Label.text isEqualToString:@""]) {
            
        }else if ([type24Label.text isEqualToString:@"Disable"]) {
            footerView.hidden = NO;
            [tableArray1 removeObject:_(@"Encryption Key")];
        }else{
            footerView.hidden = NO;
            if ([tableArray1 count]!=3){
                [tableArray1 addObject:_(@"Encryption Key")];
            }
        }
    }else if ([encryptionTypeViewController.encryptionTag isEqualToString:@"5"]) {
        type5Label.text = encryptionTypeViewController.encryptionType;
        if (type5Label.text==nil || [type5Label.text isEqualToString:@""]) {
            
        }else if ([type5Label.text isEqualToString:@"Disable"]) {
            footerView.hidden = NO;
            [tableArray2 removeObject:_(@"Encryption Key")];
        }else{
            footerView.hidden = NO;
            if ([tableArray2 count]!=3){
                [tableArray2 addObject:_(@"Encryption Key")];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (void)backBtnDidClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initData{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getWLanRadios:^(NSDictionary *resultDictionary) {
        if (resultDictionary) {
            NSDictionary *tDict = nil;
            tDict = [resultDictionary objectForKey:@"RadioInfos"];
            tDict = [tDict objectForKey:@"RadioInfo"];
            
            if (tDict) {
                NSLog(@"%@",tDict);
                int c=0;
                for (NSDictionary *i in tDict) {
                    if(c==0){
                        radioID24 = [[NSString alloc]initWithString:[i objectForKey:@"RadioID"]];
                    }else{
                        radioID5 = [[NSString alloc]initWithString:[i objectForKey:@"RadioID"]];
                        [self initTable:i tString:radioID5 tArray:tableArray2];
                    }
                    c++;
                }
                
                [_tableView reloadData];
                [self performSelectorInBackground:@selector(getRadio) withObject:nil];
            }
        }else{//logout
            [self backToLoginPage];
        }
    }];
}

- (void)initTable:(NSDictionary*)i tString:(NSString*)tString tArray:(NSMutableArray*)tArray{
    [tArray addObject:_(@"Wireless SSID")];
    [tArray addObject:_(@"Encryption Type")];
}

- (void)getRadio{
    //2.4G
    RouterGlobal *globalID24 = [[RouterGlobal alloc]init];
    [globalID24 getWLanRadioSettingsWithRadioID:radioID24 CompleteBlock:^(NSDictionary *resultDictionary) {
        if (resultDictionary) {
            _24Dict = resultDictionary;
            SSID24Field.text = [_24Dict objectForKey:@"SSID"];
            [self setUISwitch:_24Dict tUISwitch:_24Switch];
        }
        self.loadingView.hidden = YES;
        [_tableView reloadData];
    }];
//    _24EncryptionDict = [global getEncryption:radioID24];
    
    //5G
    RouterGlobal *globalID5 = [[RouterGlobal alloc]init];
    [globalID5 getWLanRadioSettingsWithRadioID:radioID5 CompleteBlock:^(NSDictionary *resultDictionary) {
        if (resultDictionary) {
            _5Dict = resultDictionary;
            SSID5Field.text = [_5Dict objectForKey:@"SSID"];
            [self setUISwitch:_5Dict tUISwitch:_5Switch];
        }
        self.loadingView.hidden = YES;
        [_tableView reloadData];
    }];
//    _5EncryptionDict = [global getEncryption:radioID5];
}

- (void)setRadio{
    SSID24Field.text = [_24Dict objectForKey:@"SSID"];
    [self setUISwitch:_24Dict tUISwitch:_24Switch];
    
    SSID5Field.text = [_5Dict objectForKey:@"SSID"];
    [self setUISwitch:_5Dict tUISwitch:_5Switch];
    
    self.loadingView.hidden = YES;
    [_tableView reloadData];
}

- (void)setUISwitch:(NSDictionary*)tDict tUISwitch:(UISwitch*)tUISwitch{
    NSString *enabled = [NSString stringWithFormat:@"%@",[tDict objectForKey:@"Enabled"]];
    if ([enabled isEqualToString:@"1"]) {
        [tUISwitch setOn:YES animated:YES];
    }else{
        [tUISwitch setOn:NO animated:YES];
    }
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    int lo=0;
    if ([textField isEqual:key24Field]) {
        lo = -100;
    }else if ([textField isEqual:SSID24Field]) {
        lo = -50;
    }else{
        lo = -200;
    }
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectMake(0,lo,self.view.frame.size.width,self.view.frame.size.height);
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
    [UIView commitAnimations];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return [tableArray1 count];
            break;
        case 1:
            return [tableArray2 count];
            break;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSString *CellIdentifier = @"WirelessSettingTableViewCell";
    NSString *CellIdentifier = nil;
    WirelessSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"WirelessSettingTableViewCell" owner:self options:nil] objectAtIndex:0];
    }
    
    CALayer *border = [CALayer layer];
    CGFloat borderWidth = 1;
    border.borderColor = [UIColor colorWithRGB:0x959595].CGColor;
    border.frame = CGRectMake(0, 30 - borderWidth, tableView.bounds.size.width - 150 - 20, 30);
    border.borderWidth = borderWidth;
    
        switch (indexPath.section) {
            case 0:
                cell.titleLabel.text = [NSString stringWithFormat:@"%@: ", [tableArray1 objectAtIndex:indexPath.row]];
                if (indexPath.row==0) {
                    SSID24Field.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
                    SSID24Field.textAlignment = NSTextAlignmentLeft;
                    SSID24Field.delegate=(id)self;
                    [SSID24Field addTarget:self action:@selector(fieldDidChange) forControlEvents:UIControlEventEditingChanged];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    [cell addSubview:SSID24Field];
                    [SSID24Field mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(cell).mas_offset(150);
                        make.right.equalTo(cell).mas_offset(-20);
                        make.top.equalTo(cell).mas_offset(5);
                        make.height.mas_equalTo(30);
                    }];
                    
                    [SSID24Field.layer addSublayer:border];
                    SSID24Field.layer.masksToBounds = YES;
                }else if (indexPath.row==1) {
                    type24Label.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
                    type24Label.textAlignment = NSTextAlignmentLeft;
                    type24Label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
                    [cell addSubview:type24Label];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }else if (indexPath.row==2) {
                    key24Field.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
                    key24Field.textAlignment = NSTextAlignmentLeft;
                    key24Field.delegate=(id)self;
                    [key24Field setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    [cell addSubview:key24Field];
                    [key24Field mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(cell).mas_offset(150);
                        make.right.equalTo(cell).mas_offset(-20);
                        make.top.equalTo(cell).mas_offset(5);
                        make.height.mas_equalTo(30);
                    }];
                    
                    [key24Field.layer addSublayer:border];
                    key24Field.layer.masksToBounds = YES;
                }
                break;
            case 1:
                cell.titleLabel.text = [NSString stringWithFormat:@"%@: ", [tableArray2 objectAtIndex:indexPath.row]];
                if (indexPath.row==0) {
                    SSID5Field.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
                    SSID5Field.textAlignment = NSTextAlignmentLeft;
                    SSID5Field.delegate=(id)self;
                    [SSID5Field addTarget:self action:@selector(fieldDidChange) forControlEvents:UIControlEventEditingChanged];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    [cell addSubview:SSID5Field];
                    [SSID5Field mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(cell).mas_offset(150);
                        make.right.equalTo(cell).mas_offset(-20);
                        make.top.equalTo(cell).mas_offset(5);
                        make.height.mas_equalTo(30);
                    }];
                    
                    [SSID5Field.layer addSublayer:border];
                    SSID5Field.layer.masksToBounds = YES;
                }else if (indexPath.row==1) {
                    type5Label.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
                    type5Label.textAlignment = NSTextAlignmentLeft;
                    type5Label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
                    [cell addSubview:type5Label];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }else if (indexPath.row==2) {
                    key5Field.textColor = [UIColor colorWithRed:54.f/255.f green:89.f/255.f blue:140.f/255.f alpha:1];
                    key5Field.textAlignment = NSTextAlignmentLeft;
                    key5Field.delegate=(id)self;
                    [key5Field setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    [cell addSubview:key5Field];
                    [key5Field mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(cell).mas_offset(150);
                        make.right.equalTo(cell).mas_offset(-20);
                        make.top.equalTo(cell).mas_offset(5);
                        make.height.mas_equalTo(30);
                    }];
                    
                    [key5Field.layer addSublayer:border];
                    key5Field.layer.masksToBounds = YES;
                }
                break;
        }
    
    return cell;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    UIView *titleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
//    [titleView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.mas_equalTo(tableView.bounds.size.width);
//        make.height.mas_equalTo(50);
//    }];
    
    UIView *titleView = [UIView new];
    
    if (section==0) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 7, 200, 30)];
        label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        label.text = [NSString stringWithFormat:@"%@ 2.4 GHz", _(@"FREQUENCY")];
        NSRange substringRange = [label.text rangeOfString:@"2.4" options:NSCaseInsensitiveSearch];
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:label.text];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRGB:0x007aff] range:substringRange];
        label.attributedText = string;
        [label setFont:[UIFont fontWithName:@"Arial-BoldMT" size:18]];
        [_24Switch addTarget:self action:@selector(fieldDidChange) forControlEvents:UIControlEventValueChanged];
        [titleView addSubview:label];
        [titleView addSubview:_24Switch];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleView).offset(15);
            make.top.equalTo(titleView).offset(7);
            make.width.mas_equalTo(200);
            make.height.mas_equalTo(30);
        }];
        [_24Switch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(titleView).offset(-15);
            make.top.equalTo(titleView).offset(8);
        }];
    }else if (section==1 && radioID5!=nil) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 7, 200, 30)];
        label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        label.text = [NSString stringWithFormat:@"%@ 5 GHz", _(@"FREQUENCY")];
        NSRange substringRange = [label.text rangeOfString:@"5" options:NSCaseInsensitiveSearch];
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:label.text];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRGB:0x007aff] range:substringRange];
        label.attributedText = string;
        [label setFont:[UIFont fontWithName:@"Arial-BoldMT" size:18]];
        [_5Switch addTarget:self action:@selector(fieldDidChange) forControlEvents:UIControlEventValueChanged];
        [titleView addSubview:label];
        [titleView addSubview:_5Switch];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleView).offset(15);
            make.top.equalTo(titleView).offset(7);
            make.width.mas_equalTo(200);
            make.height.mas_equalTo(30);
        }];
        [_5Switch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(titleView).offset(-15);
            make.top.equalTo(titleView).offset(8);
        }];
    }
    
    return titleView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row==1){
//        encryptionTypeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EncryptionTypeViewController"];
        encryptionTypeViewController = [[EncryptionTypeViewController alloc] initWithNibName:@"EncryptionTypeViewController" bundle:nil];
        if(indexPath.section==0){
            encryptionTypeViewController.encryptionTag = @"2.4";
            encryptionTypeViewController.encryptionType = type24Label.text;
        }else{
            encryptionTypeViewController.encryptionTag = @"5";
            encryptionTypeViewController.encryptionType = type5Label.text;
        }
        
        [self.navigationController pushViewController:encryptionTypeViewController animated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section==1) {
        return nil;
    }else{
        return nil;
    }
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return 44.0;
    }else if (section==1 && radioID5!=nil) {
        return 44.0;
    }else{
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section==1) {
        return 60;
    }else{
        return 10;
    }
}

- (void)fieldDidChange{
    footerView.hidden = NO;
}

- (void)checkField{
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"RouterPage_WirelessSettings-Save" Label:nil Value:nil];
#endif
    [SSID24Field resignFirstResponder];
    [key24Field resignFirstResponder];
    [SSID5Field resignFirstResponder];
    [key5Field resignFirstResponder];
    
    //LogMessage(nil, 0, @"type24Label.text %@", type24Label.text);
    
    bool tagReboot24 = NO, tagReboot5 = NO;
    if (type24Label.text == nil) { //只設定開或關 for 2.4G
        
        if ([SSID24Field.text isEqualToString:@""]) {//SSID不能為空白
            [self showWarnning:@"SSID_EMPTY_ALERT"];
            tagReboot24 = NO;
        }else if (SSID24Field.text.length > 32){//SSID長度限制為32
            [self showWarnning:@"SSID_LENGTH_ALERT"];
            tagReboot24 = NO;
        }else if ( [[DataManager sharedInstance] checkFileName:SSID24Field.text] ){//特殊字元
            [self showWarnning:@"SSID_ERROR_ALERT"];
            tagReboot24 = NO;
        }else{
            tagReboot24 = YES;
        }
        
    }else if (type24Label.text != nil) { //有設定密碼 for 2.4G
        
        if ([SSID24Field.text isEqualToString:@""]) {//SSID不能為空白
            [self showWarnning:@"SSID_EMPTY_ALERT"];
            tagReboot24 = NO;
        }else if (SSID24Field.text.length > 32){//SSID長度限制為32
            [self showWarnning:@"SSID_LENGTH_ALERT"];
            tagReboot24 = NO;
        }else if (![type24Label.text isEqualToString:@"Disable"] && [key24Field.text isEqualToString:@""]){//KEY不能為空白
            [self showWarnning:@"KEY_EMPTY_ALERT"];
            tagReboot24 = NO;
        }else if ( [[DataManager sharedInstance] checkFileName:key24Field.text] ){//特殊字元
            [self showWarnning:@"KEY_ERROR_ALERT"];
            tagReboot24 = NO;
        }else if ([type24Label.text isEqualToString:@"WEP"]) {
            tagReboot24 = [self checkWEP:key24Field.text type:@"2.4G"];
            
        }else if ([type24Label.text isEqualToString:@"WPA2(AES)"] && ( key24Field.text.length<8 || key24Field.text.length>63 ) ) { //“AES”,”TKIP”,”TKIPORAES”, Encryption Key長度需為8~63.
            [self showWarnning:@"KEY_8To63_ALERT"];
            tagReboot24 = NO;
        }else if ([type24Label.text isEqualToString:@"WPA(TKIP)"] && ( key24Field.text.length<8 || key24Field.text.length>63 ) ) { //“AES”,”TKIP”,”TKIPORAES”, Encryption Key長度需為8~63.
            [self showWarnning:@"KEY_8To63_ALERT"];
            tagReboot24 = NO;
        }else if ([type24Label.text isEqualToString:@"WPA2 Mixed"] && ( key24Field.text.length<8 || key24Field.text.length>63 ) ) {//“AES”,”TKIP”,”TKIPORAES”, Encryption Key長度需為8~63.
            [self showWarnning:@"KEY_8To63_ALERT"];
            tagReboot24 = NO;
        }else{
            tagReboot24 = YES;
        }

    }
    
    if (radioID5 != nil && type5Label.text == nil) {//只設定開或關 for 5G
        
        if (radioID5!=nil && [SSID5Field.text isEqualToString:@""]){//SSID不能為空白
            [self showWarnning:@"SSID_EMPTY_ALERT"];
            tagReboot5 = NO;
        }else if (radioID5!=nil && SSID5Field.text.length > 32){//SSID長度限制為32
            [self showWarnning:@"SSID_LENGTH_ALERT"];
            tagReboot5 = NO;
        }else if ( [[DataManager sharedInstance] checkFileName:SSID5Field.text] ){//特殊字元
            [self showWarnning:@"SSID_ERROR_ALERT"];
            tagReboot5 = NO;
        }else{
            tagReboot5 = YES;
        }
        
    }else if (radioID5 != nil && type5Label.text != nil) {//有設定密碼 for 5G
        
        if ([SSID5Field.text isEqualToString:@""]){//SSID不能為空白
            [self showWarnning:@"SSID_EMPTY_ALERT"];
            tagReboot5 = NO;
        }else if (SSID5Field.text.length > 32){//SSID長度限制為32
            [self showWarnning:@"SSID_LENGTH_ALERT"];
            tagReboot5 = NO;
        }else if (![type5Label.text isEqualToString:@"Disable"] && [key5Field.text isEqualToString:@""]){//KEY不能為空白
            [self showWarnning:@"KEY_EMPTY_ALERT"];
            tagReboot5 = NO;
        }else if ( [[DataManager sharedInstance] checkFileName:key5Field.text] ){//特殊字元
            [self showWarnning:@"KEY_ERROR_ALERT"];
            tagReboot5 = NO;
        }else if ([type5Label.text isEqualToString:@"WEP"]) {
            tagReboot5 = [self checkWEP:key5Field.text type:@"5G"];
            
        }else if ([type5Label.text isEqualToString:@"WPA2(AES)"] && ( key5Field.text.length<8 || key5Field.text.length>63 ) ) {
            [self showWarnning:@"KEY_8To63_ALERT"];
            tagReboot5 = NO;
        }else if ([type5Label.text isEqualToString:@"WPA(TKIP)"] &&  ( key5Field.text.length<8 || key5Field.text.length>63 ) ) {
            [self showWarnning:@"KEY_8To63_ALERT"];
            tagReboot5 = NO;
        }else if ([type5Label.text isEqualToString:@"WPA2 Mixed"] && ( key5Field.text.length<8 || key5Field.text.length>63 ) ) {
            [self showWarnning:@"KEY_8To63_ALERT"];
            tagReboot5 = NO;
        }else{
            tagReboot5 = YES;
        }
        
    }
    
    //reboot
    if (tagReboot24 == YES && tagReboot5 == YES) {
        [self enableSSID24];
        [self editEncryption24];
        [self enableSSID5];
        [self editEncryption5];
        [self showRebooting];
    }else if (tagReboot24 == YES && radioID5 == nil) {
        [self enableSSID24];
        [self editEncryption24];
        [self showRebooting];
    }
    
}

-(void)showRebooting{
    self.navigationController.parentViewController.definesPresentationContext = YES;
    RebootingViewController *view = [[RebootingViewController alloc] initWithNibName:@"RebootingViewController" bundle:nil];
    view.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    view.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.4];
    [self.navigationController.parentViewController presentViewController:view animated:NO completion:nil];
}

- (bool)checkWEP:(NSString*)key type:(NSString*)type{
    bool tagEdit = NO;
    if (key.length==5) {
        if (![self regularCheck:@"[a-zA-Z0-9]{5}" checkStr:key]) { //Encryption Key 不符合ASCII規則
            [self showWarnning:[NSString stringWithFormat:_(@"illegal %@ ASCII key value"),type] ];
            tagEdit = NO;
        }else{
            tagEdit = YES;
        }
    }else if (key.length==10) {
        if (![self regularCheck:@"[a-fA-F0-9]{10}" checkStr:key]) { //Encryption Key 不符合16進位規則
            [self showWarnning:@"KEY_HEX_ALERT"];
            tagEdit = NO;
        }else{
            tagEdit = YES;
        }
    }else if (key.length==13) {
        if (![self regularCheck:@"[a-zA-Z0-9]{13}" checkStr:key]) { //Encryption Key 不符合ASCII規則
            [self showWarnning:[NSString stringWithFormat:_(@"illegal %@ ASCII key value"),type] ];
            tagEdit = NO;
        }else{
            tagEdit = YES;
        }
    }else if (key.length==26) {
        if (![self regularCheck:@"[a-fA-F0-9]{26}" checkStr:key]) { //Encryption Key 不符合16進位規則
            [self showWarnning:@"KEY_HEX_ALERT"];
            tagEdit = NO;
        }else{
            tagEdit = YES;
        }
    }else{//如果Encryption Key 長度不符合規則(5,10,13,26)
        [self showWarnning:@"KEY_LENGTH_ALERT"];
        tagEdit = NO;
    }
    
    if (tagEdit == YES) {
    if ([type isEqualToString:@"2.4G"]) {
        [self enableSSID24];
        [self editEncryption24];
    }else{
        [self enableSSID5];
        [self editEncryption5];
    }
    }
    
    return tagEdit;
}

- (BOOL)regularCheck:(NSString*)pattern checkStr:(NSString*)checkStr{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if ([pred evaluateWithObject: checkStr]){
        return YES;
    }else{
        return NO;
    }
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

- (void)enableSSID24{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    NSString *enable24;
    if ([_24Switch isOn]) {
        enable24 = @"true";
    }else{
        enable24 = @"false";
    }
    NSString *SSIDBroadcast24 = [NSString stringWithFormat:@"%@",[_24Dict objectForKey:@"SSIDBroadcast"]];
    if ([SSIDBroadcast24 isEqualToString:@"1"]) {
        SSIDBroadcast24 = @"true";
    }else{
        SSIDBroadcast24 = @"false";
    }
    NSString *jsonString = [NSString stringWithFormat:
                            @"{\"RadioID\":\"%@\",\"SSIDID\":\"%@\",\"Enabled\":\"%@\",\"Mode\":\"%@\",\"SSID\":\"%@\",\"SSIDBroadcast\":\"%@\",\"ChannelWidth\":\"%@\",\"Channel\":\"%@\"}",
                            radioID24,@"1",enable24,[_24Dict objectForKey:@"Mode"],SSID24Field.text,SSIDBroadcast24,[_24Dict objectForKey:@"ChannelWidth"],[_24Dict objectForKey:@"Channel"]];
    [global setWLanRadioSettingsWithJsonString:jsonString CompleteBlock:^(NSDictionary *resultDictionary) {
        LogMessage(nil, 0, @"result24 : %@", resultDictionary);
    }];
}

- (void)editEncryption24{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    NSString *enable24;
    if ([type24Label.text isEqualToString:@"Disable"]) {
        enable24 = @"false";
    }else{
        enable24 = @"true";
    }
    NSString *jsonString = [NSString stringWithFormat:@"{\"RadioID\":\"%@\",\"SSIDID\":\"%@\",\"Enabled\":\"%@\",\"Type\":\"%@\",\"Encryption\":\"%@\",\"Key\":\"%@\"}",
                  radioID24,@"1",enable24,[self getEncryptionType:type24Label.text],[self getEncryption:type24Label.text key:key24Field.text],key24Field.text];
    LogMessage(nil, 0, @"SSID 2.4 jsonString %@", jsonString);
    [global setWLanRadioSecurityWithJsonString:jsonString CompleteBlock:^(NSDictionary *resultDictionary) {
        LogMessage(nil, 0, @"SSID 2.4 %@", resultDictionary);
        //NSString *resultKey24 = [tDict objectForKey:@"SetWLanRadioSecurityResult"];
    }];
}

- (void)enableSSID5{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    NSString *enable5;
    if ([_5Switch isOn]) {
        enable5 = @"true";
    }else{
        enable5 = @"false";
    }
    NSString *SSIDBroadcast5 = [NSString stringWithFormat:@"%@",[_5Dict objectForKey:@"SSIDBroadcast"]];
    if ([SSIDBroadcast5 isEqualToString:@"1"]) {
        SSIDBroadcast5 = @"true";
    }else{
        SSIDBroadcast5 = @"false";
    }
    NSString *jsonString = [NSString stringWithFormat:
                  @"{\"RadioID\":\"%@\",\"SSIDID\":\"%@\",\"Enabled\":\"%@\",\"Mode\":\"%@\",\"SSID\":\"%@\",\"SSIDBroadcast\":\"%@\",\"ChannelWidth\":\"%@\",\"Channel\":\"%@\"}",
                  radioID5,@"1",enable5,[_5Dict objectForKey:@"Mode"],SSID5Field.text,SSIDBroadcast5,[_5Dict objectForKey:@"ChannelWidth"],[_5Dict objectForKey:@"Channel"]];
    LogMessage(nil, 0, @"enableSSID5 jsonString : %@", jsonString);
    [global setWLanRadioSettingsWithJsonString:jsonString CompleteBlock:^(NSDictionary *resultDictionary) {
        LogMessage(nil, 0, @"enableSSID5 result : %@", resultDictionary);
    }];
}

- (void)editEncryption5{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    NSString *enable5;
    if ([type5Label.text isEqualToString:@"Disable"]) {
        enable5 = @"false";
    }else{
        enable5 = @"true";
    }
    NSString *jsonString = [NSString stringWithFormat:@"{\"RadioID\":\"%@\",\"SSIDID\":\"%@\",\"Enabled\":\"%@\",\"Type\":\"%@\",\"Encryption\":\"%@\",\"Key\":\"%@\"}",
                  radioID5,@"1",enable5,[self getEncryptionType:type5Label.text],[self getEncryption:type5Label.text key:key5Field.text],key5Field.text];
    LogMessage(nil, 0, @"editEncryption5 jsonString %@", jsonString);
    [global setWLanRadioSecurityWithJsonString:jsonString CompleteBlock:^(NSDictionary *resultDictionary) {
        LogMessage(nil, 0, @"editEncryption5 result %@", resultDictionary);
        //NSString *resultKey5 = [tDict objectForKey:@"SetWLanRadioSecurityResult"];
    }];
}

- (NSString*)setEncryptionTypeLabel:(NSString*)encryption{
    NSString *temp=@"";
    if( [encryption isEqualToString:@"AES"]){
        temp=@"WPA2(AES)";
    }else if( [encryption isEqualToString:@"TKIP"]){
        temp=@"WPA(TKIP)";
    }else if( [encryption isEqualToString:@"TKIPORAES"]){
        temp=@"WPA2 Mixed";
    }else{
        temp=encryption;
    }
    return temp;
}

- (NSString*)getEncryption:(NSString*)encryption key:(NSString*)key{
    NSString *temp=@"";
    if( [encryption isEqualToString:@"Disable"]){
        temp=@"";
    }else if( [encryption isEqualToString:@"WEP"]){
        if (key.length==5) {
            temp=@"WEP-64";
        }else if (key.length==10) {
            temp=@"WEP-64";
        }else if (key.length==13) {
            temp=@"WEP-128";
        }else if (key.length==26) {
            temp=@"WEP-128";
        }
    }else if( [encryption isEqualToString:@"WPA2(AES)"]){
        temp=@"AES";
    }else if( [encryption isEqualToString:@"WPA(TKIP)"]){
        temp=@"TKIP";
    }else if( [encryption isEqualToString:@"WPA2 Mixed"]){
        temp=@"TKIPORAES";
    }
    return temp;
}

- (NSString*)getEncryptionType:(NSString*)encryption{
    NSString *temp=@"";
    if( [encryption isEqualToString:@"Disable"]){
        temp=@"";
    }else if( [encryption isEqualToString:@"WEP"]){
        temp=@"WEP-OPEN";
    }else if( [encryption isEqualToString:@"WPA2(AES)"]){
        temp=@"WPA2-PSK";
    }else if( [encryption isEqualToString:@"WPA(TKIP)"]){
        temp=@"WPA-PSK";
    }else if( [encryption isEqualToString:@"WPA2 Mixed"]){
        temp=@"WPAORWPA2-PSK";
    }
    return temp;
}

- (void)doCancel{
    [self setRadio];
    [self cancelType24];
    [self cancelType5];
    footerView.hidden = YES;
    [self.tableView reloadData];
}

- (void)cancelType24{
    type24Label.text = @"";
    key24Field.text = @"";
    [tableArray1 removeObject:_(@"Encryption Key")];
}

- (void)cancelType5{
    type5Label.text = @"";
    key5Field.text = @"";
    [tableArray2 removeObject:_(@"Encryption Key")];
}

-(void)backToLoginPage{
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
//    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
//    [navController dismissViewControllerAnimated:YES completion:nil];
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
