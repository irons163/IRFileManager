//
//  DiskTableViewCell.h
//  EnShare
//
//  Created by Phil on 2017/2/16.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiskTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *diskImageView;
@property (strong, nonatomic) IBOutlet UILabel *partitionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *checkedIcon;
@end
