//
//  DocumentList.m
//  EnSmart
//
//  Created by Phil on 2015/8/19.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "DocumentListViewController.h"
#import "DataManager.h"
#import "PlayerViewController.h"
#import "KxVideoViewController.h"
#import "AZAPreviewController.h"
#import "AZAPreviewItem.h"
#import "KGModal.h"
#import "IR_Tools.h"
#import "SuccessView.h"
#import "CommonTools.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "MyFavoritesCollectionViewCell.h"
#import "CollectionDataFile.h"
#import "StorageDeleteView.h"
#import "StorageSelectWarningView.h"
#ifdef enshare
#import "SenaoGA.h"
#endif
//#import "UploadingViewController.h"
//#import "RouterGlobal.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "Masonry.h"
#import "FileTypeUtility.h"
#import <IRGallery/IRGallery.h>

typedef NS_ENUM(NSUInteger, EditMode) {
    NormalMode,
    DeleteMode,
    UploadMode,
    SearchMode
};

typedef NS_ENUM(NSUInteger, SortMode) {
    SortByNameMode,
    SortBySizeMode,
    SortByDateMode
};

@implementation DocumentListViewController{
    NSMutableArray *items;
    NSMutableArray *photos;
    NSMutableArray *favorites;
    NSMutableArray* selectedItems;
    
    AZAPreviewController *previewController;
    AZAPreviewItem *previewItem;
    
    NSMutableArray *autocompleteUrls;
    bool searchActived;
    
    int editMode;
    int sortMode;
    
    UIBarButtonItem *leftItem, *rightItem, *leftButtonForCancelDeleteMode, *rightButtonForDoDelete, *leftButtonForCancelUploadMode, *rightButtonForDoUpload;
    
    __weak IBOutlet UIView *tooBar;
    UIButton* deleteButton;
    UIButton* uploadButton;
    UIButton* searchButton;
    UIButton* dismissSearchBarButton;
    UIButton* cancelDeleteModeButton, *cancelUploadModeButton;
    UIButton* selectAllButton;
    UITextField* textField;
    UIImageView * searchBg;
    UIImageView* searchIcon;
    CGRect dismissSearchBarButtonFrame;
    CGRect dismissSearchBarButtonFrameWhenSelectAllButton;
    
    NSString *titleStr;
    
    bool isMyFavoritesListSlideDown;
    int offsetYOfMyFavoritesListSlideDown;
    
    NSOperationQueue *queue;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    autocompleteUrls = [NSMutableArray array];
    selectedItems = [NSMutableArray array];
    
    [self setNavigatinItem];
    [self setToolBar];
    
//    CGFloat newTableViewY = tooBar.frame.origin.y + tooBar.frame.size.height;
//    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, newTableViewY, self.tableView.frame.size.width, self.myFavoritesView.frame.origin.y - newTableViewY);
//    self.bgImageView.frame = self.tableView.frame;
#ifdef MESSHUDrive
    self.bgImageView.image = [UIImage imageNamed:@"bg_gray"];
#endif
    
    [self initMyFavorites];
    [self initSortMenu];
    
    self.myFavoritesTitleLabel.text = _(@"MY_FAVORITES_TITLE");
    
    self.sortByFileNameTitleLabel.text = _(@"SORT_BY_FILENAME_TITLE");
    self.sortByFileSizeTitleLabel.text = _(@"SORT_BY_FILE_SIZE_TITLE");
    self.sortByDateTitleLabel.text = _(@"SORT_BY_DATE_TITLE");
    [self.sortByFileNameTitleLabel sizeToFit];
    [self.sortByFileSizeTitleLabel sizeToFit];
    [self.sortByDateTitleLabel sizeToFit];
    
    self.sortByFileNameTypeLabel.text = _(@"SORT_BY_FILENAME_TYPE");
    self.sortByFileSizeTypeLabel.text = _(@"SORT_BY_FILE_SIZE_TYPE");
    self.sortByDateTypeLabel.text = _(@"SORT_BY_DATE_TYPE");
    
    queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 2;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.importFile) {
        CollectionDataFile *file = appDelegate.importFile;
        appDelegate.importFile = nil;
        
        [self openFile:file useArray:@[file]];
    }
}

//-(void)createGallery{
//    galleryVC = [[OnlineIRGalleryViewController alloc] initWithPhotoSource:self];
//    galleryVC.startingIndex = 0;
//    galleryVC.useThumbnailView = FALSE;
//    galleryVC.delegate = self;
//}

-(void)setNavigatinItem{
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = YES;
    UIView* leftview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
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
    backButtonFrame.origin.y = 5;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    [backButton setTitle:_(@"Back") forState:UIControlStateNormal];
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIButton* sortMenuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage *image = [UIImage imageNamed:@"btn_nav_sort"];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 24)];
#else
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(26.4, 24)];
#endif
    [sortMenuButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_nav_sort"];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 24)];
#else
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(26.4, 24)];
#endif
    [sortMenuButton setImage:image forState:UIControlStateHighlighted];
    [sortMenuButton addTarget:self action:@selector(menuBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:sortMenuButton];
    
    rightItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight, rightItem, nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    cancelDeleteModeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
    cancelDeleteModeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [cancelDeleteModeButton setTitle:_(@"Cancel") forState:UIControlStateNormal];
    [cancelDeleteModeButton addTarget:self action:@selector(switchDeleteMode) forControlEvents:UIControlEventTouchUpInside];
    leftButtonForCancelDeleteMode = [[UIBarButtonItem alloc] initWithCustomView:cancelDeleteModeButton];
    
    UIButton* doDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    image = [UIImage imageNamed:@"btn_trash"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_trash"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateHighlighted];
    [doDeleteButton addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
    rightButtonForDoDelete = [[UIBarButtonItem alloc] initWithCustomView:doDeleteButton];
    
    cancelUploadModeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
    cancelUploadModeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [cancelUploadModeButton setTitle:_(@"Cancel") forState:UIControlStateNormal];
    [cancelUploadModeButton addTarget:self action:@selector(switchUploadMode) forControlEvents:UIControlEventTouchUpInside];
    leftButtonForCancelUploadMode = [[UIBarButtonItem alloc] initWithCustomView:cancelUploadModeButton];
    
    UIButton* doUploadButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    image = [UIImage imageNamed:@"btn_upload_cloud"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(29.4, 25)];
    [doUploadButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_upload_cloud"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(29.4, 25)];
    [doUploadButton setImage:image forState:UIControlStateHighlighted];
    [doUploadButton addTarget:self action:@selector(uploadClick) forControlEvents:UIControlEventTouchUpInside];
    rightButtonForDoUpload = [[UIBarButtonItem alloc] initWithCustomView:doUploadButton];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setNormalNavigatinItem{
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,leftItem,nil];
    negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,rightItem,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setDeletingNavigatinItem{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = leftButtonForCancelDeleteMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoDelete,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setUploadingNavigatinItem{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = leftButtonForCancelUploadMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoUpload,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setToolBar{
//    tooBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, 50)];

    if (@available(iOS 11.0, *)) {
        [tooBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(tooBar.superview.mas_safeAreaLayoutGuideTop);
        }];
    }else{
        [tooBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_topLayoutGuide);
        }];
    }
    
#ifdef MESSHUDrive
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:ToolTitleBackgroundColor]];
#else
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:@"fff4f4f4"]];
#endif
//    [self.view addSubview:tooBar];
    
    deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    //    deleteButton.backgroundColor = [UIColor redColor];
    UIImage* image = [UIImage imageNamed:@"btn_trash"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(23, 30)];
    [deleteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_trash"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(23, 30)];
    [deleteButton setImage:image forState:UIControlStateHighlighted];
    
    uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
    
    image = [UIImage imageNamed:@"top_option_upload to storage_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [uploadButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"top_option_upload to storage_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [uploadButton setImage:image forState:UIControlStateHighlighted];
    
    searchButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 50, 50)];
    image = [UIImage imageNamed:@"btn_search"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [searchButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_search"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [searchButton setImage:image forState:UIControlStateHighlighted];
    [searchButton setContentMode:UIViewContentModeRight];
    
    [deleteButton addTarget:self action:@selector(switchDeleteMode) forControlEvents:UIControlEventTouchUpInside];
    [uploadButton addTarget:self action:@selector(switchUploadMode) forControlEvents:UIControlEventTouchUpInside];
    [searchButton addTarget:self action:@selector(switchSearchMode) forControlEvents:UIControlEventTouchUpInside];
    
    [self setNormalToobarItem];
    
    dismissSearchBarButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-50, 0, 50, 50)];
    image = [UIImage imageNamed:@"btn_search_cancle"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(15, 15)];
    [dismissSearchBarButton setImage:image forState:UIControlStateNormal];
    [dismissSearchBarButton setImage:image forState:UIControlStateHighlighted];
    [dismissSearchBarButton addTarget:self action:@selector(clearSearchBarContent) forControlEvents:UIControlEventTouchUpInside];
    
    selectAllButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 30, 50)];
    //    deleteButton.backgroundColor = [UIColor redColor];
    image = [UIImage imageNamed:@"btn_list_uncheck.png"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 20)];
    [selectAllButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_list_check.png"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 20)];
    [selectAllButton setImage:image forState:UIControlStateSelected];
    [selectAllButton addTarget:self action:@selector(selectAllItemButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    dismissSearchBarButtonFrame = dismissSearchBarButton.frame;
    dismissSearchBarButtonFrameWhenSelectAllButton = dismissSearchBarButton.frame;
    dismissSearchBarButtonFrameWhenSelectAllButton.origin.x = dismissSearchBarButton.frame.origin.x - selectAllButton.frame.size.width;
}

-(void)setNormalToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar addSubview:deleteButton];
    [tooBar addSubview:uploadButton];
    [tooBar addSubview:searchButton];
}

-(void)setDeletingToobarItem{
    [self showSearchBarWithSelectAllButton:YES];
}

-(void)setUploadingToobarItem{
    [self showSearchBarWithSelectAllButton:YES];
}

-(void)setSearchingToobarItemWithSelectAllButton:(BOOL)withSelectAllButton{
//    for (UIView *subview in [tooBar subviews]) {
//        [[subview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    }
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGRect searchBarViewFrmae = CGRectZero;
    if (withSelectAllButton) {
        [tooBar addSubview:selectAllButton];
        CGFloat searchBarViewStartX = selectAllButton.frame.size.width;
        searchBarViewFrmae = CGRectMake(searchBarViewStartX, 0, tooBar.frame.size.width - searchBarViewStartX, tooBar.frame.size.height);
    } else {
        searchBarViewFrmae = CGRectMake(0, 0, tooBar.frame.size.width, tooBar.frame.size.height);
        searchBarViewFrmae = searchBarViewFrmae;
    }
    UIView *view = [[UIView alloc] initWithFrame:searchBarViewFrmae];
    [view addSubview:searchIcon];
    [view addSubview:searchBg];
    [view addSubview:textField];
    [view addSubview:dismissSearchBarButton];
    [tooBar addSubview:view];
}

-(void)showSearchBarWithSelectAllButton:(BOOL)withSelectAllButton{
    if(textField!=nil){
        textField.text = @"";
        [self searchBehaviorWithString:textField.text];
        
        [textField removeFromSuperview];
        textField = nil;
        return;
    }
    
    searchActived = true;
    [self searchBehaviorWithString:@""];
    
    if (withSelectAllButton) {
        dismissSearchBarButton.frame = dismissSearchBarButtonFrameWhenSelectAllButton;
    } else {
        dismissSearchBarButton.frame = dismissSearchBarButtonFrame;
    }
    
    searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(searchButton.frame.size.width/2 - 20/2, searchButton.frame.size.height/2 - 20/2, 25, 25)];
    searchIcon.image = [UIImage imageNamed:@"btn_search"];
    
    CGFloat textFieldX = searchIcon.frame.origin.x + searchIcon.frame.size.width + 10;
    textField = [[UITextField alloc] initWithFrame:CGRectMake(textFieldX, 1, dismissSearchBarButton.frame.origin.x - textFieldX, tooBar.frame.size.height-2)];
    [textField setFont:[UIFont systemFontOfSize:14]];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.borderStyle = UITextBorderStyleNone;
    textField.placeholder = _(@"OFFLINE_SEARCH_HINT");
    textField.delegate = self;
    if(editMode == SearchMode)
        [textField becomeFirstResponder];

    searchBg = [[UIImageView alloc] initWithFrame:CGRectMake(textField.frame.origin.x, searchIcon.frame.origin.y + searchIcon.frame.size.height + 5, dismissSearchBarButton.frame.origin.x + 35 - textField.frame.origin.x, 1)];
#ifdef MESSHUDrive
    searchBg.backgroundColor = [UIColor whiteColor];
    [textField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName : [UIColor groupTableViewBackgroundColor]}]];
    [textField setTintColor:[UIColor colorWithRGB:0xCC0000]];
    [textField setTextColor:[UIColor whiteColor]];
#else
    searchBg.backgroundColor = [UIColor colorWithColorCodeString:@"FF1ba48a"];
#endif
    [self setSearchingToobarItemWithSelectAllButton:withSelectAllButton];
}

-(void)searchBehaviorWithString:(NSString*)substring{
    if([substring isEqualToString:@""]){
        searchActived = false;
    }else{
        searchActived = true;
        
    }
    [self searchAutocompleteEntriesWithSubstring:substring];
}

-(void)clearSearchBarContent{
    if(textField!=nil){
        if([textField.text isEqualToString:@""]){
            if(editMode==SearchMode){
                [self switchSearchMode];
            }
        }else{
            textField.text = @"";
            [self searchBehaviorWithString:textField.text];
        }
    }
}

-(void)dismissSearchBar{
    if(textField!=nil){
        self.navigationController.navigationBar.translucent = YES;
        [searchBg removeFromSuperview];
        
        searchActived = false;
        textField.text = @"";
        [self searchBehaviorWithString:textField.text];
        
        [textField removeFromSuperview];
        textField = nil;
        
        [self setNormalToobarItem];
        return;
    }
}

-(void)initSortMenu{
    [self.sortMenuView setBackgroundColor:[UIColor colorWithColorCodeString:@"AAAAAAAA"]];
//    self.sortSelectView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.sortSelectView.frame.size.width, self.sortSelectView.frame.size.height);
    
    UIImage* image = [UIImage imageNamed:@"icn_sort_name"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
    [self.sortByNameButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"icn_sort_name"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
    [self.sortByNameButton setImage:image forState:UIControlStateHighlighted];
    
    image = [UIImage imageNamed:@"icn_sort_size"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
    [self.sortBySizeButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"icn_sort_size"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
    [self.sortBySizeButton setImage:image forState:UIControlStateHighlighted];
    
    image = [UIImage imageNamed:@"icn_sort_date"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
    [self.sortByDateButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"icn_sort_date"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
    [self.sortByDateButton setImage:image forState:UIControlStateHighlighted];
}

- (IBAction)myFavoritesViewClick:(id)sender {
    self.myFavoritesView.userInteractionEnabled = NO;
    CGFloat constraintValue;
    
    if(!isMyFavoritesListSlideDown){
        isMyFavoritesListSlideDown = true;
        constraintValue = -offsetYOfMyFavoritesListSlideDown;
//        newFrame = CGRectMake(self.myFavoritesView.frame.origin.x, self.myFavoritesView.frame.origin.y + offsetYOfMyFavoritesListSlideDown, self.myFavoritesView.frame.size.width, self.myFavoritesView.frame.size.height);
//        //        [self.navigationController setNavigationBarHidden:NO animated:YES];
//        newTableViewFrame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height + offsetYOfMyFavoritesListSlideDown );
    }else{
        isMyFavoritesListSlideDown = false;
        constraintValue = 0;
//        newFrame = CGRectMake(self.myFavoritesView.frame.origin.x, self.myFavoritesView.frame.origin.y - offsetYOfMyFavoritesListSlideDown, self.myFavoritesView.frame.size.width, self.myFavoritesView.frame.size.height);
//        newTableViewFrame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height - offsetYOfMyFavoritesListSlideDown );
        //        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    
    [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.myFavoritesViewBottomConstraint.constant = constraintValue;
        [self.myFavoritesView.superview layoutIfNeeded];
//        self.myFavoritesView.frame = newFrame;
//        self.tableView.frame = newTableViewFrame;
//        self.bgImageView.frame = self.tableView.frame;
    } completion:^(BOOL finished) {
        self.myFavoritesView.userInteractionEnabled = YES;
    }];
}

-(void)startAnimating{
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.loadingView.hidden = NO;
    rightButtonForDoUpload.enabled = NO;
}

-(void)stopAnimating{
    [self.loadingView stopAnimating];
    [self.view setUserInteractionEnabled:YES];
    self.loadingView.hidden = YES;
    rightButtonForDoUpload.enabled = YES;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if(offsetYOfMyFavoritesListSlideDown==0){
        offsetYOfMyFavoritesListSlideDown = ([UIScreen mainScreen].bounds.size.height - self.myFavoritesView.frame.origin.y) - self.myFavoritesCollectionView.frame.origin.y;
        
//        self.myFavoritesView.frame = CGRectMake(self.myFavoritesView.frame.origin.x, self.myFavoritesView.frame.origin.y + offsetYOfMyFavoritesListSlideDown, self.myFavoritesView.frame.size.width, self.myFavoritesView.frame.size.height);
        self.myFavoritesViewBottomConstraint.constant = -offsetYOfMyFavoritesListSlideDown;
//        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height + offsetYOfMyFavoritesListSlideDown );
//        self.bgImageView.frame = self.tableView.frame;
        isMyFavoritesListSlideDown = true;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    self.navigationItem.title = titleStr;
    [self.navigationController setNavigationBarHidden:NO];
    [self registerForKeyboardNotifications];
    [self loadData];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //設定通知對應的函數
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(notificationHandle:)
                                                 name: @"ReloadNotificationHandle"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    NSLog(@"remove-notificationHandle");
    //移除通知對應函數
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

//當通知發生時會執行此函數
- (void) notificationHandle: (NSNotification*) sender;
{
    NSLog(@"-notificationHandle");
    [self loadData];
}

-(NSString*)getFileTypeString:(FILE_TYPE)type{
    NSString* fileTypeString = nil;
    switch (type) {
        case DOCUMENT_TYPE:
            fileTypeString = @"DOCUMENT";
            break;
        case MUSIC_TYPE:
            fileTypeString = @"MUSIC";
            break;
        case VIDEO_TYPE:
            fileTypeString = @"VIDEO";
            break;
        case PHOTO_TYPE:
            fileTypeString = @"PICTURE";
            break;
        default:
            break;
    }
    
    return fileTypeString;
}

-(void)loadData{
    NSString* fileTypeString = [self getFileTypeString:self.fileType];
    
    items = [NSMutableArray array];
    photos = [NSMutableArray array];
    favorites = [NSMutableArray array];
    [self removeSelectedItems];
    
    NSArray* readFromDB = nil;
    if(self.fileType == ALL_TYPE){
        readFromDB = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Collection WHERE isfolder = '%@'; ", @"0"]];
    }else{
        readFromDB = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Collection WHERE type = '%@' AND isfolder = '%@'; ", fileTypeString, @"0"]];
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    for(NSDictionary* dic in readFromDB){
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:dic[@"filename"]];
        CollectionDataFile* file = [[CollectionDataFile alloc] initWithDatabaseNSDictionary:dic fileSize:[IR_Tools getFileSize:filePath] fileCreatedDate:[IR_Tools getFileCreationTimeFromPath:filePath]];
        [items addObject:file];
    }
    
    if(self.fileType == ALL_TYPE){
        readFromDB = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Collection WHERE type = 'PICTURE' AND parentfolder = '%@' ORDER BY isfolder DESC; ", @"/"]];
        for(NSDictionary* dic in readFromDB){
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:dic[@"filename"]];
            CollectionDataFile* file = [[CollectionDataFile alloc] initWithDatabaseNSDictionary:dic fileSize:[IR_Tools getFileSize:filePath] fileCreatedDate:[IR_Tools getFileCreationTimeFromPath:filePath]];
            [photos addObject:file];
        }
    }
    
    for(CollectionDataFile* file in items){
        if([file.addfavoritetime intValue]!=0)
            [favorites addObject:file];
    }
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"addfavoritetime" ascending:YES];
    [favorites sortUsingDescriptors:[NSArray arrayWithObject:sorter]];

    
    switch (sortMode) {
        case SortByNameMode:
            [self sortByNameClick:nil];
            break;
        case SortBySizeMode:
            [self sortBySizeClick:nil];
            break;
        case SortByDateMode:
            [self sortByDateClick:nil];
            break;
    }
    
    [self.tableView reloadData];
    [self.myFavoritesCollectionView reloadData];
}

#pragma mark - SortAction

-(void)menuBtnDidClick{
    if(self.sortMenuView.superview){
        [self.sortMenuView removeFromSuperview];
    }else{
        [self.view addSubview:self.sortMenuView];
        [self.sortMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.sortMenuView.superview);
        }];
        if (@available(iOS 11.0, *)) {
            [self.sortSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.sortSelectView.superview.mas_safeAreaLayoutGuideTop);
            }];
        }else{
            [self.sortSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.mas_topLayoutGuide);
            }];
        }
    }
}

- (IBAction)sortByNameClick:(id)sender {
    sortMode = SortByNameMode;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [items sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [photos sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [self.tableView reloadData];
    [self sortMenuBGClick:nil];
}

- (IBAction)sortBySizeClick:(id)sender {
    sortMode = SortBySizeMode;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"size" ascending:YES];
    [items sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [photos sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [self.tableView reloadData];
    [self sortMenuBGClick:nil];
}

- (IBAction)sortByDateClick:(id)sender {
    sortMode = SortByDateMode;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"createTime" ascending:NO];
    [items sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [photos sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [self.tableView reloadData];
    [self sortMenuBGClick:nil];
}

- (IBAction)sortMenuBGClick:(id)sender {
    [self.sortMenuView removeFromSuperview];
}

#pragma mark - MyFavoritesUICollectionView

static NSString* myFavoritesCellIdentifier = @"MyFavoritesCell";

-(void)initMyFavorites{
    [self.myFavoritesCollectionView registerNib:[UINib nibWithNibName:@"MyFavoritesCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:myFavoritesCellIdentifier];
    self.myFavoritesCollectionView.backgroundColor = [UIColor whiteColor];
    self.myFavoritesCollectionView.showsHorizontalScrollIndicator = NO;
    ((UICollectionViewFlowLayout *)self.myFavoritesCollectionView.collectionViewLayout).minimumInteritemSpacing = CGFLOAT_MAX;
    
    [self.viewInTopOfMyFavorites setBackgroundColor:[UIColor colorWithColorCodeString:@"fff4f4f4"]];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return favorites.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MyFavoritesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:myFavoritesCellIdentifier forIndexPath:indexPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:((CollectionDataFile*)favorites[indexPath.row]).name];
    
    cell.filenameLabel.text = ((CollectionDataFile*)favorites[indexPath.row]).name;
    
    if(self.fileType == VIDEO_TYPE){
        [self setThumbToFavoritesCell:cell byVideoPath:filePath];
    }else if(self.fileType == MUSIC_TYPE){
        cell.imageViewe.image = [IR_Tools getMusicCover:filePath];
        if(cell.imageViewe.image==nil)
            cell.imageViewe.image = [FileTypeUtility getImageOfflineWithType:@"MUSIC" ext:[cell.filenameLabel.text pathExtension]];
    }else if(self.fileType == DOCUMENT_TYPE){
        cell.imageViewe.image = [FileTypeUtility getImageOfflineWithType:@"DOCUMENT" ext:[cell.filenameLabel.text pathExtension]];
    }else if(self.fileType == PHOTO_TYPE){
        
    }else if(self.fileType == ALL_TYPE){
        NSString *type = [[DataManager sharedInstance] getType:[filePath pathExtension]];
        if([type isEqualToString:@"VIDEO"]){
            [self setThumbToFavoritesCell:cell byVideoPath:filePath];
        }else if([type isEqualToString:@"MUSIC"]){
            cell.imageViewe.image = [IR_Tools getMusicCover:filePath];
            if(cell.imageViewe.image==nil)
                cell.imageViewe.image = [FileTypeUtility getImageOfflineWithType:@"MUSIC" ext:[cell.filenameLabel.text pathExtension]];
        }else if([type isEqualToString:@"PICTURE"]){
            cell.imageViewe.image = [UIImage imageNamed:@"img_photo.jpg"];
            
            @autoreleasepool {
                [cell.imageViewe sd_setImageWithURL:[NSURL fileURLWithPath:filePath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"]  options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    
                }];
            }
        }else {
            cell.imageViewe.image = [FileTypeUtility getImageOfflineWithType:type ext:[cell.filenameLabel.text pathExtension]];
        }
    }
    
    return cell;
}

-(void)setThumbToFavoritesCell:(MyFavoritesCollectionViewCell*)cell byVideoPath:(NSString*)filePath{
    if(!cell.operation){
        [cell.operation cancel];
    }
    
    cell.imageViewe.image = [FileTypeUtility getImageOfflineWithType:@"VIDEO" ext:[cell.filenameLabel.text pathExtension]];
    
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *image = [IR_Tools generateThumbImage:filePath];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            cell.imageViewe.image = image;
            if(cell.imageViewe.image==nil)
                cell.imageViewe.image = [FileTypeUtility getImageOfflineWithType:@"VIDEO" ext:[cell.filenameLabel.text pathExtension]];
        }];
    }];
    
    cell.operation = operation;
    
    [queue addOperation:operation];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self openFile:favorites[indexPath.row] useArray:favorites];
}

//加入最愛
- (void)starClk:(NSNumber*)enable file:(CollectionDataFile*)file {
    NSString* favoriteTime;
    if ([enable boolValue] == TRUE) {
        [favorites addObject:file];
        favoriteTime = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
        
        [self.myFavoritesCollectionView reloadData];
        //        [self.myFavoritesCollectionView reloadDataWithCompletion:^{
        NSInteger section = [self.myFavoritesCollectionView numberOfSections] - 1;
        NSInteger item = [self.myFavoritesCollectionView numberOfItemsInSection:section] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [self.myFavoritesCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
        //        }];
        
    } else {
        [favorites removeObject:file];
        favoriteTime = @"0";
        
        [self.myFavoritesCollectionView reloadData];
        NSInteger section = [self.myFavoritesCollectionView numberOfSections] - 1;
        NSInteger item = [self.myFavoritesCollectionView numberOfItemsInSection:section] - 1;
        if(section>=0 && item>=0){
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            [self.myFavoritesCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
        }
    }
    
    [[DataManager sharedInstance].database sqliteUpdate:@"Collection" keys:@ {
        @"filename" : [file.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        @"isfolder" : @"0",
    } params:@ {
        @"addfavoritetime" : favoriteTime,
    }];
}

-(void)deleteMyFavoritefile:(CollectionDataFile*)file {
    if([favorites indexOfObject: file ]<[favorites count]){
        [favorites removeObject: file ];
    }
}

#pragma mark - ToolBarBehavior

- (void)delete:(NSArray*)dfiles {
    for (CollectionDataFile *file in dfiles) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *file1 = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:file1 error:nil];
        
        [[DataManager sharedInstance].database sqliteDelete:@"Collection" keys:@ {
            @"uid" : file.uid,
        }];
        
        [self deleteMyFavoritefile:file];
    }
    
    [self showWarnning:_(@"DELETE_ALERT")];
    [self switchDeleteMode];
    
    [self loadData];
}

- (void)deleteByFiles:(NSArray*)dfiles {
    for (NSString *file_ in dfiles) {
        NSString *file = file_.pathComponents[file_.pathComponents.count - 1];
        for (CollectionDataFile *item in photos) {
            if ([file isEqualToString:item.name]) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:file_ error:nil];
                [[DataManager sharedInstance].database sqliteDelete:@"Collection" keys:@ {
                    @"uid" : item.uid,
                }];
                
                [self deleteMyFavoritefile:item];
                break;
            }
        }
    }
    
    [self showWarnning:_(@"DELETE_ALERT")];
    
    [self loadData];
}

- (void)selectAllItem:(BOOL)selectAll {
    if (selectAll) {
        if(searchActived){
            selectedItems = [NSMutableArray arrayWithArray:autocompleteUrls];
        }else{
            selectedItems = [NSMutableArray arrayWithArray:items];
        }
    } else {
        [selectedItems removeAllObjects];
    }
}

- (void)checkSelectAllItemButtonStatus {
    BOOL selectedAll = NO;
    if ([selectedItems count] > 0) {
        if(searchActived){
            selectedAll = ([selectedItems count] == [autocompleteUrls count]);
        }else{
            selectedAll = ([selectedItems count] == [items count]);
        }
    }

    selectAllButton.selected = selectedAll;
}

- (void)selectAllItemButtonClick:(UIButton*)sender {
    sender.selected = !sender.isSelected;
    
    [self selectAllItem:sender.isSelected];
    self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(searchActived){
        return autocompleteUrls.count;
    }else{
        return items.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* simpleTableIdentifier = @"Simple";
    DocumentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if(cell == nil){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"DocumentTableViewCell" owner:self options:nil] objectAtIndex:0];
    }
    
    CollectionDataFile* file;
    if(searchActived){
        NSLog(@"%ld",(long)indexPath.row);
        file = ((CollectionDataFile*)[autocompleteUrls objectAtIndex:indexPath.row]);
    }else{
        file = ((CollectionDataFile*)[items objectAtIndex:indexPath.row]);
    }
    
    if(editMode == DeleteMode || editMode == UploadMode){
        [cell changeToSelectedMode:YES];
    }else{
        [cell changeToSelectedMode:NO];
    }
    
    cell.titleLabel.text = file.name;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
    
    if(self.fileType == VIDEO_TYPE){
        [self setThumbToCell:cell byVideoPath:filePath];
    }else if(self.fileType == MUSIC_TYPE){
        cell.thumbnailImageView.image = [IR_Tools getMusicCover:filePath];
        if(cell.thumbnailImageView.image==nil)
            cell.thumbnailImageView.image = [FileTypeUtility getImageOfflineWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
    }else if(self.fileType == DOCUMENT_TYPE){
        cell.thumbnailImageView.image = [FileTypeUtility getImageOfflineWithType:@"DOCUMENT" ext:[cell.titleLabel.text pathExtension]];
    }else if(self.fileType == PHOTO_TYPE){
        
    }else if(self.fileType == ALL_TYPE){
        if([file.type isEqualToString:@"VIDEO"]){
            [self setThumbToCell:cell byVideoPath:filePath];
        }else if([file.type isEqualToString:@"MUSIC"]){
            if(cell.thumbnailImageView.image==nil)
                cell.thumbnailImageView.image = [FileTypeUtility getImageOfflineWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
        }else if([file.type isEqualToString:@"PICTURE"]){
            cell.thumbnailImageView.image = [UIImage imageNamed:@"img_photo.jpg"];
            @autoreleasepool {
                [cell.thumbnailImageView sd_setImageWithURL:[NSURL fileURLWithPath:filePath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"]  options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    
                }];
            }
        }else {
            cell.thumbnailImageView.image = [FileTypeUtility getImageOfflineWithType:file.type ext:[cell.titleLabel.text pathExtension]];
        }
    }
    
    cell.fileSizeLabel.text = [[IR_Tools transformedValue:file.size] stringByAppendingString:@", "];
    [cell.fileSizeLabel setNumberOfLines:1];
    [cell.fileSizeLabel sizeToFit];
    CGRect newFrame = cell.createDateLabel.frame;
    newFrame.origin.x = cell.fileSizeLabel.frame.origin.x + cell.fileSizeLabel.frame.size.width;
    cell.createDateLabel.frame = newFrame;
    cell.createDateLabel.text = [IR_Tools formatDate_yyyyMMdd:[IR_Tools getFileCreationTimeFromPath:filePath]];
    [cell.createDateLabel setNumberOfLines:1];
    [cell.createDateLabel sizeToFit];
    
    cell.favoriteButton.selected = NO;
    for(CollectionDataFile *favoritesFile in favorites){
        if([favoritesFile.name isEqualToString:file.name]){
            cell.favoriteButton.selected = YES;
            break;
        }
    }
    
    cell.delegate = self;
    
    if([selectedItems containsObject:file]){
        [cell.checkboxButton setSelected:YES];
    }else{
        [cell.checkboxButton setSelected:NO];
    }
    
    cell.file = file;
    
    return cell;
}

-(void)setThumbToCell:(DocumentTableViewCell*)cell byVideoPath:(NSString*)filePath{
    if(!cell.operation){
        [cell.operation cancel];
    }
    
    cell.thumbnailImageView.image = [FileTypeUtility getImageOfflineWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
    
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *image = [IR_Tools generateThumbImage:filePath];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            cell.thumbnailImageView.image = image;
            if(cell.thumbnailImageView.image==nil)
                cell.thumbnailImageView.image = [FileTypeUtility getImageOfflineWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
        }];
    }];
    
    cell.operation = operation;
    
    [queue addOperation:operation];
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    DocumentTableViewCell *docCell = (DocumentTableViewCell*)cell;
    if(!docCell.operation){
        [docCell.operation cancel];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *useArray = nil;
    CollectionDataFile *item;
    if(searchActived){
        useArray = autocompleteUrls;
        item = autocompleteUrls[indexPath.row];
    }else{
        useArray = items;
        item = items[indexPath.row];
    }
    
    if(editMode != NormalMode && editMode!=SearchMode){
        DocumentTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if(cell.checkboxButton.isSelected){
            [selectedItems removeObject:item];
            [cell.checkboxButton setSelected:NO];
        }else{
            [selectedItems addObject:item];
            [cell.checkboxButton setSelected:YES];
        }
        
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [self checkSelectAllItemButtonStatus];
    }else {
        [self openFile:item useArray:useArray];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(void)openFile:(CollectionDataFile*)item useArray:(NSArray*)useArray{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"type %@",[item valueForKey:@"type"]);
    //    NSLog(@"type %@",[item objectForKeyedSubscript:@"type"]);
    if ([item.type isEqualToString:@"MUSIC"]) {
        // 播放元件
        
        PlayerViewController *playerViewController = [[PlayerViewController alloc] init];
        playerViewController.delegate = self;
        
        int c=0;
        for (CollectionDataFile *dict in useArray) {
            NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:dict.name];
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:file, @"musicAddress", dict.name, @"musicName", nil];
            [playerViewController.musicListArray addObject:dictionary];
            if ([dict.name isEqualToString:item.name]) {
                playerViewController.musicLocation = c;
            }
            c++;
        }
        
        [self presentViewController:playerViewController animated:YES completion:nil];
    } else if ([item.type isEqualToString:@"VIDEO"]) {
        int c = 0, videoPosition = 0;
        NSMutableArray *videoArray = [[NSMutableArray alloc] init];
        for (CollectionDataFile *dict in useArray) {
            if ([[dict.name lowercaseString] rangeOfString:@".mov"].length>0 || [[dict.name lowercaseString] rangeOfString:@".avi"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".mp4"].length>0 || [[dict.name lowercaseString] rangeOfString:@".3gp"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".m4v"].length>0 || [[dict.name lowercaseString] rangeOfString:@".mkv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".wmv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".asf"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".dv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".vob"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".mpg"].length>0) {
                
                NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:dict.name];
                [videoArray addObject:file];
                //                LogMessage(nil, 0, @"file %@", file);
                
                if ([dict.name isEqualToString:item.name]) {
                    videoPosition = c;
                }
                c++;
            }
        }
        
        KxVideoViewController *videoViewController = [KxVideoViewController kxVideoInitWithContentPathFromLocal:videoArray videoPosition:videoPosition];
        videoViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:videoViewController];
        navigationController.navigationBar.barStyle = UIBarStyleBlack;
        navigationController.navigationBarHidden = YES;
        [self presentViewController:navigationController animated:YES completion:nil];
        
    } else if ([item.type isEqualToString:@"PICTURE"]) {
        int idx = 0;
        for (CollectionDataFile *photo in photos) {
            if ([photo.name isEqualToString:item.name])
                break;
            idx++;
        }
        IRGalleryViewController *galleryVC = [[IRGalleryViewController alloc] initWithPhotoSource:self];
        galleryVC.startingIndex = idx;
        galleryVC.useThumbnailView = FALSE;
        galleryVC.delegate = self;
        [galleryVC gotoImageByIndex:idx animated:NO];
        [self.navigationController pushViewController:galleryVC animated:YES];
    } else if ([item.type isEqualToString:@"DOCUMENT"]) {
        // 預覽
        NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:item.name];
        previewItem = [AZAPreviewItem previewItemWithURL:[NSURL fileURLWithPath:file] title:[[file pathComponents] lastObject]];
        previewController = [[AZAPreviewController alloc] init];
        previewController.dataSource = self;
        previewController.delegate = self;
        [self presentViewController:previewController animated:YES completion:nil];
    }
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

- (void)removeSelectedItems {
    [selectedItems removeAllObjects];
    [self selectAllItem:NO];
    [self checkSelectAllItemButtonStatus];
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    [autocompleteUrls removeAllObjects];

    [self removeSelectedItems];
    
    if(editMode != NormalMode  && editMode != SearchMode)
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
        
    if(!searchActived){
        for(CollectionDataFile* f in items) {
            [autocompleteUrls addObject:f];
        }
    }else{
        bool isTheStringDate = NO;
        isTheStringDate = [self isTheStringDate:substring];
        
        for(CollectionDataFile* f in items) {
            if(isTheStringDate){
                NSString* dateStr = [IR_Tools formatDate_yyyyMMdd:f.createTime];
                if([dateStr isEqualToString:substring]){
                    [autocompleteUrls addObject:f];
                }
            }else{
                NSString *curStringForFileName = f.name;
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

#pragma mark UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *substring = [NSString stringWithString:textField.text];
    substring = [substring stringByReplacingCharactersInRange:range withString:string];
    [self searchBehaviorWithString:substring];
    return YES;
}

//To avoid crash issue, because action(delete:) send message to delete:(NSArray*) that is use for file delete, not for TextField! By Phil 2017/08/15
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];
    if(canPerformAction && action == @selector(delete:))
        return NO;
    return canPerformAction;
}

#pragma mark - OfflineIRGalleryViewControllerDelegate Methods

- (int)numberOfPhotosForPhotoGallery:(IRGalleryViewController *)gallery {
    return photos.count;
}

- (IRGalleryPhotoSourceType)photoGallery:(IRGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    return IRGalleryPhotoSourceTypeLocal;
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index {
    NSString *filename = [NSString stringWithFormat:@"%@", ((CollectionDataFile*)photos[index]).name];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery urlForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index {
    NSString *filename = [NSString stringWithFormat:@"%@", photos[index]];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery filePathForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *str = [[paths objectAtIndex:0] stringByAppendingPathComponent:[photos[index] valueForKey:@"name"]];
    return str;
}

- (bool)photoGallery:(IRGalleryViewController *)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index{
    CollectionDataFile* file;
    file = ((CollectionDataFile*)photos[index]);
    
    for(CollectionDataFile *favoritesFile in favorites){
        if([favoritesFile.name isEqualToString:file.name]){
            return YES;
        }
    }
    
    return NO;
}

- (void)photoGallery:(IRGalleryViewController *)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index{
    CollectionDataFile* file;
    file = ((CollectionDataFile*)photos[index]);
    
    [self starClk:@(isAddToFavortieList) file:file];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    return previewItem;
}

#pragma mark - AZAPreviewControllerDelegate

- (void)AZA_previewController:(AZAPreviewController *)controller failedToLoadRemotePreviewItem:(id<QLPreviewItem>)previewItem withError:(NSError *)error{
}

#pragma mark - KxVideoCallBackDelegate
-(void)didVideoPlay:(NSString *)path{
    [self increaseCountByFilePath:path];
}

#pragma mark - PlayerViewCallBackDelegate
-(void)didMusicChange:(NSString *)path{
    [self increaseCountByFilePath:path];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)increaseCountByFilePath:(NSString*)path{
    for(int i = 0; i < items.count; i++){
        CollectionDataFile* file = items[i];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
        if([filePath isEqualToString:path]){
//            [manager increaseCountByFileName:file.name];
            break;
        }
    }
}

-(void)backBtnDidClick{
    if(editMode == SearchMode){
        [self switchSearchMode];
    }else{
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(void)switchDeleteMode{
    if(editMode == NormalMode){
        editMode = DeleteMode;

        [self setDeletingToobarItem];
        [self setDeletingNavigatinItem];
        
        self.tableView.allowsMultipleSelection = YES;
        
        [self.tableView reloadData];
        
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    }else{
        [self dismissSearchBar];
        editMode = NormalMode;
        self.tableView.allowsMultipleSelection = NO;
        [self changeToNormalMode];
        
        self.navigationItem.title = titleStr;
    }
}

-(void)switchSearchMode{
    if(editMode == NormalMode){
        editMode = SearchMode;
        
        ((UIButton*)self.navigationItem.rightBarButtonItems.lastObject.customView).enabled = NO;
        [self showSearchBarWithSelectAllButton:NO];
    }else{
        editMode = NormalMode;
        ((UIButton*)self.navigationItem.rightBarButtonItems.lastObject.customView).enabled = YES;
        [self dismissSearchBar];
        
    }
}

-(void)changeToNormalMode{
    [self setNormalToobarItem];
    [self setNormalNavigatinItem];
    searchButton.hidden = NO;
    [self cancelClick];
}

- (void)cancelClick{
    [self removeSelectedItems];
    editMode = NormalMode;
    [self.tableView reloadData];
    
    self.tableView.allowsMultipleSelection = NO;
}

- (void)deleteClick {
    if (selectedItems.count == 0) {
        [self showWarningView];
        return;
    }
    
    NSString *info;
    NSMutableArray *dfiles = [NSMutableArray array];

    for (CollectionDataFile *file in selectedItems){
        [dfiles addObject:file];
        info = NSLocalizedString(@"DELETE_FILE", nil);
    }
    
    StorageDeleteView *sview = nil;
    VIEW(sview, StorageDeleteView);
    sview.delegate = self;
    sview.files = dfiles;
    sview.infoLabel.text = info;
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:sview andAnimated:YES];
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"CollectionPage_Edit-Delete" Label:nil Value:nil];
#endif
}

-(void)switchUploadMode{
    if(editMode == NormalMode){
        editMode = UploadMode;
        
        [self setUploadingToobarItem];
        [self setUploadingNavigatinItem];
        
        self.tableView.allowsMultipleSelection = YES;
        [self.tableView reloadData];
        
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    }else{
        [self dismissSearchBar];
        editMode = NormalMode;
        self.tableView.allowsMultipleSelection = NO;
        [self changeToNormalMode];
        
        self.navigationItem.title = titleStr;
    }
}

- (void)showWarningView{
    StorageSelectWarningView *sview = nil;
    VIEW(sview, StorageSelectWarningView);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:sview andAnimated:YES];
}

-(void)setFileType:(FILE_TYPE)fileType{
    self->_fileType = fileType;
    
    switch (fileType) {
        case DOCUMENT_TYPE:
            titleStr = _(@"Documents List");
            break;
        case VIDEO_TYPE:
            titleStr = _(@"Videos List");
            break;
        case PHOTO_TYPE:
            titleStr = _(@"Photos List");
            break;
        case MUSIC_TYPE:
            titleStr = _(@"Musics List");
            break;
        case ALL_TYPE:
            titleStr = _(@"Files List");
            break;
    }
    
    self.navigationItem.title = titleStr;
}

#pragma mark - KeyboardNotifications

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat tableViewBottom = self.tableView.frame.origin.y + self.tableView.frame.size.height;
    CGFloat offsetY = kbSize.height - (self.view.frame.size.height - tableViewBottom);
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, offsetY, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, textField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, textField.frame.origin.y-kbSize.height);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

@end
