//
//  MyFavoritesCollectionViewCell.h
//  EnShare
//
//  Created by Phil on 2016/10/19.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyFavoritesCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *filenameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewe;

@property (strong, nonatomic) NSOperation *operation;

@end
