//
//  PhotoCollectionViewController.m
//  EnSmart
//
//  Created by Phil on 2015/8/26.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "PhotoCollectionViewController.h"
//#import "AZAPreviewController.h"
//#import "AZAPreviewItem.h"
#import "KGModal.h"
#import "IR_Tools.h"
#import "SuccessView.h"
#import "DataManager.h"
#import "PhotoCollectionReusableView.h"
#import "CollectionDataFile.h"
#import "PhotoCollectionViewCell.h"
#import "CommonTools.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "StorageDeleteView.h"
#import "StorageSelectWarningView.h"
#import "LoadingView.h"
#import "StaticLanguage.h"
//#import "UploadingViewController.h"
//#import "RouterGlobal.h"
#import "AppDelegate.h"
//#import "DialogPermissionView.h"
#import "UIImageView+WebCache.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSUInteger, EditMode) {
    NormalMode,
    DeleteMode,
    UploadMode
};

@interface PhotoCollectionViewController ()

@end

@implementation PhotoCollectionViewController{
    CGFloat newCollectionViewY;
    NSMutableArray* photos, *photosGroupByDate;
//    BOOL editEnabled;
    NSMutableArray* selectedPhotos;
    
    NSMutableArray *autocompleteUrls;
    bool searchActived;
    bool isNeedToReloadData;
    
    int editMode;
    UIView* tooBar;
    UIBarButtonItem *leftItem, *rightItem, *dismissSearchBarRightItem, *leftButtonForCancelDeleteMode, *rightButtonForDoDelete, *leftButtonForCancelUploadMode, *rightButtonForDoUpload;
    UIButton* uploadButton;
    UIButton* deleteButton;
    UIButton* searchButton;
    UIButton* downloadButton;
    UIButton* dismissSearchBarButton;
    UIButton* cancelDeleteModeButton, *cancelUploadModeButton;
    UIButton* selectAllButton;
    UITextField* textField;
    UIImageView * searchBg;
    UIImageView* searchIcon;
    
    IRGalleryViewController *galleryVC;
    dispatch_queue_t queue;
}

static NSString * const reuseIdentifier = @"Cell";

-(void)viewWillAppear:(BOOL)animated{
    self.navigationItem.title = _(@"Photos List");
    [self.navigationController setNavigationBarHidden:NO];
    [self registerForKeyboardNotifications];
    
    if(!tooBar){
        [self setNavigatinItem];
        [self setToolBar];
        
        [self setNormalToobarItem];
    }
    

    
    //設定通知對應的函數
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(notificationHandle:)
                                                 name: @"ReloadNotificationHandle"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    NSLog(@"remove-notificationHandle");
    //移除通知對應函數
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidLayoutSubviews{
//    [self setNormalToobarItem];
    [self changeCollectionViewY];
}

-(void)changeCollectionViewY{
#ifdef MESSHUDrive
    self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, newCollectionViewY, self.collectionView.frame.size.width, self.view.frame.size.height - newCollectionViewY);
    self.collectionViewBottomLineImageView.hidden = YES;
    self.syncAlbumBtn.hidden = YES;
#else
    self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, newCollectionViewY, self.collectionView.frame.size.width, self.collectionViewBottomLineImageView.frame.origin.y - newCollectionViewY);
#endif
    self.bgImageView.frame = self.collectionView.frame;
}

//當通知發生時會執行此函數
- (void) notificationHandle: (NSNotification*) sender;
{
    NSLog(@"-notificationHandle");
    [self loadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    queue = dispatch_queue_create("loadImaged.queue", DISPATCH_QUEUE_SERIAL);
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PhotoCollectionViewCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 10, 0);
    collectionViewLayout.headerReferenceSize = CGSizeMake(self.collectionView.frame.size.width, 40.f);
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.importFile) {
        CollectionDataFile *file = appDelegate.importFile;
        appDelegate.importFile = nil;
        
        photos = [NSMutableArray array];
        [photos addObject:file];
        
        photosGroupByDate = [self groupByDate:photos];
        
        [self createGallery];
        
        for(UIButton *button in galleryVC.toolBar.items){
            button.enabled = NO;
        }
        
        [galleryVC setSlideEnable:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self gotoGallery:[NSIndexPath indexPathForItem:0 inSection:0]];
            
            isNeedToReloadData = YES;
            
            if(isNeedToReloadData){
                isNeedToReloadData = NO;
                [self loadData];
            }
        });
        

    }else{
        [self loadData];
    }
    
    selectedPhotos = [NSMutableArray array];
    
    autocompleteUrls = [NSMutableArray array];
    
    [self.syncAlbumBtn setTitle:_(@"SYNC_ALBUM_BUTTON_TITLE") forState:UIControlStateNormal];
    
    [self.navigationController.navigationBar setNeedsLayout];
#ifdef MESSHUDrive
    self.bgImageView.image = [UIImage imageNamed:@"bg_gray"];
#endif
}

-(void)createGallery{
    __weak PhotoCollectionViewController *weakSelf = self;
    
    if(galleryVC){
        @synchronized (galleryVC) {
            [galleryVC setPhotoSource:nil];
        }
    }
    
    galleryVC = [[IRGalleryViewController alloc] initWithPhotoSource:weakSelf];
    galleryVC.startingIndex = 0;
    galleryVC.useThumbnailView = FALSE;
    galleryVC.delegate = self;
}

-(void)dealloc{
    @synchronized (galleryVC) {
        [galleryVC setPhotoSource:nil];
    }
}

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
    backButtonFrame.origin.x = 0 ;
    backButtonFrame.origin.y = 5 ;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    [backButton setTitle:_(@"Back") forState:UIControlStateNormal];
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    
    downloadButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIImage* image = [UIImage imageNamed:@"nav_mobile import to enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 30)];
    [downloadButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"nav_mobile import to enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 30)];
    [downloadButton setImage:image forState:UIControlStateHighlighted];
    [downloadButton addTarget:self action:@selector(openSyncPhotosPageFormPhoneAlbum) forControlEvents:UIControlEventTouchUpInside];
    
    rightItem = [[UIBarButtonItem alloc] initWithCustomView:downloadButton];
    
    [self setNormalNavigatinItem];
    
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
}

-(void)setNormalNavigatinItem{
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,leftItem,nil];
    //    [rightItem setTitlePositionAdjustment:UIOffsetMake(0, -50) forBarMetrics:UIBarMetricsDefault];
    negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-20];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,rightItem,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setDeletingNavigatinItem{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = leftButtonForCancelDeleteMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    //    self.navigationItem.rightBarButtonItem = rightButtonForDoDelete;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoDelete,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setUploadingNavigatinItem{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = leftButtonForCancelUploadMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    //    self.navigationItem.rightBarButtonItem = rightButtonForDoDelete;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoUpload,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setToolBar{
    tooBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, 50)];
#ifdef MESSHUDrive
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:ToolTitleBackgroundColor]];
#else
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:@"fff4f4f4"]];
#endif
    [self.view addSubview:tooBar];
    
    deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
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
    [searchButton addTarget:self action:@selector(showSearchBar) forControlEvents:UIControlEventTouchUpInside];
    
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
}

-(void)setNormalToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar addSubview:deleteButton];
    [tooBar addSubview:uploadButton];
    [tooBar addSubview:searchButton];
    [tooBar setHidden:NO];
    
    newCollectionViewY = tooBar.frame.origin.y + tooBar.frame.size.height;
    [self changeCollectionViewY];
}

-(void)setDeletingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //    [tooBar addSubview:cancelDeleteModeButton];
    [tooBar addSubview:selectAllButton];
}

-(void)setUploadingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //    [tooBar addSubview:cancelDeleteModeButton];
    [tooBar addSubview:selectAllButton];
}

-(void)setSearchingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar addSubview:searchIcon];
    [tooBar addSubview:searchBg];
    [tooBar addSubview:textField];
    [tooBar addSubview:dismissSearchBarButton];
    [tooBar setHidden:NO];
    
    newCollectionViewY = tooBar.frame.origin.y + tooBar.frame.size.height;
    [self changeCollectionViewY];
}

-(void)setDownloadingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //    [tooBar addSubview:cancelDeleteModeButton];
    [tooBar setHidden:YES];
    
    newCollectionViewY = tooBar.frame.origin.y;
    [self changeCollectionViewY];
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
    
    searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(searchButton.frame.size.width/2 - 20/2, searchButton.frame.size.height/2 - 20/2, 25, 25)];
    searchIcon.image = [UIImage imageNamed:@"btn_search"];
    
    CGFloat textFieldX = searchIcon.frame.origin.x + searchIcon.frame.size.width + 10;
    textField = [[UITextField alloc] initWithFrame:CGRectMake(textFieldX, 1, dismissSearchBarButton.frame.origin.x - textFieldX, tooBar.frame.size.height-2)];
    [textField setFont:[UIFont systemFontOfSize:14]];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.borderStyle = UITextBorderStyleNone;
    textField.placeholder = _(@"OFFLINE_PHOTO_SEARCH_HINT");
    textField.delegate = self;
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
            [self dismissSearchBar];
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

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

-(void)loadData{
    [self startAnimating];
    
    dispatch_async(queue, ^{
//        self.navigationItem.userInteractionEnabled = YES;
        
        photos = [NSMutableArray array];
        NSArray* readFromDB = [[DataManager sharedInstance].database sqliteRead:[NSString stringWithFormat:@"SELECT * FROM Collection WHERE type = '%@' AND isfolder = '%@'; ", @"PICTURE", @"0"]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        for(NSDictionary* dic in readFromDB){
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:dic[@"filename"]];
            CollectionDataFile* file = [[CollectionDataFile alloc] initWithDatabaseNSDictionary:dic fileSize:[IR_Tools getFileSize:filePath] fileCreatedDate:[IR_Tools getFileCreationTimeFromPath:filePath]];
            [photos addObject:file];
        }
        
        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"createTime" ascending:NO];
        [photos sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
        
        photosGroupByDate = [self groupByDate:photos];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeSelectedItems];
            
            if(editMode != NormalMode){
                self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
            }else{
                self.navigationItem.title = _(@"Photos List");
            }
            
            [self.collectionView reloadData];
            //    galleryVC.startingIndex = 0;
            //    [galleryVC reloadGallery];
            [self createGallery];
            
            [self stopAnimating];
        });
    });

    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
//#warning Incomplete method implementation -- Return the number of sections
    return photosGroupByDate.count;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat cellsAcross = 4;
    CGFloat spaceBetweenCells = 2;
    CGFloat cellProperWidth = (collectionView.bounds.size.width - (cellsAcross - 1) * spaceBetweenCells) / cellsAcross;
    return CGSizeMake(cellProperWidth, cellProperWidth);
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        PhotoCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        NSDictionary* dic = [photosGroupByDate objectAtIndex:indexPath.section];
        NSString *title = [[NSString alloc]initWithFormat:@"%@", [[dic allKeys] firstObject]];
        headerView.titleLabel.text = title;
        [headerView.titleLabel sizeToFit];
        
        reusableview = headerView;
    }
    
    return reusableview;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary* dic = [photosGroupByDate objectAtIndex:section];
    NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
    NSInteger itemsCount = photosByTheSameDate.count;
    return itemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCollectionViewCell" forIndexPath:indexPath];
    
    cell.imageview.image = [UIImage imageNamed:@"img_photo.jpg"];
    
    if(editMode == NormalMode){
        cell.checkboxImageView.hidden = YES;
    }else{
        cell.checkboxImageView.hidden = NO;
    }
    
    CollectionDataFile *item;
    int position = 0;
    for(int section = 0; section < indexPath.section; section++){
        position += [self.collectionView numberOfItemsInSection:section];
    }
    
    position += indexPath.row;
    
    if(searchActived){
        item = autocompleteUrls[position];
    }else{
        item = photos[position];
    }
    
    if([selectedPhotos containsObject:item]){
        [cell setSelected:YES];
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
    }else{
        [cell setSelected:NO];
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)_cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)_cell;
    CollectionDataFile* file;
    
    NSDictionary* dic = [photosGroupByDate objectAtIndex:indexPath.section];
    NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
    
    if(searchActived){
        file = ((CollectionDataFile*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    }else{
        file = ((CollectionDataFile*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filepath = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];

    bool isFirstLoad = false;
    if(cell.imageview.image == nil)
        isFirstLoad = true;
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
            if(isFirstLoad || [[self.collectionView indexPathsForVisibleItems] containsObject:indexPath]){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [cell.imageview sd_setImageWithURL:[NSURL fileURLWithPath:filepath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"]  options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (image)
                        return;
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        //縮小photo
                        @autoreleasepool {
                            UIImage *tImage = [UIImage imageWithContentsOfFile:filepath];
                            
                            float w=60.f,h=50.f;
                            if (tImage.size.width>=120 && tImage.size.height>=100) {
                                if( tImage.size.width > tImage.size.height ){
                                    w = ((float)(tImage.size.height/tImage.size.width))*100;
                                    h = 100;
                                }else{
                                    w = 120;
                                    h = ((float)(tImage.size.width/tImage.size.height))*120;;
                                }
                                UIGraphicsBeginImageContext(CGSizeMake(w, h));
                                [tImage drawInRect:CGRectMake(0,0,120,100)];
                            }else{
                                UIGraphicsBeginImageContext(CGSizeMake(w, h));
                                [tImage drawInRect:CGRectMake(0,0,tImage.size.width,tImage.size.height)];
                            }
                            
                            
                            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if([[self.collectionView indexPathsForVisibleItems] containsObject:indexPath]){
                                    cell.imageview.image = newImage;
                                    [cell setNeedsLayout];
                                }
                            });
                        }
                    });
                }];
                });
            }
        });
    });
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    CollectionDataFile *item;
    
    int position = 0;
    for(int section = 0; section < indexPath.section; section++){
        position += [self.collectionView numberOfItemsInSection:section];
    }
    
    position += indexPath.row;
    
    if(searchActived){
        item = autocompleteUrls[position];
    }else{
        item = photos[position];
    }
    
    if(editMode != NormalMode){
        [selectedPhotos addObject:item];
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
        [self checkSelectAllItemButtonStatus];
    }else{
        [self gotoGallery:indexPath];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(editMode != NormalMode){
        NSInteger rowNumber = 0;
        
        for (NSInteger i = 0; i < indexPath.section; i++) {
            rowNumber += [self.collectionView numberOfItemsInSection:i];
        }
        
        rowNumber += indexPath.row;
        
        CollectionDataFile* item = ((CollectionDataFile*)[photos objectAtIndex:rowNumber]);
        [selectedPhotos removeObject:item];
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
        [self checkSelectAllItemButtonStatus];
    }
}

- (UIImage*)loadFullsizeInThread:(NSString*)filename
{
    @autoreleasepool {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *str = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
     return [UIImage imageWithContentsOfFile:str];
    }
}

-(void)gotoGallery:(NSIndexPath *)indexPath{
    int position = 0;
    for(int section = 0; section < indexPath.section; section++){
        position += [self.collectionView numberOfItemsInSection:section];
    }
    
    position += indexPath.row;
    
    CollectionDataFile* file;
    
    NSDictionary* dic = [photosGroupByDate objectAtIndex:indexPath.section];
    NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
    
    if(searchActived){
        file = ((CollectionDataFile*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    }else{
        file = ((CollectionDataFile*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filepath = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
    
    galleryVC.startingIndex = position;
    galleryVC.preDisplayView.image = [UIImage imageWithContentsOfFile:filepath];
    [galleryVC gotoImageByIndex:position animated:NO];

    [self.navigationController pushViewController:galleryVC animated:YES];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - IRGalleryViewControllerSourceDelegate Methods

- (void)photoGallery:(IRGalleryViewController *)gallery deleteAtIndex:(NSUInteger)index {
    CollectionDataFile* file;
    if(searchActived){
        file = ((CollectionDataFile*)autocompleteUrls[index]);
    }else{
        file = ((CollectionDataFile*)photos[index]);
    }
    [self delete:@[file]];
}

#pragma mark - IRGalleryViewControllerSourceDelegate Methods

- (int)numberOfPhotosForPhotoGallery:(IRGalleryViewController *)gallery {
    if(searchActived){
        return autocompleteUrls.count;
    }else{
        return photos.count;
    }
}

- (IRGalleryPhotoSourceType)photoGallery:(IRGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    return IRGalleryPhotoSourceTypeLocal;
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index {
    CollectionDataFile* file;
    if(searchActived){
        file = ((CollectionDataFile*)autocompleteUrls[index]);
    }else{
        file = ((CollectionDataFile*)photos[index]);
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@", file.name];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery urlForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index {
    CollectionDataFile* file;
    if(searchActived){
        file = ((CollectionDataFile*)autocompleteUrls[index]);
    }else{
        file = ((CollectionDataFile*)photos[index]);
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@", file];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery filePathForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index {
    CollectionDataFile *file;
    if(searchActived){
        file = ((CollectionDataFile *)autocompleteUrls[index]);
    }else{
        file = ((CollectionDataFile *)photos[index]);
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *str = [[paths objectAtIndex:0] stringByAppendingPathComponent:[file valueForKey:@"name"]];
    return str;
}

- (bool)photoGallery:(IRGalleryViewController *)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index {
    CollectionDataFile* file;
    if(searchActived){
        file = ((CollectionDataFile*)autocompleteUrls[index]);
    }else{
        file = ((CollectionDataFile*)photos[index]);
    }
    
    if([file.addfavoritetime intValue]==0)
        return NO;
    
    return YES;
}

- (void)photoGallery:(IRGalleryViewController *)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index {
    CollectionDataFile *file;
    if(searchActived){
        file = ((CollectionDataFile *)autocompleteUrls[index]);
    }else{
        file = ((CollectionDataFile *)photos[index]);
    }
    
    NSString* favoriteTime;
    if (isAddToFavortieList == TRUE) {
        favoriteTime = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    } else {
        favoriteTime = @"0";
    }
    
    [[DataManager sharedInstance].database sqliteUpdate:@"Collection" keys:@ {
        @"filename" : [file.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
        @"isfolder" : @"0",
    } params:@ {
        @"addfavoritetime" : favoriteTime,
    }];
    
    file.addfavoritetime = favoriteTime;
}

- (void)backBtnDidClick {
    if(textField!=nil){
        editMode = NormalMode;
        [self dismissSearchBar];
    }else if(editMode != NormalMode){
        editMode = NormalMode;
        
        for(NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems){
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        [self removeSelectedItems];
        
        self.collectionView.allowsMultipleSelection = NO;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }else{
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)switchDeleteMode {
    if(editMode == NormalMode){
        editMode = DeleteMode;
        
        [self setDeletingToobarItem];
        [self setDeletingNavigatinItem];
        
        self.collectionView.allowsMultipleSelection = YES;
        [self.collectionView reloadData];
        
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
    }else{
        editMode = NormalMode;
        self.collectionView.allowsMultipleSelection = NO;
        [self changeToNormalMode];
        [self.collectionView reloadData];
        
        self.navigationItem.title = _(@"Photos List");
    }
}

- (void)switchUploadMode {
    if(editMode == NormalMode){
        editMode = UploadMode;
        
        [self setUploadingToobarItem];
        [self setUploadingNavigatinItem];
        
        self.collectionView.allowsMultipleSelection = YES;
        [self.collectionView reloadData];
        
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
    }else{
        editMode = NormalMode;
        self.collectionView.allowsMultipleSelection = NO;
        [self changeToNormalMode];
        [self.collectionView reloadData];
        
        self.navigationItem.title = _(@"Photos List");
    }
}

- (void)openSyncPhotosPageFormPhoneAlbum {
    [self checkPermisstion];
    
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.mediaType = QBImagePickerMediaTypeImage;
    imagePickerController.showsNumberOfSelectedAssets = YES;
    imagePickerController.assetCollectionSubtypes = @[@(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                      @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                                      @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                                      @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                                      @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
//                                                      @(PHAssetCollectionSubtypeSmartAlbumVideos),
//                                                      @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
//                                                      @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
//                                                      @(PHAssetCollectionSubtypeSmartAlbumBursts),
//                                                      @(PHAssetCollectionSubtypeSmartAlbumAllHidden),
                                                      @(PHAssetCollectionSubtypeSmartAlbumGeneric),
                                                      @(PHAssetCollectionSubtypeAlbumRegular),
                                                      @(PHAssetCollectionSubtypeAlbumSyncedAlbum),
                                                      @(PHAssetCollectionSubtypeAlbumSyncedEvent),
                                                      @(PHAssetCollectionSubtypeAlbumSyncedFaces),
                                                      @(PHAssetCollectionSubtypeAlbumImported),
//                                                      @(PHAssetCollectionSubtypeAlbumCloudShared)
                                                      ];
    if(imagePickerController.childViewControllers.count > 0){
        UINavigationController *nav = imagePickerController.childViewControllers[0];
        [nav.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor]];
        [nav.navigationBar
         setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    }
    
    [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
}

- (void)changeToNormalMode {
    [self setNormalToobarItem];
    [self setNormalNavigatinItem];
    searchButton.hidden = NO;
    [self cancelClick];
}

- (void)cancelClick {
    editMode = NormalMode;
    for(NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems){
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    [self removeSelectedItems];
    self.navigationItem.title = _(@"Photos List");
    
    self.collectionView.allowsMultipleSelection = NO;
}

- (void)deleteClick {
    if (self.collectionView.indexPathsForSelectedItems.count == 0) {
        [self showWarningView];
        return;
    }
    
    NSString *info;
    NSMutableArray *dfiles = [NSMutableArray array];

    for (CollectionDataFile* file in selectedPhotos){
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

- (void)delete:(NSArray*)dfiles {
    for (CollectionDataFile *file in dfiles) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *file1 = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:file1 error:nil];
        
        [[DataManager sharedInstance].database sqliteDelete:@"Collection" keys:@ {
            @"uid" : file.uid,
        }];
    }
    
    [self loadData];
    [self showWarnning:_(@"DELETE_ALERT")];
    [self changeToNormalMode];
}

- (void)showWarningView{
    StorageSelectWarningView *sview = nil;
    VIEW(sview, StorageSelectWarningView);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:sview andAnimated:YES];
}

- (void)selectAllItem:(BOOL)selectAll {
    if (selectAll) {
        if(searchActived){
            selectedPhotos = [NSMutableArray arrayWithArray:autocompleteUrls];
        }else{
            selectedPhotos = [NSMutableArray arrayWithArray:photos];
        }
    } else {
        [selectedPhotos removeAllObjects];
    }
}

- (void)checkSelectAllItemButtonStatus {
    BOOL selectedAll = NO;
    if ([selectedPhotos count] > 0) {
        if(searchActived){
            selectedAll = ([selectedPhotos count] == [autocompleteUrls count]);
        }else{
            selectedAll = ([selectedPhotos count] == [photos count]);
        }
    }
    
    selectAllButton.selected = selectedAll;
}

- (void)selectAllItemButtonClick:(UIButton*)sender {
    sender.selected = !sender.isSelected;
    
    [self selectAllItem:sender.isSelected];
    self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
    
    [self.collectionView reloadData];
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

- (void)removeSelectedItems {
    [selectedPhotos removeAllObjects];
    [self selectAllItem:NO];
    [self checkSelectAllItemButtonStatus];
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    // Put anything that starts with this substring into the autocompleteUrls array
    // The items in this array is what will show up in the table view
    [autocompleteUrls removeAllObjects];
    [self removeSelectedItems];
    
    if(editMode != NormalMode)
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedPhotos.count, _(@"SELECTED")];
    
    if(!searchActived){
        for(CollectionDataFile* f in photos) {
            [autocompleteUrls addObject:f];
        }
    }else{
        for(CollectionDataFile* f in photos) {
            NSString *curStringForFileName = [IR_Tools formatDate_yyyyMMdd:f.createTime];
            NSRange substringRangeForFileName = [curStringForFileName rangeOfString:substring options:NSCaseInsensitiveSearch];
            if (substringRangeForFileName.length > 0) {
                [autocompleteUrls addObject:f];
            }
        }
    }

    photosGroupByDate = [self groupByDate:autocompleteUrls];
    [self.collectionView reloadData];
    
    [self createGallery];
}

-(NSMutableArray*)groupByDate:(NSMutableArray*)itmes{
    NSMutableArray* a, *b;
    NSMutableDictionary* d;
    NSString* previousDateString;
    
    a = [NSMutableArray array];
    for(CollectionDataFile* file in itmes){
        BOOL hasNewDateGroup = NO;
        NSString* dateString = [self getDateStringShowInPhotoAlbum:file.createTime];
        if(previousDateString==nil){
            b = [NSMutableArray array];
            d = [NSMutableDictionary dictionary];
            hasNewDateGroup = YES;
        }else if(![previousDateString isEqualToString:dateString]){
            b = [NSMutableArray array];
            d = [NSMutableDictionary dictionary];
            hasNewDateGroup = YES;
        }
        [b addObject:file];
        previousDateString = dateString;
        if(hasNewDateGroup){
            [d setValue:b forKey:dateString];
            [a addObject:d];
        }
    }
    
    return a;
}

-(NSString*)getDateStringShowInPhotoAlbum:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *datestring = [formatter stringFromDate:date];
    return datestring;
}

- (IBAction)syncAlbumClick:(id)sender {
    [self doSyncPhotos];
}

- (NSString*)getVideoID:(NSString*)videoURL{
    NSString *videoID = nil, *videoExt = nil;
    
    NSString *tVideoURL = videoURL;
    
    NSRange po = [videoURL rangeOfString:@"?"];
    if(po.location>0){
        tVideoURL = [tVideoURL substringFromIndex:po.location];
    }
    
    po = [tVideoURL rangeOfString:@"&"];
    if(po.location>0){
        videoID = [tVideoURL substringToIndex:po.location];
        videoID = [videoID stringByReplacingOccurrencesOfString:@"?id="withString:@""];
        
        tVideoURL = [tVideoURL substringFromIndex:po.location];
        videoExt = [[tVideoURL stringByReplacingOccurrencesOfString:@"&ext="withString:@""] lowercaseString];
    }
    
    videoID = [ NSString stringWithFormat:@"%@.%@", videoID , videoExt];
    return videoID;
}

-(void)doSyncPhotos{
    [AutoSyncPhotos sharedInstance].delegate = self;
    [[AutoSyncPhotos sharedInstance] doSync];
}

-(void)checkPermisstion{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
    }failureBlock:^(NSError *error) {
        [self showPermisstionAlert];
    }];
}

- (void)dialogOk {
    UINavigationController* navController = self.navigationController;
    if([navController.presentedViewController isKindOfClass:[QBImagePickerController class]]){
        [navController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
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
    CGFloat tableViewBottom = self.collectionView.frame.origin.y + self.collectionView.frame.size.height;
    CGFloat offsetY = kbSize.height - (self.view.frame.size.height - tableViewBottom);
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, offsetY, 0.0);
    self.collectionView.contentInset = contentInsets;
    self.collectionView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, textField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, textField.frame.origin.y-kbSize.height);
        [self.collectionView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.collectionView.contentInset = contentInsets;
    self.collectionView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - AutoSyncPhotosDelegate
-(void)syncFinishCallback{
    if(textField!=nil){ // search
        editMode = NormalMode;
        [self dismissSearchBar];
    }
    [self loadData];
}

#pragma mark - showPermisstionAlert
- (void)showPermisstionAlert{
    SuccessView *dialog;;
    VIEW(dialog, SuccessView);
    dialog.infoLabel.text = _(@"NOT_PHOTO");
//    dialog.imageView.image = [UIImage imageNamed:_(@"Photo_Permission")];
//    dialog.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

#pragma mark - QBImagePickerControllerDelegate
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            PHImageManager *manager = [PHImageManager defaultManager];
            for (PHAsset *asset in assets) {
                PHImageRequestOptions *option = [PHImageRequestOptions new];
                option.synchronous = YES;
                
                [manager requestImageDataForAsset:asset
                                          options:option
                                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                        
                                        NSString *fileName = nil;
                                        NSArray *parts = [asset.localIdentifier componentsSeparatedByString:@"/"];
                                        NSString *assetID = [parts objectAtIndex:0];
                                        
                                        NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
                                        NSString *ext = path.pathExtension;
                                        if(ext){
                                            fileName = [NSString stringWithFormat:@"%@.%@", assetID, ext];
                                            
                                            NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]];
                                            
                                            NSString *filePath = [resourceDocPath stringByAppendingPathComponent:fileName];
                                            
                                            [imageData writeToFile:filePath atomically:YES];
                                            
                                            //存入到資料庫
                                            NSString *uid = [NSString stringWithFormat:@"%d%d", (int)[[NSDate date] timeIntervalSince1970], arc4random() % 99999];
                                            [[DataManager sharedInstance].database    sqliteInsert:@"Collection" keys:@ {
                                                @"uid" : uid,
                                                @"type" : [[DataManager sharedInstance] getType:[fileName pathExtension]],
                                                @"filename" : [fileName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                                                @"isdownload" : @"1",
                                                @"isfolder" : @"0",
                                                @"parentfolder" : @"/"
                                            }];
                                        }else{
                                            NSLog(@"No pathExtension.");
                                        }
                                    }];
            }
            
            [[KGModal sharedInstance] hideAnimated:YES];
            [self syncFinishCallback];
        });
    }];
    
    LoadingView *loadingView;;
    VIEW(loadingView, LoadingView);
    loadingView.title.text = _(@"SYNCING");
    [[KGModal sharedInstance] setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:loadingView andAnimated:YES];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

@end
