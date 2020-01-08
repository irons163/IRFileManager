//
//  DocumentList.m
//  EnSmart
//
//  Created by Phil on 2015/8/19.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "DocumentListViewController_online.h"

#import "PlayerViewController.h"
#import "KxVideoViewController.h"
#import "OnlineFGalleryViewController.h"
#import "AZAPreviewController.h"
#import "AZAPreviewItem.h"
//#import "File.h"

#import "EnShareTools.h"
#import "CommonTools.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "MyFavoritesCollectionViewCell.h"

#import "StorageDeleteView.h"
#import "StorageSelectWarningView.h"
#ifdef enshare
#import "SenaoGA.h"
#endif

#import "UploadingViewController.h"
#import "RouterGlobal.h"
#import "DocumentTableViewCell_online.h"

#import "UIImageView+WebCache.h"
#import "Masonry.h"


typedef NS_ENUM(NSUInteger, EditMode) {
    NormalMode,
    DeleteMode,
    DownloadMode,
    SearchMode
};

typedef NS_ENUM(NSUInteger, SortMode) {
    SortByNameMode,
    SortBySizeMode,
    SortByDateMode
};

@implementation DocumentListViewController_online{
    NSMutableArray *photos;
    
    AZAPreviewController *previewController;
    AZAPreviewItem *previewItem;
    
    NSMutableArray *autocompleteUrls;
    bool searchActived;
    
    int editMode;
    int sortMode;
    
    UIBarButtonItem *leftItem, *rightItem, *dismissSearchBarRightItem, *leftButtonForCancelDeleteMode, *rightButtonForDoDelete, *leftButtonForCancelDownloadMode, *rightButtonForDoDownload;
    
    __weak IBOutlet UIView *tooBar;
    UIButton* deleteButton;
    UIButton* downloadButton;
    UIButton* searchButton;
    UIButton* favoriteButton;
    UIButton* dismissSearchBarButton;
    UIButton* cancelDeleteModeButton, *cancelDownloadModeButton;
    UITextField* textField;
    UIImageView * searchBg;
    UIImageView* searchIcon;
    
    NSString *titleStr;
    
    bool isMyFavoritesListSlideDown;
    int offsetYOfMyFavoritesListSlideDown;
    
    int threadNum;//限定同時只能背景下載圖片10個
    NSMutableOrderedSet* orderSet;
    
    //    NSMutableArray *allFavorites;
}

@synthesize fileType = _fileType;

-(void)viewDidLoad{
    [super viewDidLoad];
    
    //    [self.tableView setContentInset:UIEdgeInsetsMake(20, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right)];
    
    //設定通知對應的函數
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(notificationHandle:)
                                                 name: @"ReloadNotificationHandle"
                                               object: nil];
    
    autocompleteUrls = [NSMutableArray array];
    selectedItems = [NSMutableArray array];
    
    [self setNavigatinItem];
    [self setToolBar];
    
    CGFloat newTableViewY = tooBar.frame.origin.y + tooBar.frame.size.height;
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, newTableViewY, self.tableView.frame.size.width, self.myFavoritesView.frame.origin.y - newTableViewY);
    self.bgImageView.frame = self.tableView.frame;
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
    //    [self.sortByFileNameTypeLabel sizeToFit];
    //    [self.sortByFileSizeTypeLabel sizeToFit];
    //    [self.sortByDateTypeLabel sizeToFit];
    
    orderSet = [[NSMutableOrderedSet alloc] initWithCapacity:20];
}

-(void)setNavigatinItem{
    //    self.navigationItem.title = _(@"Files List");
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
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIButton* sortMenuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage *image = [UIImage imageNamed:@"router_cut-29"];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 24)];
#else
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(26.4, 24)];
#endif
    [sortMenuButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"router_cut-29"];
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
    image = [UIImage imageNamed:@"router_cut-19_white"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"router_cut-19_white"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateHighlighted];
    [doDeleteButton addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
    rightButtonForDoDelete = [[UIBarButtonItem alloc] initWithCustomView:doDeleteButton];
    
    cancelDownloadModeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
    cancelDownloadModeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [cancelDownloadModeButton setTitle:_(@"Cancel") forState:UIControlStateNormal];
    [cancelDownloadModeButton addTarget:self action:@selector(switchDownloadMode) forControlEvents:UIControlEventTouchUpInside];
    leftButtonForCancelDownloadMode = [[UIBarButtonItem alloc] initWithCustomView:cancelDownloadModeButton];
    
    UIButton* doDownloadButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    image = [UIImage imageNamed:@"itop_option_download_to_enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 30)];
    [doDownloadButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"itop_option_download_to_enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 30)];
    [doDownloadButton setImage:image forState:UIControlStateHighlighted];
    [doDownloadButton addTarget:self action:@selector(downloadClick) forControlEvents:UIControlEventTouchUpInside];
    rightButtonForDoDownload = [[UIBarButtonItem alloc] initWithCustomView:doDownloadButton];
    
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
    self.navigationItem.leftBarButtonItem = leftButtonForCancelDownloadMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoDownload,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setToolBar{
#ifdef MESSHUDrive
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:ToolTitleOnlineBackgroundColor]];
#else
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:@"fff4f4f4"]];
#endif
    
    deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    //    deleteButton.backgroundColor = [UIColor redColor];
    UIImage* image = [UIImage imageNamed:@"router_cut-19"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [deleteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"router_cut-19"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [deleteButton setImage:image forState:UIControlStateHighlighted];
    
    downloadButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
    
    image = [UIImage imageNamed:@"top_option_download_to_enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [downloadButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"top_option_download_to_enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [downloadButton setImage:image forState:UIControlStateHighlighted];
    
    searchButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 50, 50)];
    image = [UIImage imageNamed:@"top_option_search_online_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [searchButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"top_option_search_online_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [searchButton setImage:image forState:UIControlStateHighlighted];
    [searchButton setContentMode:UIViewContentModeRight];
    
    [deleteButton addTarget:self action:@selector(switchDeleteMode) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton addTarget:self action:@selector(switchDownloadMode) forControlEvents:UIControlEventTouchUpInside];
    [searchButton addTarget:self action:@selector(switchSearchMode) forControlEvents:UIControlEventTouchUpInside];
    
    favoriteButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-50, 0, 50, 50)];
    image = [UIImage imageNamed:@"router_cut-22"];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 20)];
#else
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 28)];
#endif
    [favoriteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"router_cut-22"];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 20)];
#else
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 28)];
#endif
    [favoriteButton setImage:image forState:UIControlStateHighlighted];
    [favoriteButton addTarget:self action:@selector(myFavoritesViewClick:) forControlEvents:UIControlEventTouchUpInside];
    if(self.fileType == MUSIC_TYPE)
        favoriteButton.hidden = NO;
    else
        favoriteButton.hidden = YES;
    
    [self setNormalToobarItem];
    
    dismissSearchBarButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-50, 0, 50, 50)];
    image = [UIImage imageNamed:@"router_cut-31"];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(15, 15)];
#else
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(15, 25)];
#endif
    
    [dismissSearchBarButton setImage:image forState:UIControlStateNormal];
    [dismissSearchBarButton setImage:image forState:UIControlStateHighlighted];
    [dismissSearchBarButton addTarget:self action:@selector(clearSearchBarContent) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setNormalToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar addSubview:deleteButton];
    [tooBar addSubview:downloadButton];
    [tooBar addSubview:searchButton];
    [tooBar addSubview:favoriteButton];
}

-(void)setDeletingToobarItem{
    [self showSearchBar];
}

-(void)setUploadingToobarItem{
    [self showSearchBar];
}

-(void)setSearchingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar addSubview:searchIcon];
    [tooBar addSubview:searchBg];
    [tooBar addSubview:textField];
    [tooBar addSubview:dismissSearchBarButton];
}

-(void)showSearchBar{
    if(textField!=nil){
        textField.text = @"";
        [self searchBehaviorWithString:textField.text];
        
        [textField removeFromSuperview];
        textField = nil;
        return;
    }
    
    searchActived = true;
    [self searchBehaviorWithString:@""];
    
    searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(searchButton.frame.size.width/2 - 20/2, searchButton.frame.size.height/2 - 28/2, 25, 25)];
    searchIcon.image = [UIImage imageNamed:@"top_option_search_online_icon"];
    
    CGFloat textFieldX = searchIcon.frame.origin.x + searchIcon.frame.size.width + 10;
    textField = [[UITextField alloc] initWithFrame:CGRectMake(textFieldX, 1, dismissSearchBarButton.frame.origin.x - textFieldX, tooBar.frame.size.height-2)];
    [textField setFont:[UIFont systemFontOfSize:14]];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.borderStyle = UITextBorderStyleNone;
    textField.placeholder = _(@"ONLINE_SEARCH_HINT");
    textField.delegate = self;
    if(editMode == SearchMode)
        [textField becomeFirstResponder];
    
    searchBg = [[UIImageView alloc] initWithFrame:CGRectMake(textField.frame.origin.x, searchIcon.frame.origin.y + searchIcon.frame.size.height + 5, dismissSearchBarButton.frame.origin.x + 35 - textField.frame.origin.x, 1)];
#ifdef MESSHUDrive
    searchBg.backgroundColor = [UIColor whiteColor];
    [textField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName : [UIColor groupTableViewBackgroundColor]}]];
    [textField setTintColor:[UIColor colorWithRGB:0xCC0000]];
    [textField setTextColor:[UIColor whiteColor]];
#endif
    searchBg.backgroundColor = [UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine];
    [self setSearchingToobarItem];
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
                
                //                [self dismissSearchBar];
                //                editMode = NormalMode;
                //                self.tableView.allowsMultipleSelection = NO;
                //                [self setNormalNavigatinItem];
                //                self.navigationItem.title = titleStr;
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
        if(self.loadingView.hidden){ // If still loading, not do searchBehaviorWithString.
            textField.text = @"";
            [self searchBehaviorWithString:textField.text];
        }
        
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
    
    if(self.fileType == ALL_TYPE){
        self.sortBySizeView.hidden = NO;
        self.sortByDateView.hidden = YES;
    }else{
        self.sortBySizeView.hidden = YES;
        self.sortByDateView.hidden = NO;
    }
}

-(void)menuBtnDidClick{
    [self.view addSubview:self.sortMenuView];
    [self.sortMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.sortMenuView.superview);
        make.top.equalTo(self.mas_topLayoutGuide);
    }];
}

- (IBAction)sortByNameClick:(id)sender {
    sortMode = SortByNameMode;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSSortDescriptor *sorterByIsFolder = [[NSSortDescriptor alloc] initWithKey:@"isFolder" ascending:NO];
    [items sortUsingDescriptors:[NSArray arrayWithObjects:sorterByIsFolder, sorter, nil]];
    [photos sortUsingDescriptors:[NSArray arrayWithObjects:sorterByIsFolder, sorter, nil]];
    [self.tableView reloadData];
    [self sortMenuBGClick:nil];
}

- (IBAction)sortBySizeClick:(id)sender {
    sortMode = SortBySizeMode;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"size" ascending:YES];
    NSSortDescriptor *sorterByIsFolder = [[NSSortDescriptor alloc] initWithKey:@"isFolder" ascending:NO];
    [items sortUsingDescriptors:[NSArray arrayWithObjects:sorterByIsFolder, sorter, nil]];
    [photos sortUsingDescriptors:[NSArray arrayWithObjects:sorterByIsFolder, sorter, nil]];
    [self.tableView reloadData];
    [self sortMenuBGClick:nil];
}

- (IBAction)sortByDateClick:(id)sender {
    sortMode = SortByDateMode;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"createTime" ascending:NO];
    NSSortDescriptor *sorterByIsFolder = [[NSSortDescriptor alloc] initWithKey:@"isFolder" ascending:NO];
    [items sortUsingDescriptors:[NSArray arrayWithObjects:sorterByIsFolder, sorter, nil]];
    [photos sortUsingDescriptors:[NSArray arrayWithObjects:sorterByIsFolder, sorter, nil]];
    [self.tableView reloadData];
    [self sortMenuBGClick:nil];
}

- (IBAction)sortMenuBGClick:(id)sender {
    [self.sortMenuView removeFromSuperview];
}

//- (IBAction)myFavoritesViewClick:(id)sender {
////    self.myFavoritesView.userInteractionEnabled = NO;
//}

- (IBAction)myFavoritesViewClick:(id)sender {
    self.myFavoritesView.userInteractionEnabled = NO;
    CGFloat constraintValue;
    
    if(!isMyFavoritesListSlideDown){
        isMyFavoritesListSlideDown = true;
        constraintValue = -offsetYOfMyFavoritesListSlideDown;
    }else{
        isMyFavoritesListSlideDown = false;
        if (@available(iOS 11.0, *)) {
            constraintValue = 0;
        }else{
            constraintValue = 44;
        }
        
    }
    
    [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.myFavoritesViewBottomConstraint.constant = constraintValue;
        [self.myFavoritesView.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.myFavoritesView.userInteractionEnabled = YES;
    }];
}

//////////////////////
////// MyFavorites
//////////////////////
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
    NSString *str = [[paths objectAtIndex:0] stringByAppendingPathComponent:((OnLineDataFile*)favorites[indexPath.row]).name];
    
    cell.filenameLabel.text = ((OnLineDataFile*)favorites[indexPath.row]).name;
    //    [cell.filenameLabel sizeToFit];
    
    if(self.fileType == VIDEO_TYPE){
        cell.imageViewe.image = [EnShareTools generateThumbImage:str];
        if(cell.imageViewe.image==nil)
            cell.imageViewe.image = [[DataManager sharedInstance] getImageWithType:@"VIDEO" ext:[cell.filenameLabel.text pathExtension]];
    }else if(self.fileType == MUSIC_TYPE){
        cell.imageViewe.image = [EnShareTools getMusicCover:str];
        if(cell.imageViewe.image==nil)
            cell.imageViewe.image = [[DataManager sharedInstance] getImageWithType:@"MUSIC" ext:[cell.filenameLabel.text pathExtension]];
    }else if(self.fileType == DOCUMENT_TYPE){
        cell.imageViewe.image = [[DataManager sharedInstance] getImageWithType:@"DOCUMENT" ext:[cell.filenameLabel.text pathExtension]];
    }else if(self.fileType == PHOTO_TYPE){
        
    }else if(self.fileType == ALL_TYPE){
        for(OnLineDataFile* file in items){
            if([cell.filenameLabel.text isEqualToString:file.name]){
                cell.imageViewe.image = [[DataManager sharedInstance] getImageWithType:file.type ext:[cell.filenameLabel.text pathExtension]];
                break;
            }
        }
        
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self openFile:favorites[indexPath.row] useArray:favorites];
}

//加入最愛
- (void)starClk:(NSNumber*)enable file:(OnLineDataFile*)file {
    NSString* favoriteTime;
    if ([enable boolValue] == TRUE) {
        [favorites addObject:file];
        favoriteTime = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
        [self saveFavoriteByAdd:file.filePath];
        
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
        [self saveFavoriteByRemove:file.filePath];
        
        [self.myFavoritesCollectionView reloadData];
        NSInteger section = [self.myFavoritesCollectionView numberOfSections] - 1;
        NSInteger item = [self.myFavoritesCollectionView numberOfItemsInSection:section] - 1;
        if(section>=0 && item>=0){
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            [self.myFavoritesCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
        }
    }
}

-(void)deleteMyFavoritefile:(OnLineDataFile*)file {
    if([favorites indexOfObject: file ]<[favorites count]){
        [favorites removeObject: file ];
    }
}
//////////////////////
//////
//////////////////////

- (void)deleteByFiles:(NSArray*)dfiles {
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.loadingView.hidden = NO;
    
    NSMutableArray *deleteItems = [NSMutableArray array];
    for (NSString *file_ in dfiles) {
        NSString *file = file_.pathComponents[file_.pathComponents.count - 1];
        for (OnLineDataFile *item in photos) {
            if ([[file stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] isEqualToString:item.name]) {
                [deleteItems addObject:item.filePath];
                break;
            }
        }
    }
    
    [self deleteByFileName:[NSMutableArray arrayWithArray:deleteItems] :0];
}

//下載
- (void)downloadClick{
    if (selectedItems.count == 0) {
        [self showWarningView];
        return;
    }
    
    bool hasMusicOrVideo = FALSE;
    for (OnLineDataFile* file in selectedItems) {
        NSString *extension = [file.filePath pathExtension];
        if ([[[DataManager sharedInstance] getType:extension] isEqualToString:@"PICTURE"] ||
            [[[DataManager sharedInstance] getType:extension] isEqualToString:@"VIDEO"]) {
            hasMusicOrVideo = TRUE;
            break;
        }
    }
    
    if (hasMusicOrVideo == FALSE) {
        //        for (OnLineDataFile* file in selectedItems) {
        //            NSString *filename = file.filePath;
        //            [[DataManager sharedInstance] addDownload:filename saveToAlbum:FALSE];
        //        }
        
        DownloadingViewController_online * downloadingViewController = [[DownloadingViewController_online alloc] initWithNibName:@"DownloadingViewController_online" bundle:nil];
        downloadingViewController.downloadItems = [selectedItems copy];
        downloadingViewController.delegate = self;
        [self presentViewController:downloadingViewController animated:YES completion:nil];
    } else {
        [self saveToAlbum:@"collection"];
    }
    
    //    if (![DataManager sharedInstance].tagDownloadStatus) {
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //            [[DataManager sharedInstance] doDownload];
    //        });
    //    }
    
}

- (void)saveToAlbum:(NSString*)tag {
    BOOL tagIfAlbum = FALSE;
    //    if ([tag isEqualToString:@"album"]) {
    //        tagIfAlbum = TRUE;
    //    }else{
    //        tagIfAlbum = FALSE;
    //    }
    
    for (OnLineDataFile *file in selectedItems) {
        [[DataManager sharedInstance] addDownload:file.filePath saveToAlbum:tagIfAlbum];
    }
    
    [[KGModal sharedInstance] hideAnimated:YES];
    
    DownloadingViewController_online * downloadingViewController = [[DownloadingViewController_online alloc] initWithNibName:@"DownloadingViewController_online" bundle:nil];
    downloadingViewController.downloadItems = [selectedItems copy];
    downloadingViewController.delegate = self;
    [downloadingViewController setSaveToAlbum:tagIfAlbum];
    [self presentViewController:downloadingViewController animated:YES completion:nil];
}
/*
 -(void)showLoginDialog{
 LoginViewControllerForOffline *loginView = [[LoginViewControllerForOffline alloc] initWithNibName:@"LoginViewControllerForOffline" bundle:nil];
 [loginView addCloseBtn];
 //    self.providesPresentationContextTransitionStyle = YES;
 //    self.definesPresentationContext = YES;
 [loginView setModalPresentationStyle:UIModalPresentationOverCurrentContext];
 [loginView setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
 [self presentViewController:loginView animated:YES completion:nil];
 loginView.delegate = self;
 }*/

- (void)doUpload{
    //    [[DataManager sharedInstance] doUpload];
    //    for(OnLineDataFile* file in selectedItems){
    //        [[DataManager sharedInstance] doUpload:file.name withSuccessBlock:^{
    //
    //        } failureBlock:^{
    //
    //        } isFromAlbum:NO];
    //    }
    
    // 上傳
    BOOL tagIfUpload = NO;
    //    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows){
    for (OnLineDataFile *item in selectedItems){
        //        OnLineDataFile *item = items[indexPath.row];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:item.name];//取得檔案路徑
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        int fileSizeMB = [fileSizeNumber longLongValue] / (1024 * 1024 );
        //LogMessage(nil, 0, @"%d", fileSizeMB);
        if (fileSizeMB > 1.5 * 1024) {//超過1.5G不允許上傳
            tagIfUpload = NO;
            break;
        }else{
            tagIfUpload = YES;
        }
    }
    
    if (tagIfUpload == YES) {
        //        for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows){
        for (OnLineDataFile *item in selectedItems){
            //            OnLineDataFile *item = items[indexPath.row];
            [[DataManager sharedInstance] addUpload:item.name];
        }
        
        if (![DataManager sharedInstance].tagUploadStatus) {
            
            //            [self performSelectorInBackground:@selector(doUpload) withObject:nil];
            
            //            if ([DataManager sharedInstance].uidLoginStatus == YES && [DataManager sharedInstance].uidUploadStatus == NO) {
            //                [[DataManager sharedInstance] openTunnel:[[NSUserDefaults standardUserDefaults] stringForKey:@"UID"] openPort:2000];
            //            }
            //            [[DataManager sharedInstance] doUpload];
            
            
            
            UploadingViewController * uploadingViewController = [[UploadingViewController alloc] initWithNibName:@"UploadingViewController" bundle:nil];
            uploadingViewController.uploadItems = [selectedItems copy];
            [self presentViewController:uploadingViewController animated:YES completion:nil];
            
            [self changeToNormalMode];
        }
        
    }else{
        [self showWarnning:_(@"UPLOAD_ALERT")];
    }
    
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"CollectionPage_Edit-Upload" Label:nil Value:nil];
#endif
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if(offsetYOfMyFavoritesListSlideDown==0){
//        offsetYOfMyFavoritesListSlideDown = ([UIScreen mainScreen].bounds.size.height - self.myFavoritesView.frame.origin.y);
        offsetYOfMyFavoritesListSlideDown = self.myFavoritesView.bounds.size.height;
        
        if (@available(iOS 11.0, *)) {
            
        }else{
            offsetYOfMyFavoritesListSlideDown -= 44;
        }
        
        self.myFavoritesViewBottomConstraint.constant = -offsetYOfMyFavoritesListSlideDown;
        isMyFavoritesListSlideDown = true;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    if(editMode != NormalMode  && editMode != SearchMode)
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    else
        [self changeTitle];
    //        self.navigationItem.title = titleStr;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //移除通知對應函數
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

//當 MainControllerNotificationHandle 通知發生時會執行此函數
- (void) notificationHandle: (NSNotification*) sender;
{
    NSLog(@"-notificationHandle");
    [self loadData];
}

-(void)loadData{
    items = [NSMutableArray array];
    photos = [NSMutableArray array];
    favorites = [NSMutableArray array];
    
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
        [self showWarnning:_(@"LOGIN_ALERT_INTERNET")];
        //        [self.navigationController popToRootViewControllerAnimated:YES];
        [self backToLoginPage];
        return;
    }
    
    [self reloadData];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(searchActived){
        return autocompleteUrls.count;
    }else{
        return items.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* simpleTableIdentifier = @"Simple";
    DocumentTableViewCell_online *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if(cell == nil){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"DocumentTableViewCell_online" owner:self options:nil] objectAtIndex:0];
    }
    
    OnLineDataFile* file;
    
    if(searchActived){
        NSLog(@"%ld",(long)indexPath.row);
        file = ((OnLineDataFile*)[autocompleteUrls objectAtIndex:indexPath.row]);
    }else{
        file = ((OnLineDataFile*)[items objectAtIndex:indexPath.row]);
    }
    
    
    if((editMode == DeleteMode || editMode == DownloadMode) && !file.isFolder){
        [cell changeToSelectedMode:YES];
    }else{
        [cell changeToSelectedMode:NO];
    }
    
    cell.titleLabel.text = file.name;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *str = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
    if(self.fileType == VIDEO_TYPE){
        cell.thumbnailImageView.image = [EnShareTools generateThumbImage:str];
        if(cell.thumbnailImageView.image==nil)
            cell.thumbnailImageView.image = [[DataManager sharedInstance] getImageWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
    }else if(self.fileType == MUSIC_TYPE){
        cell.thumbnailImageView.image = [EnShareTools getMusicCover:str];
        if(cell.thumbnailImageView.image==nil)
            cell.thumbnailImageView.image = [[DataManager sharedInstance] getImageWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
    }else if(self.fileType == DOCUMENT_TYPE){
        cell.thumbnailImageView.image = [[DataManager sharedInstance] getImageWithType:@"DOCUMENT" ext:[cell.titleLabel.text pathExtension]];
    }else if(self.fileType == PHOTO_TYPE){
        
    }else if(self.fileType == ALL_TYPE){
        if (file.isFolder) {
            [cell.thumbnailImageView cancelCurrentImageLoad];
            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"folder.png"]];
        }else{
            if(![[[DataManager sharedInstance] getType:[file.name pathExtension]] isEqualToString:@"PICTURE"]){
                [cell.thumbnailImageView cancelCurrentImageLoad];
                
                cell.thumbnailImageView.image = [[DataManager sharedInstance] getImageWithType:file.type ext:[cell.titleLabel.text pathExtension]];
            }else{
                
                NSString *filePath = file.filePath;
                NSMutableString *thumbPath = [NSMutableString string];
                NSArray *paths = [filePath pathComponents];
                
                for (int i=0; i<paths.count; i++) {
                    if ([paths[i] isEqualToString:@"/"] == FALSE) {
                        if (i != 2)
                            [thumbPath appendFormat:@"/%@", [paths[i] urlEncodeUsingEncoding]];
                        else
#ifdef MESSHUDrive
                            [thumbPath appendFormat:@"/%@/.Fujitsu", [paths[i] urlEncodeUsingEncoding]];
#else
                        [thumbPath appendFormat:@"/%@/.EnGenius", [paths[i] urlEncodeUsingEncoding]];
#endif
                    }
                }
                
                NSString *thumbFilePath = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], thumbPath];
                NSString *originFilePath = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], [[filePath urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"]];
                cell.thumbnailImageView.image = [UIImage imageNamed:@"img_photo.jpg"];
                
                @autoreleasepool {
                    [cell.thumbnailImageView setImageWithURL:[NSURL URLWithString:thumbFilePath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"]  options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                        
                        if (image == NULL) {
                            
                            [cell.thumbnailImageView setImageWithURL:[NSURL URLWithString:originFilePath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"] options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                            }];
                        }
                    }];
                }
            }
        }
    }
    
    /*
     cell.fileSizeLabel.text = [[EnShareTools transformedValue:file.size] stringByAppendingString:@", "];
     [cell.fileSizeLabel setNumberOfLines:1];
     [cell.fileSizeLabel sizeToFit];
     CGRect newFrame = cell.createDateLabel.frame;
     newFrame.origin.x = cell.fileSizeLabel.frame.origin.x + cell.fileSizeLabel.frame.size.width;
     cell.createDateLabel.frame = newFrame;
     cell.createDateLabel.text = [EnShareTools formatDate_yyyyMMdd:[EnShareTools getFileCreationTimeFromPath:str]];
     [cell.createDateLabel setNumberOfLines:1];
     [cell.createDateLabel sizeToFit];
     */
    
    cell.favoriteButton.selected = NO;
    for(OnLineDataFile *favoritesFile in favorites){
        if([favoritesFile.filePath isEqualToString:file.filePath]){
            cell.favoriteButton.selected = YES;
            break;
        }
    }
    
    if(self.fileType != MUSIC_TYPE)
        cell.favoriteButton.hidden = YES;
    
    cell.delegate = self;
    
    if([selectedItems containsObject:file]){
        [cell.checkboxButton setSelected:YES];
    }else{
        [cell.checkboxButton setSelected:NO];
    }
    
    cell.file = file;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *useArray = nil;
    OnLineDataFile *item;
    if(searchActived){
        useArray = autocompleteUrls;
        item = autocompleteUrls[indexPath.row];
    }else{
        useArray = items;
        item = items[indexPath.row];
    }
    
    if(editMode != NormalMode && editMode!=SearchMode){
        DocumentTableViewCell_online *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if(!cell.checkboxButton.isHidden){
            if(cell.checkboxButton.isSelected){
                [selectedItems removeObject:item];
                [cell.checkboxButton setSelected:NO];
            }else{
                [selectedItems addObject:item];
                [cell.checkboxButton setSelected:YES];
            }
            
            self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }else {
        if(item.isFolder){
            // 目錄
            [self gotoFolder:item.filePath];
        }else{
            [self openFile:item useArray:useArray];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    
}

-(void)gotoFolder:(NSString*)folderPath{
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.path = folderPath;
    [self loadData];
    if(editMode == DeleteMode){
        [self switchDeleteMode];
    }else if(editMode == DownloadMode){
        [self switchDownloadMode];
    }else if(editMode == SearchMode){
        [self switchSearchMode];
        [self changeTitle];
    }else{
        [self changeTitle];
    }
}

-(void)changeTitle{
    if(self.path == nil || [self.path isEqualToString:[DataManager sharedInstance].usbUploadPath]){
        self.navigationItem.title = titleStr;
    }else{
        NSArray *tArray = [self.path componentsSeparatedByString:@"/"];
        NSString *newFolderPath = [tArray objectAtIndex:[tArray count]-1];
        self.navigationItem.title = newFolderPath;
    }
}

-(void)openFile:(OnLineDataFile*)item useArray:(NSArray*)useArray{
    //    if (loadingView.hidden == YES)
    //        return;
    
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"type %@",[item valueForKey:@"type"]);
    //    NSLog(@"type %@",[item objectForKeyedSubscript:@"type"]);
    if ([item.type isEqualToString:@"MUSIC"]) {
        // 播放元件
        
        PlayerViewController *playerViewController = [[PlayerViewController alloc] init];
        playerViewController.delegate = self;
        
        int c=0;
        for (OnLineDataFile *dict in useArray) {
            NSString *file = [[dict.filePath urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
            NSString *str = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], file];
            
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:str, @"musicAddress", dict.name, @"musicName", nil];
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
        for (OnLineDataFile *dict in useArray) {
            if ([[dict.name lowercaseString] rangeOfString:@".mov"].length>0 || [[dict.name lowercaseString] rangeOfString:@".avi"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".mp4"].length>0 || [[dict.name lowercaseString] rangeOfString:@".3gp"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".m4v"].length>0 || [[dict.name lowercaseString] rangeOfString:@".mkv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".wmv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".asf"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".dv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".vob"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".mpg"].length>0) {
                
                NSString *file = [[dict.filePath urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
                NSString *str = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], file];
                [videoArray addObject:str];
                
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
        //        [navigationController pushViewController:videoViewController animated:YES];
        [self presentViewController:navigationController animated:YES completion:nil];
        
    } else if ([item.type isEqualToString:@"PICTURE"]) {
        int idx = 0;
        for (OnLineDataFile *photo in photos) {
            if ([photo.name isEqualToString:item.name])
                break;
            idx++;
        }
        OnlineFGalleryViewController *galleryVC = [[OnlineFGalleryViewController alloc] initWithPhotoSource:self];
        galleryVC.startingIndex = idx;
        galleryVC.useThumbnailView = FALSE;
        galleryVC.delegate = self;
        [galleryVC gotoImageByIndex:idx animated:NO];
        [self.navigationController pushViewController:galleryVC animated:YES];
    } else if ([item.type isEqualToString:@"DOCUMENT"]) {
        // 下載檔案
        [[DataManager sharedInstance] download:item.filePath completion:^(NSString *file) {
            // 預覽
            //        NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:item.name];
            previewItem = [AZAPreviewItem previewItemWithURL:[NSURL fileURLWithPath:file] title:[[file pathComponents] lastObject]];
            previewController = [[AZAPreviewController alloc] init];
            previewController.dataSource = self;
            previewController.delegate = self;
            [self presentViewController:previewController animated:YES completion:nil];
            //            [manager increaseCountByFileName:item.name];
        } error:^(void) {
        }];
    }
}



- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    [autocompleteUrls removeAllObjects];
    
    [selectedItems removeAllObjects];
    
    if(editMode != NormalMode  && editMode != SearchMode)
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    
    if(!searchActived){
        for(OnLineDataFile* f in items) {
            [autocompleteUrls addObject:f];
        }
    }else{
        bool isTheStringDate = NO;
        isTheStringDate = [self isTheStringDate:substring];
        
        for(OnLineDataFile* f in items) {
            if(isTheStringDate){
                NSString* dateStr = [EnShareTools formatDate_yyyyMMdd:f.createTime];
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

#pragma mark - FGalleryViewControllerDelegate Methods

- (int)numberOfPhotosForPhotoGallery:(OnlineFGalleryViewController *)gallery {
    //    if(searchActived){
    //        return autocompleteUrls.count;
    //    }else{
    //        return items.count;
    //    }
    return photos.count;
}

- (FGalleryPhotoSourceType)photoGallery:(OnlineFGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    return FGalleryPhotoSourceTypeNetwork;
}

- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index {
    OnLineDataFile* file = photos[index];
    //    if(searchActived){
    //        file = ((OnLineDataFile*)autocompleteUrls[index]);
    //    }else{
    //        file = ((OnLineDataFile*)items[index]);
    //    }
    
    NSString *filename = [NSString stringWithFormat:@"%@", file.name];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    OnLineDataFile* file = photos[index];
    //    if(searchActived){
    //        file = ((OnLineDataFile*)autocompleteUrls[index]);
    //    }else{
    //        file = ((OnLineDataFile*)items[index]);
    //    }
    
    NSString *filePath = [[file.filePath urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
    NSString *url = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], filePath];
    return url;
}

- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery filePathAtIndex:(NSUInteger)index {
    OnLineDataFile* file = photos[index];
    //    if(searchActived){
    //        file = ((OnLineDataFile*)autocompleteUrls[index]);
    //    }else{
    //        file = ((OnLineDataFile*)items[index]);
    //    }
    return file.filePath;
}

- (bool)photoGallery:(OnlineFGalleryViewController*)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index{
    OnLineDataFile* file = photos[index];
    //    if(searchActived){
    //        file = ((OnLineDataFile*)autocompleteUrls[index]);
    //    }else{
    //        file = ((OnLineDataFile*)items[index]);
    //    }
    //
    if([favorites containsObject:file])
        return YES;
    
    return NO;
}

- (void)photoGallery:(OnlineFGalleryViewController*)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index{
    OnLineDataFile* file = photos[index];
    [self starClk:@(isAddToFavortieList) file:file];
    [self.tableView reloadData];
    //    if(searchActived){
    //        file = ((OnLineDataFile*)autocompleteUrls[index]);
    //    }else{
    //        file = ((OnLineDataFile*)items[index]);
    //    }
    
    //    if (isAddToFavortieList == TRUE) {
    //        [favorites addObject:file];
    //        [self saveFavoriteByAdd:file.filePath];
    //    } else {
    //        [favorites removeObject:file];
    //        [self saveFavoriteByRemove:file.filePath];
    //    }
    
    //    [self loadData];
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
        OnLineDataFile* file = items[i];
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
        if(self.path == nil || [self.path isEqualToString:[DataManager sharedInstance].usbUploadPath]){
            [self.navigationController popToRootViewControllerAnimated:YES];
        }else{
            [self gotoFolder:[self.path stringByDeletingLastPathComponent]];
        }
        
    }
}

-(void)switchFromDeleteToNormalMode{
    [self dismissSearchBar];
    editMode = NormalMode;
    self.tableView.allowsMultipleSelection = NO;
    [self changeToNormalMode];
    
    //        self.navigationItem.title = titleStr;
    
    [self changeTitle];
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
        [self switchFromDeleteToNormalMode];
    }
}

-(void)switchDownloadMode{
    if(editMode == NormalMode){
        editMode = DownloadMode;
        
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
        
        //        self.navigationItem.title = titleStr;
        [self changeTitle];
    }
}

-(void)switchSearchMode{
    if(editMode == NormalMode){
        editMode = SearchMode;
        
        ((UIBarButtonItem*)self.navigationItem.rightBarButtonItems.lastObject).enabled = NO;
        [self showSearchBar];
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
    [selectedItems removeAllObjects];
    editMode = NormalMode;
    //    [self.tableView reloadData];
    
    self.tableView.allowsMultipleSelection = NO;
}

- (void)deleteClick {
    if (selectedItems.count == 0) {
        [self showWarningView];
        return;
    }
    
    NSString *info;
    NSMutableArray *dfiles = [NSMutableArray array];
    
    for (OnLineDataFile *file in selectedItems){
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
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"CollectionPage_Edit-Delete" Label:nil Value:nil];
#endif
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
            self.path = [DataManager sharedInstance].usbUploadPath;
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

#pragma mark - LoginViewControllerForOfflineDelegate
-(void)loginSuccessCallback{
    [self doUpload];
}

#pragma mark - DownloadingViewControllerDelegate
-(void)downloadSuccessCallback{
    [self switchDownloadMode];
}

-(void)downloadCancelClickedCallback{
    
}

-(OnLineDataFile*)addObjectToItems:(NSString*)obj isFolder:(BOOL)isFolder{
    return [super addObjectToItems:obj isFolder:isFolder];
}

-(bool)doTask{
    bool compeleted = [super doTask];
    if(compeleted){
        for(OnLineDataFile* file in items){
            if([file.type isEqualToString:@"PICTURE"])
                [photos addObject:file];
        }
        
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
    
    return compeleted;
}

@end
