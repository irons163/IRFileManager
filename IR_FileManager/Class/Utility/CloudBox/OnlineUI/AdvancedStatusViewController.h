//
//  AdvancedStatusViewController.h
//  CloudBox
//
//  Created by ke on 6/19/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "CustomDataPicker.h"
#import "LayoutGuildReplaceViewController.h"

@interface AdvancedStatusViewController : LayoutGuildReplaceViewController<MFMailComposeViewControllerDelegate, CustomDataPickerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIView *titleBackgroundView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
