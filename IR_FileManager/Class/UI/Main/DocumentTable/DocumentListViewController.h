//
//  DocumentListViewController.h
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IRGallery/IRGallery.h>
#import "DocumentTableViewCell.h"
#import "CustomCollectionView.h"
#import "DocumentListFileType.h"

NS_ASSUME_NONNULL_BEGIN

@interface DocumentListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, IRGalleryViewControllerDelegate,UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource>{
}

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;

@property (nonatomic) FILE_TYPE fileType;

@end

NS_ASSUME_NONNULL_END
