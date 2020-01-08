//
//  NotificationCenterMainViewController.h
//  EnShare
//
//  Created by Phil on 2016/12/14.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationItem : NSObject
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * subtitle;
@property (nonatomic, strong) NSString * message;
@property (nonatomic, strong) NSDate * date;

-(id)initWithTitle:(NSString*)title subtitle:(NSString*)subtitle message:(NSString*)message date:(NSDate*)date;
@end

@interface NotificationCenterMainViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
