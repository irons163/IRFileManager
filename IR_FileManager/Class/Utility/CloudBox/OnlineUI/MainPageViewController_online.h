//
//  MainPageViewController.h
//  EnSmart
//
//  Created by Phil on 2015/8/17.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AssetsLibrary/AssetsLibrary.h>
#import "DeviceClass.h"
#import "LayoutGuildReplaceViewController.h"

//#import "LoginViewController.h"
//@class LoginViewController;

@protocol LoginDelegate<NSObject>
- (void) doLoginWithUID:(NSString*)uid WithLocalIP:(NSString*)ipAddress loginDelegate:(id<deviceClassDelegate>) loginDelegate;
@end

@interface MainPageViewController_online : LayoutGuildReplaceViewController<LoginDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UILabel *documentTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *albumTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *musicTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *allTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentMeshRouterLabel;
@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (nonatomic, strong) id<LoginDelegate> delegate;
- (IBAction)gotoDocumentPageClick:(id)sender;
- (IBAction)gotoVideoPageClick:(id)sender;
- (IBAction)gotoMusicPageClick:(id)sender;
- (IBAction)gotoAlbumPageClick:(id)sender;
- (IBAction)gotoAllPageClick:(id)sender;
- (IBAction)gotoOnlineModeClick:(id)sender;

-(void)refresh;

@end
