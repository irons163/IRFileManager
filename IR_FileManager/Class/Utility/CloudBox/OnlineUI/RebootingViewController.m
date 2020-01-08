//
//  RebootingViewController.m
//  EnShare
//
//  Created by Phil on 2016/12/16.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "RebootingViewController.h"
#import "UIColor+Helper.h"
#import "RouterGlobal.h"
#import "dataDefine.h"

@interface RebootingViewController ()

@end

@implementation RebootingViewController{
    int timerCount;
    NSTimer *autoTimer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
#ifdef MESSHUDrive
    self.rebootTitleLabel.textColor = [UIColor whiteColor];
#else
    self.rebootTitleLabel.textColor = [UIColor colorWithRGB:0x00b4f5];
#endif
    
    [self showTime];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showTime{
    timerCount = 59;
    autoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(goTimer:) userInfo:nil repeats:YES];
}

- (void)goTimer:(NSTimer *)theTimer{
    if (timerCount == 59) {
        [self performSelectorInBackground:@selector(reboot) withObject:nil];
    }
    
    self.timerLbl.text = [NSString stringWithFormat:@"%d",timerCount];
    if (timerCount == 0) {
        [autoTimer invalidate];
        autoTimer = nil;
        [self logout];
    }
    timerCount --;
}

- (void)reboot{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    [global reboot:^(NSDictionary *resultDictionary) {
        NSLog(@"%@",resultDictionary);
    }];
}

- (void)logout{
    //    [self.navigationController popToRootViewControllerAnimated:YES];
    //    [self.navigationController.parentViewController dismissViewControllerAnimated:YES completion:nil];
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
