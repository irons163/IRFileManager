//
//  WelcomeViewController.m
//  IR_FileManager
//
//  Created by Phil on 2018/7/9.
//  Copyright © 2018年 Phil. All rights reserved.
//

#import "WelcomeViewController.h"
#import <WebKit/WebKit.h>
#import "MainPageViewController.h"

@interface WelcomeViewController ()<UIWebViewDelegate>
{
    __weak IBOutlet UIWebView *welecomeWebView;
}
@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    welecomeWebView.scrollView.scrollEnabled = NO;
    welecomeWebView.scrollView.bounces = NO;
    
    NSData *data = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"enwifi" ofType:@"gif"]];
    [welecomeWebView loadData:data MIMEType:@"image/gif" textEncodingName:@"" baseURL:[NSURL URLWithString:@""]];
    welecomeWebView.scalesPageToFit = YES;
    [welecomeWebView setOpaque:NO];
}

- (void)gotoDeviceList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MainPageViewController *mainPageViewController = [MainPageViewController new];
        [self.navigationController presentViewController:[[UINavigationController alloc] initWithRootViewController:mainPageViewController] animated:YES completion:nil];
    });
}

#pragma mark - IBAction
- (IBAction)doWelcome:(id)sender {
    MainPageViewController *mainPageViewController = [MainPageViewController new];
    [self presentViewController:mainPageViewController animated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [NSTimer scheduledTimerWithTimeInterval:3.0
                                     target:self
                                   selector:@selector(timeToRedirect:)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - NSTimer
- (void)timeToRedirect:(NSTimer*)timer
{
    [timer invalidate];
    timer = nil;
    [self gotoDeviceList];
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:[[ScanningViewController alloc] init] animated:YES];
    });
     */
}

@end
