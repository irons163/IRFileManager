//
//  NotificationCenterMainViewController.m
//  EnShare
//
//  Created by Phil on 2016/12/14.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "NotificationCenterMainViewController.h"
#import "NotificationCenterViewController.h"
#import "EnShareTools.h"
#import "CommonTools.h"
#import "NotificationCenterMainTableViewCell.h"
#import "UIColor+Helper.h"
#import "KGModal.h"
#import "StorageSelectWarningView.h"
#import "StorageDeleteView.h"
#import "SuccessView.h"

typedef NS_ENUM(NSUInteger, EditMode) {
    NormalMode,
    DeleteMode
};

@implementation NotificationItem

-(id)initWithTitle:(NSString*)title subtitle:(NSString*)subtitle message:(NSString*)message date:(NSDate*)date{
    if(self = [super init]){
        self.title = title;
        self.subtitle = subtitle;
        self.message = message;
        self.date = date;
    }
    return self;
}

@end

@interface NotificationCenterMainViewController ()

@end

@implementation NotificationCenterMainViewController{
    NSMutableArray *items;
    NSMutableArray* selectedItems;
    NSMutableArray *autocompleteUrls;
    UIButton* cancelDeleteModeButton;
    UIBarButtonItem *leftItem, *rightItem, *leftButtonForCancelDeleteMode, *rightButtonForDoDelete;
    UITextField *textField;
    bool searchActived;
    EditMode editMode;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setNavigatinItem];
    [self setToolBar];
    
    items = [NSMutableArray array];
    selectedItems = [NSMutableArray array];
    autocompleteUrls = [NSMutableArray array];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableArray *notificationItems = [NSMutableArray arrayWithArray:[userDefault arrayForKey:@"Notification"]];
    for(NSDictionary* dic in notificationItems){
        NotificationItem *item = [[NotificationItem alloc] initWithTitle:dic[@"title"] subtitle:dic[@"subtitle"] message:dic[@"message"] date:dic[@"date"]];
        [items addObject:item];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = _(@"NOTIFICATION_CENTER_TITLE");
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setNavigatinItem{
    //    self.navigationItem.title = _(@"Files List");
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = YES;
    UIImage* backImage = [UIImage imageNamed:@"btn_nav_back.png"];
    UIImage* iBackImage = [UIImage imageNamed:@"ibtn_nav_back"];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:backImage forState:UIControlStateNormal];
    if (iBackImage) {
        [backButton setImage:iBackImage forState:UIControlStateHighlighted];
    }
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect backButtonFrame = backButton.frame;
    backButtonFrame.origin.x = 0;
    backButtonFrame.origin.y = 10;
    backButtonFrame.size.width = 90.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    [backButton setTitle:_(@"Back") forState:UIControlStateNormal];
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    leftItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-40];
    
    UIButton *changeToDeleteModeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
    changeToDeleteModeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [changeToDeleteModeButton setTitle:_(@"Edit") forState:UIControlStateNormal];
    [changeToDeleteModeButton setTitleColor:[UIColor colorWithColorCodeString:@"1BA48A"] forState:UIControlStateNormal];
    [changeToDeleteModeButton addTarget:self action:@selector(switchDeleteMode) forControlEvents:UIControlEventTouchUpInside];
    
    rightItem = [[UIBarButtonItem alloc] initWithCustomView:changeToDeleteModeButton];
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight, rightItem, nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    cancelDeleteModeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    cancelDeleteModeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [cancelDeleteModeButton setTitle:_(@"Cancel") forState:UIControlStateNormal];
    [cancelDeleteModeButton setTitleColor:[UIColor colorWithColorCodeString:@"1BA48A"] forState:UIControlStateNormal];
    [cancelDeleteModeButton addTarget:self action:@selector(switchDeleteMode) forControlEvents:UIControlEventTouchUpInside];
    leftButtonForCancelDeleteMode = [[UIBarButtonItem alloc] initWithCustomView:cancelDeleteModeButton];
    
    UIButton *doDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    doDeleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [doDeleteButton setTitle:_(@"Delete") forState:UIControlStateNormal];
    [doDeleteButton setTitleColor:[UIColor colorWithColorCodeString:@"1BA48A"] forState:UIControlStateNormal];
    [doDeleteButton addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
    rightButtonForDoDelete = [[UIBarButtonItem alloc] initWithCustomView:doDeleteButton];
}

-(void)setNormalNavigatinItem{
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-40];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,leftItem,nil];
    negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,rightItem,nil];
}

-(void)setDeletingNavigatinItem{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = leftButtonForCancelDeleteMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoDelete,nil];
}

-(void)setToolBar{
    UIView *toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, 50)];
    [toolBar setBackgroundColor:[UIColor colorWithColorCodeString:@"fff4f4f4"]];
    [self.view addSubview:toolBar];
    
    UIButton *dismissSearchBarButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-50, 0, 50, 50)];
    UIImage *image = [UIImage imageNamed:@"btn_search_cancle"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(15, 15)];
    [dismissSearchBarButton setImage:image forState:UIControlStateNormal];
    [dismissSearchBarButton setImage:image forState:UIControlStateHighlighted];
    [dismissSearchBarButton addTarget:self action:@selector(clearSearchBarContent) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(12, 15, 20, 20)];
    searchIcon.image = [CommonTools imageWithImage:[UIImage imageNamed:@"btn_search"] scaledToSize:CGSizeMake(25, 25)];
    
    CGFloat textFieldX = searchIcon.frame.origin.x + searchIcon.frame.size.width + 10;
    textField = [[UITextField alloc] initWithFrame:CGRectMake(textFieldX, 1, dismissSearchBarButton.frame.origin.x - textFieldX, toolBar.frame.size.height-2)];
    [textField setFont:[UIFont systemFontOfSize:14]];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.borderStyle = UITextBorderStyleNone;
    textField.placeholder = _(@"OFFLINE_SEARCH_HINT");
    textField.delegate = self;
    
    UIImageView *searchBg = [[UIImageView alloc] initWithFrame:CGRectMake(textField.frame.origin.x, searchIcon.frame.origin.y + searchIcon.frame.size.height + 5, dismissSearchBarButton.frame.origin.x + 35 - textField.frame.origin.x, 1)];
    searchBg.backgroundColor = [UIColor colorWithColorCodeString:@"FF1ba48a"];
    
    [toolBar addSubview:searchIcon];
    [toolBar addSubview:searchBg];
    [toolBar addSubview:textField];
    [toolBar addSubview:dismissSearchBarButton];
    
    CGFloat newTableViewY = toolBar.frame.origin.y + toolBar.frame.size.height;
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, newTableViewY, self.tableView.frame.size.width, self.tableView.frame.size.height - newTableViewY);
}

-(void)switchDeleteMode{
    if(editMode == NormalMode){
        editMode = DeleteMode;
        [selectedItems removeAllObjects];
        [self setDeletingNavigatinItem];
        self.tableView.allowsMultipleSelection = YES;
        [self.tableView reloadData];
    }else{
        [self setNormalNavigatinItem];
        editMode = NormalMode;
        [selectedItems removeAllObjects];
        self.tableView.allowsMultipleSelection = NO;
        [self.tableView reloadData];
    }
}

-(void)backBtnDidClick{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteClick {
    if (selectedItems.count == 0) {
        [self showWarningView];
        return;
    }
    
    NSString *info;
    NSMutableArray *dfiles = [NSMutableArray array];
    
    for (NotificationItem *file in selectedItems){
        [dfiles addObject:file];
        LogMessage(nil, 0, @"%@", file);
        info = NSLocalizedString(@"DELETE_FILE", nil);
    }
    
    StorageDeleteView *sview = nil;
    VIEW(sview, StorageDeleteView);
    sview.delegate = self;
    sview.files = dfiles;
    sview.infoLabel.text = info;
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:sview andAnimated:YES];
}

- (void)delete:(NSArray*)dfiles {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [items removeObjectsInArray:dfiles];
    
    NSMutableArray *notificationItems = [NSMutableArray array];
    for(NotificationItem *file in items){
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
        [dic setValue:file.title forKey:@"title"];
        [dic setValue:file.subtitle forKey:@"subtitle"];
        [dic setValue:file.message  forKey:@"message"];
        [dic setValue:file.date forKey:@"date"];
        
        [notificationItems addObject:dic];
    }
    [userDefault setObject:notificationItems forKey:@"Notification"];
    [userDefault synchronize];
    
    [self showWarnning:_(@"DELETE_ALERT")];
    [self clearSearchBarContent];
    [self switchDeleteMode];
}

- (void)showWarningView{
    StorageSelectWarningView *sview = nil;
    VIEW(sview, StorageSelectWarningView);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:sview andAnimated:YES];
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

#pragma mark Search relative
-(void)searchBehaviorWithString:(NSString*)substring{
    if([substring isEqualToString:@""]){
        searchActived = false;
    }else{
        searchActived = true;
        
    }
    [self searchAutocompleteEntriesWithSubstring:substring];
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    [autocompleteUrls removeAllObjects];
    
    [selectedItems removeAllObjects];
    
    if(!searchActived){
        for(NotificationItem* f in items) {
            [autocompleteUrls addObject:f];
        }
    }else{
        bool isTheStringDate = NO;
        isTheStringDate = [self isTheStringDate:substring];
        
        for(NotificationItem* f in items) {
            if(isTheStringDate){
                NSString* dateStr = [EnShareTools formatDate_yyyyMMdd:f.date];
//                NSString* dateStr = f.subtitle;
                if([dateStr isEqualToString:substring]){
                    [autocompleteUrls addObject:f];
                }
            }else{
                NSString *curStringForFileName = f.title;
                NSRange substringRangeForFileName = [curStringForFileName rangeOfString:substring options:NSCaseInsensitiveSearch];
                if (substringRangeForFileName.length > 0) {
                    [autocompleteUrls addObject:f];
                }
            }
        }
    }
    
    [self.tableView reloadData];
}

- (BOOL)isTheStringDate: (NSString*) theString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *dateFromString = [[NSDate alloc] init];
    
    dateFromString = [dateFormatter dateFromString:theString];
    
    if (dateFromString !=nil) {
        return true;
    }
    else {
        return false;
    }
}

-(void)clearSearchBarContent{
    if([textField.text isEqualToString:@""]){
        
    }else{
        textField.text = @"";
        [self searchBehaviorWithString:textField.text];
    }
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *substring = [NSString stringWithString:textField.text];
    substring = [substring stringByReplacingCharactersInRange:range withString:string];
    [self searchBehaviorWithString:substring];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark UITableViewDataSource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 52;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(searchActived){
        return autocompleteUrls.count;
    }else{
        return items.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* simpleTableIdentifier = @"NotificationCenterMainTableViewCell";
    NotificationCenterMainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if(cell == nil){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"NotificationCenterMainTableViewCell" owner:self options:nil] objectAtIndex:0];
    }
    
    NotificationItem* file;
    if(searchActived){
        NSLog(@"%ld",(long)indexPath.row);
        file = ((NotificationItem*)[autocompleteUrls objectAtIndex:indexPath.row]);
    }else{
        file = ((NotificationItem*)[items objectAtIndex:indexPath.row]);
    }
    
    if(editMode == DeleteMode){
        cell.checkboxButton.hidden = NO;
        cell.notificationView.frame = CGRectMake(cell.checkboxButton.frame.origin.x + cell.checkboxButton.frame.size.width, 0, cell.notificationView.frame.size.width, cell.notificationView.frame.size.height);
    }else{
        cell.checkboxButton.hidden = YES;
        cell.notificationView.frame = CGRectMake(8, 0, cell.notificationView.frame.size.width, cell.notificationView.frame.size.height);
    }
    
    cell.titleLabel.text = file.title;
    cell.dateLabel.text = file.subtitle;
    
    cell.messageLabel.text = file.message;
    [cell.messageLabel setNumberOfLines:1];
    [cell.messageLabel sizeToFit];
    cell.dateLabel.text = [EnShareTools formatDate_yyyyMMdd:file.date];
    [cell.dateLabel setNumberOfLines:1];
    
    if([selectedItems containsObject:file]){
        [cell.checkboxButton setSelected:YES];
    }else{
        [cell.checkboxButton setSelected:NO];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *useArray = nil;
    NotificationItem *item;
    if(searchActived){
        useArray = autocompleteUrls;
        item = autocompleteUrls[indexPath.row];
    }else{
        useArray = items;
        item = items[indexPath.row];
    }
    
    if(editMode != NormalMode){
        NotificationCenterMainTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if(cell.checkboxButton.isSelected){
            [selectedItems removeObject:item];
            [cell.checkboxButton setSelected:NO];
        }else{
            [selectedItems addObject:item];
            [cell.checkboxButton setSelected:YES];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }else {
        NotificationCenterViewController* noficationPage = [[NotificationCenterViewController alloc] initWithNibName:@"NotificationCenterViewController" bundle:nil];
        noficationPage.item = item;
        [self.navigationController pushViewController:noficationPage animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
