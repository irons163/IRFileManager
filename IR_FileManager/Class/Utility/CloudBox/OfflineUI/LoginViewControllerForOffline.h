//
//  LoginViewControllerForOffline.h
//  EnShare
//
//  Created by Phil on 2016/11/17.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "LoginViewController.h"

@protocol LoginViewControllerForOfflineDelegate <NSObject>

-(void)loginSuccessCallback;

@end

@interface LoginViewControllerForOffline : LoginViewController
-(void)addCloseBtn;

@property (nonatomic, assign) id<LoginViewControllerForOfflineDelegate> delegate;
@end
