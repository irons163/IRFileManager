//
//  PhotoCollectionViewController.h
//  EnSmart
//
//  Created by Phil on 2015/8/26.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OnLineFilesViewController.h"
#import "LoginViewControllerForOffline.h"
#import "OnlineFGalleryViewController.h"
#import "DownloadingViewController_online.h"
#import <QBImagePickerController/QBImagePickerController.h>

@interface PhotoCollectionViewController_online : OnLineFilesViewController<UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, LoginViewControllerForOfflineDelegate, DownloadingViewControllerDelegate, OnlineFGalleryViewControllerDelegate, QBImagePickerControllerDelegate, UICollectionViewDelegateFlowLayout>{
    IBOutlet UIView *autoUploadView;
    IBOutlet UIImageView *autoUploadImageView;
    IBOutlet UILabel *autoUploadHeaderLbl;
    IBOutlet UILabel *autoUploadLbl;
    IBOutlet UILabel *autoUploadLeftLbl;
    IBOutlet UIProgressView *autoUploadProgressView;
    IBOutlet UIButton *autoUploadCancelButton;
//    IBOutlet UIButton *autoUploadBtn;
}
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIImageView *collectionViewBottomLineImageView;
@property (strong, nonatomic) IBOutlet UIButton *syncAlbumBtn;

- (IBAction)syncAlbumClick:(id)sender;
- (IBAction)autoUploadCancelClick:(id)sender;

//@property NSInteger* threadNum;//限定同時只能背景下載圖片10個;
@end
