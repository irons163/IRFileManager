//
//  DocumentList.h
//  EnSmart
//
//  Created by Phil on 2015/8/19.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DocumentTableViewCell.h"
#import "OfflineFGalleryViewController.h"
#import "LoginViewControllerForOffline.h"
#import "CustomCollectionView.h"

@interface DocumentListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, FGalleryViewControllerDelegate,UITextFieldDelegate, KxVideoCallBackDelegate, PlayerViewCallBackDelegate,LoginViewControllerForOfflineDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource>{
}

typedef enum{
    DOCUMENT_TYPE = 0,
    MUSIC_TYPE,
    VIDEO_TYPE,
    PHOTO_TYPE,
    ALL_TYPE
}FILE_TYPE;

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) IBOutlet UILabel *myFavoritesTitleLabel;

@property (strong, nonatomic) IBOutlet UIView *myFavoritesView;
@property (strong, nonatomic) IBOutlet UIView *viewInTopOfMyFavorites;
@property (strong, nonatomic) IBOutlet CustomCollectionView *myFavoritesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myFavoritesViewBottomConstraint;

@property (strong, nonatomic) IBOutlet UILabel *sortByFileNameTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByFileSizeTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByDateTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByFileNameTypeLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByFileSizeTypeLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByDateTypeLabel;

@property (strong, nonatomic) IBOutlet UIView *sortMenuView;
@property (strong, nonatomic) IBOutlet UIView *sortSelectView;
@property (strong, nonatomic) IBOutlet UIButton *sortByNameButton;
@property (strong, nonatomic) IBOutlet UIButton *sortBySizeButton;
@property (strong, nonatomic) IBOutlet UIButton *sortByDateButton;

- (IBAction)sortByNameClick:(id)sender;
- (IBAction)sortBySizeClick:(id)sender;
- (IBAction)sortByDateClick:(id)sender;
- (IBAction)sortMenuBGClick:(id)sender;

- (IBAction)myFavoritesViewClick:(id)sender;

@property (nonatomic) FILE_TYPE fileType;

@end
