//
//  NotificationCenterViewController.h
//  EnShare
//
//  Created by Titan Chen on 2016/12/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotificationCenterMainViewController.h"

@interface NotificationCenterViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *notificaitonTitle;
@property (weak, nonatomic) IBOutlet UILabel *notificationSubTitle;
@property (weak, nonatomic) IBOutlet UILabel *notificationMessage;
@property (strong, nonatomic) IBOutlet UIImageView *lineImageView;

@property (nonatomic, strong) NotificationItem * item;

@end
