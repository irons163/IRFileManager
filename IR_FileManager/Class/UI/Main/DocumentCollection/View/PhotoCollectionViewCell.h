//
//  PhotoCollectionViewCell.h
//
//  Created by Phil on 2016/10/28.
//

#import <UIKit/UIKit.h>

@interface PhotoCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageview;
@property (strong, nonatomic) IBOutlet UIImageView *checkboxImageView;

+ (NSString *)identifier;

@end
