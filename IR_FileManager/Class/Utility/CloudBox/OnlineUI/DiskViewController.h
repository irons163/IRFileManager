//
//  DiskViewController.h
//  EnShare
//
//  Created by ke on 2013/12/3.
//  Copyright (c) 2013年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiskViewController : UIViewController{
//    IBOutlet UIView *mainView;
    IBOutlet UITableView *table;
    IBOutlet UIActivityIndicatorView *loadingView;
//    IBOutlet UIButton *refreshBtn;
    
    NSMutableArray *tableArray;
}

//- (IBAction)refreshClk:(id)sender;

@end
