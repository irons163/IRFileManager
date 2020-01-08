//
//  MeshRouterSelectionViewController.h
//  EnShare
//
//  Created by Phil on 2017/3/16.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainPageViewController_online.h"
#import "DeviceClass.h"
#import "LayoutGuildReplaceViewController.h"

@interface MeshRouterSelectionViewController : LayoutGuildReplaceViewController<deviceClassDelegate>{
    IBOutlet UITableView *table;
    IBOutlet UIActivityIndicatorView *loadingView;
    IBOutlet UILabel *meshRouterSelectMsgLabel;
}

@property (nonatomic, strong) id<LoginDelegate> delegate;
@property (nonatomic, strong) void (^meshRouterChangedSuccessCallback)(void);

@end
