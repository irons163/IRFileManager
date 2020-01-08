//
//  PhotoCollectionViewController.h
//  EnSmart
//
//  Created by Phil on 2015/8/26.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AutoSyncPhotos.h"
#import "LoginViewControllerForOffline.h"
#import "OfflineFGalleryViewController.h"
#import <QBImagePickerController/QBImagePickerController.h>

@interface PhotoCollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, AutoSyncPhotosDelegate, LoginViewControllerForOfflineDelegate, FGalleryViewControllerDelegate, QBImagePickerControllerDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIImageView *collectionViewBottomLineImageView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) IBOutlet UIButton *syncAlbumBtn;

- (IBAction)syncAlbumClick:(id)sender;
- (IBAction)IBActiongotoOnlineModeClickidsender:(id)sender;
@end
