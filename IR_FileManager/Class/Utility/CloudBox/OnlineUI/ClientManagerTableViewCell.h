//
//  ClientManagerTableViewCell.h
//  EnShare
//
//  Created by Phil on 2016/12/12.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClientManagerTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *ipInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *macInfoLabel;
@property (strong, nonatomic) IBOutlet UIButton *blockButton;

- (IBAction)blockButtonClick:(id)sender;

@property (nonatomic) id delegate;
@property (nonatomic) BOOL isConnected;
@end
