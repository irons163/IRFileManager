//
//  PhotoCollectionViewController.h
//
//  Created by Phil on 2015/8/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "AutoSyncPhotos.h"
#import <IRGallery/IRGallery.h>
#import <QBImagePickerController/QBImagePickerController.h>

@interface PhotoCollectionViewController : UIViewController<UICollectionViewDelegate, UITextFieldDelegate, IRGalleryViewControllerSourceDelegate, IRGalleryViewControllerDelegate, QBImagePickerControllerDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIImageView *collectionViewBottomLineImageView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) IBOutlet UIButton *syncAlbumBtn;

- (IBAction)syncAlbumClick:(id)sender;

@end
