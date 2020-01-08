//
//  AboutViewController.h
//  CloudBox
//
//  Created by Wowoya on 13/4/19.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *tableView;
}

@end
