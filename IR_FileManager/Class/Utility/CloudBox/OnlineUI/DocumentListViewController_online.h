//
//  DocumentList.h
//  EnSmart
//
//  Created by Phil on 2015/8/19.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "DocumentTableViewCell.h"
#import "OnLineFilesViewController.h"
#import "OnlineFGalleryViewController.h"
#import "LoginViewControllerForOffline.h"
#import "DownloadingViewController_online.h"

@interface DocumentListViewController_online : OnLineFilesViewController<UITableViewDelegate, UITableViewDataSource, OnlineFGalleryViewControllerDelegate,UITextFieldDelegate, KxVideoCallBackDelegate, PlayerViewCallBackDelegate,LoginViewControllerForOfflineDelegate,DownloadingViewControllerDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource>{
}

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *myFavoritesTitleLabel;

@property (strong, nonatomic) IBOutlet UIView *myFavoritesView;
@property (strong, nonatomic) IBOutlet UIView *viewInTopOfMyFavorites;
@property (strong, nonatomic) IBOutlet UICollectionView *myFavoritesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *myFavoritesViewBottomConstraint;

@property (strong, nonatomic) IBOutlet UILabel *sortByFileNameTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByFileSizeTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByDateTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByFileNameTypeLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByFileSizeTypeLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByDateTypeLabel;

@property (strong, nonatomic) IBOutlet UIView *sortMenuView;
@property (strong, nonatomic) IBOutlet UIView *sortByNameView;
@property (strong, nonatomic) IBOutlet UIView *sortBySizeView;
@property (strong, nonatomic) IBOutlet UIView *sortByDateView;
@property (strong, nonatomic) IBOutlet UIView *sortSelectView;
@property (strong, nonatomic) IBOutlet UIButton *sortByNameButton;
@property (strong, nonatomic) IBOutlet UIButton *sortBySizeButton;
@property (strong, nonatomic) IBOutlet UIButton *sortByDateButton;

- (IBAction)sortByNameClick:(id)sender;
- (IBAction)sortBySizeClick:(id)sender;
- (IBAction)sortByDateClick:(id)sender;
- (IBAction)sortMenuBGClick:(id)sender;

- (IBAction)myFavoritesViewClick:(id)sender;



//-(void)setItem :(NSArray*)itemsByStorageInfo;

@end
