//
//  NotificationCenterMainTableViewCell.h
//  EnShare
//
//  Created by Phil on 2016/12/14.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationCenterMainTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *notificationView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *checkboxButton;
@end
