//
//  LoginViewControllerForOffline.m
//  EnShare
//
//  Created by Phil on 2016/11/17.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "LoginViewControllerForOffline.h"

@interface LoginViewControllerForOffline ()

@end

@implementation LoginViewControllerForOffline

-(void)addCloseBtn{
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(3, 80, 100, 40)];
    [closeBtn setTitle:_(@"Close") forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [super.self.view addSubview:closeBtn];
}

-(void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)checkFirmwareVesrion{
    //override to do nothing.
}

-(void)gotoStorageViewController{
    //override to back.
    [self close];
    [self.delegate loginSuccessCallback];
}


@end
