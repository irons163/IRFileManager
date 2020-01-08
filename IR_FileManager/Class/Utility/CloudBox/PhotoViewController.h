//
//  PhotoViewController.h
//  EnShare
//
//  Created by ke on 2013/11/7.
//  Copyright (c) 2013年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AssetsLibrary/AssetsLibrary.h>

@protocol AlbumAssetsDelegate <NSObject>

- (void)getAlbumPhotoAssets:(NSArray *)info;
- (void)getAlbumVideoAssets:(NSArray *)info;

@end

@interface PhotoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UILabel *loadingLbl;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (strong, nonatomic) IBOutlet UIButton *doneBtn;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIView *infoView;
@property (strong, nonatomic) IBOutlet UILabel *selectNumLbl;
@property (strong, nonatomic) IBOutlet UIView *permissionView;
@property (strong, nonatomic) IBOutlet UILabel *selectedLbl;

@property (nonatomic, assign) id<AlbumAssetsDelegate> delegate;

- (void)doDelegate;
- (IBAction)backClk:(id)sender;
- (IBAction)doneClk:(id)sender;
- (IBAction)selectAllClk:(id)sender;

@end
