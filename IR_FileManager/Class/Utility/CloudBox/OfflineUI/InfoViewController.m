//
//  InfoViewController.m
//  EnShare
//
//  Created by Phil on 2016/11/10.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)gotoEnGeniusWebsite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.engeniustech.com"]];
}
@end
