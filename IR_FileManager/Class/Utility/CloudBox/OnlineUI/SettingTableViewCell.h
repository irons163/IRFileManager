//
//  SettingTableViewCell.h
//  EnShare
//
//  Created by Phil on 2016/12/13.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *hintLabel;
@property (strong, nonatomic) IBOutlet UIImageView *seperatorLineImageView;

- (void)changeToOneLine;
- (void)changeToTwoLine;
@end
