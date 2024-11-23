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
    
    NSData *data = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"giphy" ofType:@"webp"]];
    [welecomeWebView loadData:data MIMEType:@"image/webp" textEncodingName:@"" baseURL:[NSURL URLWithString:@""]];
    welecomeWebView.scalesPageToFit = YES;
    [welecomeWebView setOpaque:NO];
}

- (void)gotoDeviceList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MainPageViewController *mainPageViewController = [MainPageViewController new];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainPageViewController];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.navigationBarHidden = NO;
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    });
}

#pragma mark - IBAction
- (IBAction)doWelcome:(id)sender {
    self.navigationController.navigationBarHidden = NO;
    MainPageViewController *mainPageViewController = [MainPageViewController new];
    mainPageViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:mainPageViewController animated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [NSTimer scheduledTimerWithTimeInterval:2.0
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
