//
//  LoginViewController.h
//  CloudBox
//
//  Created by Wowoya on 13/2/28.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StaticHttpRequest.h"
#import "DeviceClass.h"
#import "MainPageViewController_online.h"

@interface LoginViewController : UIViewController<UITextFieldDelegate,StaticHttpRequestDelegate,deviceClassDelegate, LoginDelegate> {
    UITextField* currentTextField;
    IBOutlet UIScrollView *scrollView;
    
    IBOutlet UIButton *offlineBtn;
    IBOutlet UIButton *informationViewBtn;
    
    IBOutlet UITextField *usernameLbl;
    IBOutlet UITextField *passwordLbl;
    IBOutlet UITextField *hostLbl;
    
    IBOutlet UIButton *rememberBtn;
    IBOutlet UIButton *selectRemoteBtn;
    IBOutlet UIButton *remoteLoginBtn;
    IBOutlet UIActivityIndicatorView *loadingView;
    NSString *routerAddress;
    NSString *realRouterAddress;

    IBOutlet UILabel *dnsTitleLabel;
    IBOutlet UILabel *dnsLabel;
    
    IBOutlet UIButton *cancelUserNameBtn;
    IBOutlet UIButton *cancelPasswordBtn;
    IBOutlet UIButton *cancelHostBtn;
    
    IBOutlet UILabel *versionLabel;
    
    IBOutlet UIButton *selectUIDBtn;
    IBOutlet UIButton *selectDDNSBtn;
#ifdef MESSHUDrive
    IBOutlet UIView *hostView;
#endif
}

- (IBAction)cancelUserNameClk:(id)sender;
- (IBAction)cancelPasswordClk:(id)sender;
- (IBAction)cancelHostClk:(id)sender;

- (IBAction)remoteLoginClk:(id)sender;
- (IBAction)selectRemoteLoginClk:(id)sender;
- (IBAction)rememberClk:(id)sender;
- (IBAction)offlineClk:(id)sender;

- (IBAction)selectUIDClk:(id)sender;
- (IBAction)selectDDNSClk:(id)sender;

- (void)doLoginWithEnMesh;

@end
