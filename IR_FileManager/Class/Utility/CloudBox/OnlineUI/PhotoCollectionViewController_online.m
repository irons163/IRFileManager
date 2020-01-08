

//
//  PhotoCollectionViewController.m
//  EnSmart
//
//  Created by Phil on 2015/8/26.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "PhotoCollectionViewController_online.h"
#import "AZAPreviewController.h"
#import "AZAPreviewItem.h"
#import "KGModal.h"
#import "EnShareTools.h"
#import "SuccessView.h"
#import "DataManager.h"
#import "PhotoCollectionReusableView.h"
#import "OnLineDataFile.h"
#import "CollectionDataFile.h"
#import "PhotoCollectionViewCell.h"
#import "CommonTools.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "StorageDeleteView.h"
#import "StorageSelectWarningView.h"
#ifdef enshare
#import "SenaoGA.h"
#endif
#import "UploadingViewController_online.h"
#import "RouterGlobal.h"
#import "NSString+URLEncoding.h"
#import "UIImageView+WebCache.h"
#import "AutoUploadFolderNameView.h"
#import "AutoUpload.h"
#import "LoadingView.h"
#import "DialogPermissionView.h"
#import "Masonry.h"

typedef NS_ENUM(NSUInteger, EditMode) {
    NormalMode,
    DeleteMode,
    DownloadMode
};

@interface PhotoCollectionViewController_online ()<SDWebImageManagerDelegate>

@end

@implementation PhotoCollectionViewController_online{
    CGFloat newCollectionViewY;
    
    NSMutableArray* photosGroupByDate;
    
    NSMutableArray *autocompleteUrls;
    bool searchActived;
    
    int editMode;
    UIView* tooBar;
    UIBarButtonItem *leftItem, *rightItem, *dismissSearchBarRightItem, *leftButtonForCancelDeleteMode, *rightButtonForDoDelete, *leftButtonForCancelDownloadMode, *rightButtonForDoUpload;
    UIButton* deleteButton;
    UIButton* searchButton;
    UIButton* downloadButton;
    UIButton* openSyncPhotosPageFormPhoneAlbumButton;
    UIButton* dismissSearchBarButton;
    UIButton* cancelDeleteModeButton, *cancelDownloadModeButton;
    UITextField* textField;
    UIImageView * searchBg;
    UIImageView* searchIcon;
    
    OnlineFGalleryViewController *galleryVC;
    
    NSTimer *autoUploadTimer;
    
    UIImage *placeholderImage;
}

static NSString * const reuseIdentifier = @"Cell";

-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"will Appear");
    [super viewWillAppear:animated];
    
    if(editMode != NormalMode)
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    else
        self.navigationItem.title = _(@"Photos List");
    
    if(!tooBar){ // to check first viewWillAppear.
        [self setNavigatinItem];
        [self setToolBar];
        
        self.syncAlbumBtn.center = CGPointMake([[UIScreen mainScreen] bounds].size.width - self.syncAlbumBtn.frame.size.width/2 -5, tooBar.frame.size.height/2);
        [self.syncAlbumBtn setTitle:_(@"SYNC_ALBUM_BUTTON_TITLE") forState:UIControlStateNormal];
        
        [self setNormalToobarItem];

    }else{
        [self initAutoUpload];
    }
}

-(void)viewDidLayoutSubviews{
    [self changeCollectionViewY];
}

-(void)changeCollectionViewY{
    self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, newCollectionViewY, self.collectionView.frame.size.width, self.collectionViewBottomLineImageView.frame.origin.y - newCollectionViewY);
    self.bgImageView.frame = self.collectionView.frame;
    
#ifdef MESSHUDrive
//    [self.syncAlbumBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.syncAlbumBtn setBackgroundImage:[UIImage imageNamed:@"btn_sync_all"] forState:UIControlStateNormal];
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SDWebImageManager.sharedManager.imageDownloader.maxConcurrentDownloads = 6;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PhotoCollectionViewCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 10, 0);
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self createGallery];
    
    SDWebImageManager.sharedManager.delegate = self;
    
    placeholderImage = [UIImage imageNamed:@"img_photo.jpg"];
    
#ifdef MESSHUDrive
    self.bgImageView.image = [UIImage imageNamed:@"bg_gray"];
#endif
}

-(void)createGallery{
    galleryVC = [[OnlineFGalleryViewController alloc] initWithPhotoSource:self];
    galleryVC.startingIndex = 0;
    galleryVC.useThumbnailView = FALSE;
    galleryVC.delegate = self;
}

-(void)setNavigatinItem{
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
    backButtonFrame.origin.x = 0 ;
    backButtonFrame.origin.y = 5 ;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    
    openSyncPhotosPageFormPhoneAlbumButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIImage* image = [UIImage imageNamed:@"btn_nav_mobile"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 30)];
    [openSyncPhotosPageFormPhoneAlbumButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"btn_nav_mobile"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 30)];
    [openSyncPhotosPageFormPhoneAlbumButton setImage:image forState:UIControlStateHighlighted];
    [openSyncPhotosPageFormPhoneAlbumButton addTarget:self action:@selector(openSyncPhotosPageFormPhoneAlbum) forControlEvents:UIControlEventTouchUpInside];
    
    rightItem = [[UIBarButtonItem alloc] initWithCustomView:openSyncPhotosPageFormPhoneAlbumButton];
    
    [self setNormalNavigatinItem];
    
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
    rightButtonForDoUpload = [[UIBarButtonItem alloc] initWithCustomView:doDownloadButton];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setNormalNavigatinItem{
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,leftItem,nil];
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
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoDelete,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setUploadingNavigatinItem{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = leftButtonForCancelDownloadMode;
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight,rightButtonForDoUpload,nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)setToolBar{
    tooBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, 50)];
#ifdef MESSHUDrive
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:ToolTitleOnlineBackgroundColor]];
#else
    [tooBar setBackgroundColor:[UIColor colorWithColorCodeString:@"fff4f4f4"]];
#endif
    [self.view addSubview:tooBar];
    
    deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIImage* image = [UIImage imageNamed:@"router_cut-19"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [deleteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"router_cut-19"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [deleteButton setImage:image forState:UIControlStateHighlighted];
    
    //    [deleteButton setContentEdgeInsets:UIEdgeInsetsMake(-20, 0, -10, 0)];
    
    downloadButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
    
    image = [UIImage imageNamed:@"top_option_download_to_enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [downloadButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"top_option_download_to_enfile_icon"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [downloadButton setImage:image forState:UIControlStateHighlighted];
    
    autoUploadView.backgroundColor = tooBar.backgroundColor;
    autoUploadHeaderLbl.text = _(@"Camera_Upload");
    [autoUploadCancelButton setTitle:_(@"Cancel") forState:UIControlStateNormal];
    
    [deleteButton addTarget:self action:@selector(switchDeleteMode) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton addTarget:self action:@selector(switchDownloadMode) forControlEvents:UIControlEventTouchUpInside];
    
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

-(UIView*)addAutoUploadView{
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_KEY] isEqualToString:@"YES"]) {
        return autoUploadView;
    }
    return self.syncAlbumBtn;
}

-(void)setNormalToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar addSubview:deleteButton];
    [tooBar addSubview:downloadButton];
    [tooBar addSubview:[self addAutoUploadView]];
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_KEY] isEqualToString:@"YES"]) {
        [autoUploadView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(tooBar);
        }];
    }
    [tooBar setHidden:NO];
    
    newCollectionViewY = tooBar.frame.origin.y + tooBar.frame.size.height;
    [self changeCollectionViewY];
}

-(void)setDeletingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tooBar setHidden:YES];
    
    newCollectionViewY = tooBar.frame.origin.y;
    [self changeCollectionViewY];
}

-(void)setUploadingToobarItem{
    [[tooBar subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //    [tooBar addSubview:cancelDeleteModeButton];
    [tooBar setHidden:YES];
    
    newCollectionViewY = tooBar.frame.origin.y;
    [self changeCollectionViewY];
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
    [tooBar setHidden:YES];
    
    newCollectionViewY = tooBar.frame.origin.y;
    [self changeCollectionViewY];
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
    items = [NSMutableArray array];
    selectedItems = [NSMutableArray array];
    autocompleteUrls = [NSMutableArray array];
    
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
        [self showWarnning:_(@"LOGIN_ALERT_INTERNET")];
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    
    [self reloadData];
}

-(bool)doTask{
    bool compeleted = [super doTask];
    if(compeleted){
        photosGroupByDate = [self groupByDate:items];
        [self createGallery];
        [self.collectionView reloadData];
        
        [self initAutoUpload];
    }
    
    return compeleted;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"didReceiveMemoryWarning");
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
    cell.tag = indexPath.row;
    
    OnLineDataFile* file;
    NSDictionary* dic = [photosGroupByDate objectAtIndex:indexPath.section];
    NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
    
    if(searchActived){
        NSLog(@"%ld",(long)indexPath.row);
        file = ((OnLineDataFile*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    }else{
        file = ((OnLineDataFile*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    }
    
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
    
    @autoreleasepool {
        [cell.imageview setImageWithURL:[NSURL URLWithString:thumbFilePath] placeholderImage:placeholderImage options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            
            if (image == NULL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.imageview setImageWithURL:[NSURL URLWithString:originFilePath] placeholderImage:placeholderImage options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                        
//                        NSLog(@"cacheType:%ld", (long)cacheType);
                    }];
                });
            }
        }];
    }
    
    if(editMode == NormalMode){
        cell.checkboxImageView.hidden = YES;
    }else{
        cell.checkboxImageView.hidden = NO;
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    [((PhotoCollectionViewCell*)cell).imageview cancelCurrentImageLoad];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
//    [self gotoGallery:indexPath];
    OnLineDataFile *item;
    
    int position = 0;
    for(int section = 0; section < indexPath.section; section++){
        position += [self.collectionView numberOfItemsInSection:section];
    }
    
    position += indexPath.row;
    
    if(searchActived){
        item = autocompleteUrls[position];
    }else{
        item = items[position];
    }
    
    if(editMode != NormalMode){
        [selectedItems addObject:item];
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
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
        
        OnLineDataFile* item = ((OnLineDataFile*)[items objectAtIndex:rowNumber]);
        [selectedItems removeObject:item];

        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    }
}

-(void)gotoGallery:(NSIndexPath *)indexPath{
    
    int position = 0;
    position = indexPath.row;
//    OnlineFGalleryViewController *galleryVC = [[OnlineFGalleryViewController alloc] initWithPhotoSource:self];
//    galleryVC.startingIndex = position;
//    galleryVC.useThumbnailView = FALSE;
//    galleryVC.delegate = self;
    galleryVC.startingIndex = position;
    
    for(PhotoCollectionViewCell * cell in [self.collectionView visibleCells]){
        if(cell.tag == position){
            galleryVC.preDisplayView.tag = position;
            if(cell.imageview.image && cell.imageview.image == placeholderImage)
                galleryVC.preDisplayView.image = nil;
            else if(cell.imageview.image){
                galleryVC.preDisplayView.image = cell.imageview.image;
                galleryVC.preDisplayView.hidden = YES;
            }else{
                galleryVC.preDisplayView.image = nil;
            }
            break;
        }
    }
    
    galleryVC.preDisplayView.hidden = YES;
    [galleryVC gotoImageByIndex:position animated:NO];
    
    [self.navigationController pushViewController:galleryVC animated:YES];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - FGalleryViewControllerDelegate Methods

-(UIImage *)photoGallery:(OfflineFGalleryViewController *)gallery loadThumbnailFromLocalAtIndex:(NSUInteger)index{
    for(PhotoCollectionViewCell * cell in [self.collectionView visibleCells]){
        if(cell.tag == index){
            if(cell.imageview.image && cell.imageview.image != placeholderImage)
                return cell.imageview.image;
            break;
        }
    }
    return nil;
}

- (int)numberOfPhotosForPhotoGallery:(OnlineFGalleryViewController *)gallery {
    if(searchActived){
        return autocompleteUrls.count;
    }else{
        return items.count;
    }
}

- (FGalleryPhotoSourceType)photoGallery:(OnlineFGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    return FGalleryPhotoSourceTypeNetwork;
}

- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index {
    OnLineDataFile* file;
    if(searchActived){
        file = ((OnLineDataFile*)autocompleteUrls[index]);
    }else{
        file = ((OnLineDataFile*)items[index]);
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@", file.name];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    OnLineDataFile* file;
    if(searchActived){
        file = ((OnLineDataFile*)autocompleteUrls[index]);
    }else{
        file = ((OnLineDataFile*)items[index]);
    }
    
//    NSString *filePath = [[file.filePath urlEncodeUsingEncoding] stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
//    NSString *url = [NSString stringWithFormat:@"http://%@%@", [[DeviceClass sharedInstance] getDownloadUrl], filePath];
    
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
    
    NSString *url;
    if(size == FGalleryPhotoSizeThumbnail){
        url = thumbFilePath;
    }else{
        url = originFilePath;
        
    }
    return url;
}

- (NSString*)photoGallery:(OnlineFGalleryViewController *)gallery filePathAtIndex:(NSUInteger)index {
    OnLineDataFile* file;
    if(searchActived){
        file = ((OnLineDataFile*)autocompleteUrls[index]);
    }else{
        file = ((OnLineDataFile*)items[index]);
    }
    return file.filePath;
}

- (bool)photoGallery:(OnlineFGalleryViewController*)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index{
    OnLineDataFile* file;
    if(searchActived){
        file = ((OnLineDataFile*)autocompleteUrls[index]);
    }else{
        file = ((OnLineDataFile*)items[index]);
    }
    
    if([favorites containsObject:file])
        return YES;
    
    return NO;
}

- (void)photoGallery:(OnlineFGalleryViewController*)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index{
    OnLineDataFile* file;
    if(searchActived){
        file = ((OnLineDataFile*)autocompleteUrls[index]);
    }else{
        file = ((OnLineDataFile*)items[index]);
    }
    
    if (isAddToFavortieList == TRUE) {
        [favorites addObject:file];
        [self saveFavoriteByAdd:file.filePath];
    } else {
        [favorites removeObject:file];
        [self saveFavoriteByRemove:file.filePath];
    }
}

-(void)backBtnDidClick{
    if(textField!=nil){
        editMode = NormalMode;
        [self dismissSearchBar];
    }else if(editMode != NormalMode){
        editMode = NormalMode;
        
        for(NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems){
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        [selectedItems removeAllObjects];
        
        self.collectionView.allowsMultipleSelection = NO;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }else{
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(void)switchFromDeleteToNormalMode{
    editMode = NormalMode;
    self.collectionView.allowsMultipleSelection = NO;
    [self changeToNormalMode];
    [self.collectionView reloadData];
    
    self.navigationItem.title = _(@"Photos List");
}

-(void)switchDeleteMode{
    if(editMode == NormalMode){
        editMode = DeleteMode;
        
        [self setDeletingToobarItem];
        [self setDeletingNavigatinItem];
        
        self.collectionView.allowsMultipleSelection = YES;
        [self.collectionView reloadData];
        
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
        
        self.collectionView.allowsMultipleSelection = YES;
        [self.collectionView reloadData];
        
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    }else{
        editMode = NormalMode;
        self.collectionView.allowsMultipleSelection = NO;
        [self changeToNormalMode];
        [self.collectionView reloadData];
        
        self.navigationItem.title = _(@"Photos List");
    }
}

-(void)openSyncPhotosPageFormPhoneAlbum{
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
                                                      @(PHAssetCollectionSubtypeSmartAlbumGeneric),
                                                      @(PHAssetCollectionSubtypeAlbumRegular),
                                                      @(PHAssetCollectionSubtypeAlbumSyncedAlbum),
                                                      @(PHAssetCollectionSubtypeAlbumSyncedEvent),
                                                      @(PHAssetCollectionSubtypeAlbumSyncedFaces),
                                                      @(PHAssetCollectionSubtypeAlbumImported),
                                                      ];
    if(imagePickerController.childViewControllers.count > 0){
        UINavigationController *nav = imagePickerController.childViewControllers[0];
        [nav.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine]];
        [nav.navigationBar
         setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
        [nav.navigationBar setTintColor:[UIColor whiteColor]];
    }
    
    [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
}

-(void)changeToNormalMode{
    [self setNormalToobarItem];
    [self setNormalNavigatinItem];
    [self cancelClick];
}

- (void)cancelClick{
    editMode = NormalMode;
    for(NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems){
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    [selectedItems removeAllObjects];
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

    for (OnLineDataFile* file in selectedItems){
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
        DownloadingViewController_online * downloadingViewController = [[DownloadingViewController_online alloc] initWithNibName:@"DownloadingViewController_online" bundle:nil];
        downloadingViewController.downloadItems = [selectedItems copy];
        downloadingViewController.delegate = self;
        [self presentViewController:downloadingViewController animated:YES completion:nil];
    } else {
        [self saveToAlbum:@"collection"];
    }
}

- (void)saveToAlbum:(NSString*)tag {
    BOOL tagIfAlbum = FALSE;
    
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

- (IBAction)deleteClk:(id)sender {
    if (selectedItems.count == 0) {
        [self showWarningView];
        return;
    }
    
    NSString *info;
    NSMutableArray *dfiles = [NSMutableArray array];
    for (OnLineDataFile* file in selectedItems){
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

- (void)deleteByFiles:(NSArray*)dfiles {
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.loadingView.hidden = NO;
    
    NSMutableArray *deleteItems = [NSMutableArray array];
    for (NSString *file_ in dfiles) {
        NSString *file = file_.pathComponents[file_.pathComponents.count - 1];
        for (OnLineDataFile *item in items) {
            if ([[file stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] isEqualToString:item.name]) {
                [deleteItems addObject:item.filePath];
                break;
            }
        }
    }
    
    [self deleteByFileName:[NSMutableArray arrayWithArray:deleteItems] :0];
}

-(void)showLoginDialog{
    LoginViewControllerForOffline *loginView = [[LoginViewControllerForOffline alloc] initWithNibName:@"LoginViewControllerForOffline" bundle:nil];
    [loginView addCloseBtn];
    //    self.providesPresentationContextTransitionStyle = YES;
    //    self.definesPresentationContext = YES;
    [loginView setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [loginView setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self presentViewController:loginView animated:YES completion:nil];
    loginView.delegate = self;
}

-(void)getUSBInfo{
    
    //取得USB資訊
    RouterGlobal *global = [[RouterGlobal alloc]init];
    [global getStorageInfo:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            
            NSDictionary* tempDict = [resultDictionary objectForKey:@"StorageInformation"];
            if ([tempDict count]==0) {
                [self showLoginDialog];
                [self showWarnning:_(@"USB")];
            }else{
//                if ([DataManager sharedInstance].diskPath == nil) {
                    [DataManager sharedInstance].diskPath = resultDictionary[@"StorageInformation"][0][@"UsbPath"];
                    [DataManager sharedInstance].diskGuestPath = resultDictionary[@"StorageInformation"][0][@"UsbGuestPath"];
//                }
                if ([[DeviceClass sharedInstance] isAdminUser]) {
                    [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskPath;
                }else{//guest
                    [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskGuestPath;
                }
                
                [self doUpload];
            }
            
        }else{
            [self showLoginDialog];
            [self showWarnning:_(@"No mounted device")];
        }
    }];
}

- (void)doUpload{
    // 上傳
    BOOL tagIfUpload = NO;

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
        for (OnLineDataFile *item in selectedItems){
            [[DataManager sharedInstance] addUpload:item.name];
        }
        
        if (![DataManager sharedInstance].tagUploadStatus) {
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

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    
    // Put anything that starts with this substring into the autocompleteUrls array
    // The items in this array is what will show up in the table view
    [autocompleteUrls removeAllObjects];
    [selectedItems removeAllObjects];
    
    if(editMode != NormalMode)
        self.navigationItem.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedItems.count, _(@"SELECTED")];
    
    if(!searchActived){
        for(OnLineDataFile* f in items) {
            [autocompleteUrls addObject:f];
        }
    }else{
        for(OnLineDataFile* f in items) {
            NSString *curStringForFileName = [EnShareTools formatDate_yyyyMMdd:f.createTime];
            NSRange substringRangeForFileName = [curStringForFileName rangeOfString:substring options:NSCaseInsensitiveSearch];
            if (substringRangeForFileName.length > 0) {
                [autocompleteUrls addObject:f];
            }
        }
    }

    photosGroupByDate = [self groupByDate:autocompleteUrls];
    [self createGallery];
    [self.collectionView reloadData];
}

-(NSMutableArray*)groupByDate:(NSMutableArray*)itmes{
    NSMutableArray* a, *b;
    NSMutableDictionary* d;
    NSString* previousDateString;
    
    a = [NSMutableArray array];
    b = [NSMutableArray array];
    d = [NSMutableDictionary dictionary];
    
    for(OnLineDataFile* file in itmes){
        BOOL hasNewDateGroup = NO;
        NSString* dateString = [self getDateStringShowInPhotoAlbum:file.createTime];

        hasNewDateGroup = YES;
        
        if(!dateString)
            dateString = @"";
        
        [b addObject:file];
        previousDateString = dateString;
        [d setValue:b forKey:dateString];
    }
    
    [a addObject:d];
    
    return a;
}

-(NSString*)getDateStringShowInPhotoAlbum:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *datestring = [formatter stringFromDate:date];
    return datestring;
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
    
    //NSLog(@"%@",videoID);
    
    return videoID;
}

-(void)viewDidDisappear:(BOOL)animated{
    [autoUploadTimer invalidate];
    autoUploadTimer = nil;
}

//呼叫Auto Upload
- (void)initAutoUpload{
    NSLog(@"initAutoUpload");
    if (self.fileType == PHOTO_TYPE){
        autoUploadTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(setAutoUploadProgress) userInfo:nil repeats:YES];
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_KEY] isEqualToString:@"YES"]) {
            [self showAutoUpload];
        }else {
        }
    }
}

- (IBAction)syncAlbumClick:(id)sender {
    if(editMode == DeleteMode){
        [self switchDeleteMode];
    }else if(editMode == DownloadMode){
        [self switchDownloadMode];
    }
    
    [self.syncAlbumBtn removeFromSuperview];
    [tooBar addSubview:autoUploadView];
    [autoUploadView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(tooBar);
    }];
    [self doAutoUpload];
}

- (IBAction)autoUploadCancelClick:(id)sender {
    [[AutoUpload sharedInstance] cancelUpload];
    
    [self cancelClk];
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

-(void)doAutoUpload{
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"Storage_Photo-Enable Album Sync" Label:nil Value:nil];
#endif
    if ([[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY] == nil) {
        [self showAddfolderName];
    }else{
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"YES" forKey:AUTO_UPLOAD_KEY];
        [userDefault setObject:@"YES" forKey:WIFI_ONLY_KEY];
        [userDefault synchronize];
        [self showAutoUpload];
    }
}

#pragma mark - Auto Upload
- (void)showAddfolderName{
    AutoUploadFolderNameView *autoUploadFolderNameView;
    VIEW(autoUploadFolderNameView, AutoUploadFolderNameView);
    autoUploadFolderNameView.delegate = self;
    autoUploadFolderNameView.folderNameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY];
    [[KGModal sharedInstance] setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:autoUploadFolderNameView andAnimated:YES];
}
- (void)doAutoUpload:(NSString*)folder{
    if ([[folder stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""] ) { //為空白
        [self showWarnning:_(@"AUTO_UPLOAD_ALERT_EMPTY")];
    }else if ( [[DataManager sharedInstance] checkFileName:folder] ) { //含有特殊字元
        [self showWarnning:_(@"AUTO_UPLOAD_ALERT_ERROR")];
    }else if ( folder.length>128 ) { //長度太長
        [self showWarnning:_(@"RENAME_ALERT_LENGTH")];
    }else{
        
        [[KGModal sharedInstance] hideAnimated:YES];
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:folder forKey:AUTO_UPLOAD_FOLDER_NAME_KEY];
        [userDefault setObject:@"YES" forKey:AUTO_UPLOAD_KEY];
        [userDefault setObject:@"YES" forKey:WIFI_ONLY_KEY];
        [userDefault synchronize];
        
        [self showAutoUpload];
        
    }
}
- (void)cancelClk{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"NO" forKey:AUTO_UPLOAD_KEY];
    [userDefault synchronize];
    
    if(editMode == NormalMode){
        [autoUploadView removeFromSuperview];
        [tooBar addSubview:self.syncAlbumBtn];
    }
}

- (void)showAutoUpload{
    if ([DataManager sharedInstance].tagUploadStatus == NO) {//如果檔案上傳沒有在執行
        
        NSString *tag = [[StaticHttpRequest sharedInstance] detect3GWifi];
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"YES"]) {
            if ([tag isEqualToString:@"3G"]) {
                [autoUploadTimer invalidate];
                autoUploadTimer = nil;
                autoUploadLbl.text = _(@"Wait_Wifi");
                autoUploadProgressView.hidden = YES;
            }else if ([tag isEqualToString:@"WiFi"]) {
                autoUploadLbl.hidden = YES;
                autoUploadProgressView.hidden = NO;
                [[AutoUpload sharedInstance] doUpload:[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY]];
            }else{
                [autoUploadTimer invalidate];
                autoUploadTimer = nil;
                autoUploadLbl.text = _(@"NO_Internet");
                autoUploadProgressView.hidden = YES;
            }
        }else if ([[[NSUserDefaults standardUserDefaults] stringForKey:WIFI_ONLY_KEY] isEqualToString:@"NO"]) {
            if ([tag isEqualToString:@"3G"]) {
                autoUploadLbl.hidden = YES;
                autoUploadProgressView.hidden = NO;
                [[AutoUpload sharedInstance] doUpload:[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY]];
            }else if ([tag isEqualToString:@"WiFi"]) {
                autoUploadLbl.hidden = YES;
                autoUploadProgressView.hidden = NO;
                [[AutoUpload sharedInstance] doUpload:[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY]];
            }else{
                [autoUploadTimer invalidate];
                autoUploadTimer = nil;
                autoUploadLbl.text = _(@"NO_Internet");
                autoUploadProgressView.hidden = YES;
            }
        }
        
        autoUploadHeaderLbl.text = _(@"Camera_Upload");
        autoUploadLeftLbl.hidden = NO;
        
    }else{
        [autoUploadTimer invalidate];
        autoUploadTimer = nil;
        [self showWarnning:_(@"UPLOAD_DO")];
    }
}

- (void)setAutoUploadProgress{
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_KEY] isEqualToString:@"YES"]) {
        if ([DataManager sharedInstance].autoUploadProgressFloat == -1) {//表示網路有問題
            autoUploadLeftLbl.hidden = YES;
            autoUploadLbl.hidden = NO;
            autoUploadImageView.image = [UIImage imageNamed:@"ic_photoupload"];
            autoUploadLbl.text = _(@"NO_Internet");
            autoUploadProgressView.hidden = YES;
        }else if ([DataManager sharedInstance].autoUploadProgressFloat == -2) {//非Main Router
            autoUploadLeftLbl.hidden = YES;
            autoUploadLbl.hidden = NO;
            autoUploadImageView.image = [UIImage imageNamed:@"ic_photoupload"];
            autoUploadLbl.text = _(@"NOT_ROUTER");
            autoUploadProgressView.hidden = YES;
        }else if ([DataManager sharedInstance].autoUploadProgressFloat == -3) {//沒有開啟相簿權限
            autoUploadLeftLbl.hidden = YES;
            autoUploadLbl.hidden = NO;
            autoUploadImageView.image = [UIImage imageNamed:@"ic_photoupload"];
            autoUploadLbl.text = _(@"NOT_PHOTO");
            autoUploadProgressView.hidden = YES;
        }else if([DataManager sharedInstance].autoUploadProgressFloat == -4) {//無取得相簿資料
            autoUploadLeftLbl.hidden = YES;
            autoUploadLbl.hidden = NO;
            autoUploadImageView.image = [UIImage imageNamed:@"ic_photoupload"];
            autoUploadLbl.text = _(@"UPGRADE_OS");
            autoUploadProgressView.hidden = YES;
        }else{
            autoUploadLbl.hidden = YES;
            autoUploadProgressView.hidden = NO;
            autoUploadLeftLbl.hidden = NO;
            autoUploadProgressView.progress = [DataManager sharedInstance].autoUploadProgressFloat;
            autoUploadImageView.image = [DataManager sharedInstance].autoUploadImage;
            
            if ([[DataManager sharedInstance].autoUploadName rangeOfString:@".jpg"].length>0 || [[DataManager sharedInstance].autoUploadName rangeOfString:@".png"].length>0) {
                autoUploadHeaderLbl.text = _(@"PHOTO_Upload");
            }else{
                autoUploadHeaderLbl.text = _(@"VIDEO_Upload");
            }
            
            if ([DataManager sharedInstance].autoUploadLeft == 1) {
                autoUploadLeftLbl.text = [NSString stringWithFormat:_(@"LEFT_DO1"), [DataManager sharedInstance].autoUploadLeft];
            }else{
                autoUploadLeftLbl.text = [NSString stringWithFormat:_(@"LEFT_DO"), [DataManager sharedInstance].autoUploadLeft < 0 ? 0 : [DataManager sharedInstance].autoUploadLeft];
            }
            
            if ([DataManager sharedInstance].autoUploadLeft == 0) {//表示全部上傳完成
                autoUploadHeaderLbl.text = _(@"Camera_Upload");
                autoUploadLeftLbl.hidden = YES;
                autoUploadLbl.hidden = NO;
                autoUploadImageView.image = [UIImage imageNamed:@"ic_photoupload"];
                autoUploadLbl.text = _(@"AUTO_UPLOAD_FINISH");
                autoUploadProgressView.hidden = YES;
            }else if([DataManager sharedInstance].autoUploadLeft < 0){
                autoUploadHeaderLbl.text = _(@"Camera_Upload");
                autoUploadLeftLbl.hidden = YES;
                autoUploadLbl.hidden = NO;
                autoUploadImageView.image = [UIImage imageNamed:@"ic_photoupload"];
                autoUploadLbl.text = _(@"LOADING");
                autoUploadProgressView.hidden = YES;
            }
        }
    }else{
        if ([[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY] != nil)
            [self cancelClk];
    }
}

#pragma mark - AlbumAssetsDelegate
-(void)syncFinishCallback{
    [self loadData];
}

#pragma mark - LoginViewControllerForOfflineDelegate
-(void)loginSuccessCallback{
    [self getUSBInfo];
}

#pragma mark - DownloadingViewControllerDelegate
-(void)downloadSuccessCallback{
    [self switchDownloadMode];
}

-(void)downloadCancelClickedCallback{
//    [self initAutoUpload];
}

-(UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL{
    return [[DataManager sharedInstance] imageByScalingForSize:CGSizeMake(75, 75) image:image];
}

#pragma mark - showPermisstionAlert
- (void)showPermisstionAlert{
    DialogPermissionView *dialog = nil;
    VIEW(dialog, DialogPermissionView);
    dialog.delegate = self;
    dialog.titleLbl.text = _(@"NOT_PHOTO");
    dialog.imageView.image = [UIImage imageNamed:_(@"Photo_Permission")];
    dialog.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

#pragma mark - QBImagePickerControllerDelegate
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
        if ([assets count] == 0) return;
        
        if ([[DataManager sharedInstance] autoUploadLeft] > 0) {
            [self showWarnning:_(@"AUTO_UPLOAD_DO")];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *uploadItems = [NSMutableArray array];
            __block NSString *errorString = nil;
            
            PHImageManager *manager = [PHImageManager defaultManager];
            for (PHAsset *asset in assets) {
                PHImageRequestOptions *option = [PHImageRequestOptions new];
                option.synchronous = YES;
                
                [manager requestImageDataForAsset:asset
                                          options:option
                                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                        
                                        BOOL tagIfPhotoUpload = NO;
                                        
                                        if (imageData) {
                                            NSUInteger imageSize = imageData.length;
                                            
                                            NSUInteger fileSizeMB = imageSize / (1024 * 1024 );
                                            if (fileSizeMB > 1.5 * 1024) {//超過1.5G不允許上傳
                                                tagIfPhotoUpload = NO;
                                            }else{
                                                tagIfPhotoUpload = YES;
                                            }
                                            
                                            if (tagIfPhotoUpload == YES) {
                                                
                                                NSString *fileName = nil;
                                                NSArray *parts = [asset.localIdentifier componentsSeparatedByString:@"/"];
                                                NSString *assetID = [parts objectAtIndex:0];
                                                
                                                NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
                                                NSString *ext = path.pathExtension;
                                                
                                                fileName = [NSString stringWithFormat:@"%@.%@", assetID, ext];
                                                
                                                NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                                                
                                                [imageData writeToFile:filePath atomically:YES];
                                                
                                                [uploadItems addObject:fileName];
                                            }else{
                                                errorString = _(@"UPLOAD_ALERT");
                                            }
                                        }else{
                                            errorString = _(@"Operation_Failed");
                                        }
                                    }];
                
                if(errorString)
                    break;
            }
            
            if(errorString)
                [self showWarnning:errorString];
            else{
                // 上傳
                UploadingViewController_online * uploadingViewController = [[UploadingViewController_online alloc] initWithNibName:@"UploadingViewController_online" bundle:nil];
                uploadingViewController.uploadItems = [uploadItems copy];
                [uploadingViewController setFromAlbum:YES];
                uploadingViewController.uploadSuccessCallback = ^{
                    [self.loadingView startAnimating];
                    [self.view setUserInteractionEnabled:NO];
                    self.loadingView.hidden = NO;
                    
                    [self loadData];
                };
                [self presentViewController:uploadingViewController animated:YES completion:nil];
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
