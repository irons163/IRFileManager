//
//  NotificationCenterViewController.m
//  EnShare
//
//  Created by Titan Chen on 2016/12/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "NotificationCenterViewController.h"
#import "UIColor+Helper.h"
#import "KGModal.h"
#import "SuccessView.h"

@interface NotificationCenterViewController ()

@end

@implementation NotificationCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = YES;
    UIImage* backImage = [UIImage imageNamed:@"btn_nav_back.png"];
    UIImage* iBackImage = [UIImage imageNamed:@"ibtn_nav_back"];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:backImage forState:UIControlStateNormal];
    if (iBackImage) {
        [backButton setImage:iBackImage forState:UIControlStateHighlighted];
    }
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect backButtonFrame = backButton.frame;
    backButtonFrame.origin.x = 0;
    backButtonFrame.origin.y = 10;
    backButtonFrame.size.width = 90.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    [backButton setTitle:_(@"Back") forState:UIControlStateNormal];
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-40];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    shareButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [shareButton setTitle:_(@"Share") forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor colorWithColorCodeString:@"1BA48A"] forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(shareClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight, rightItem, nil];
    
    self.notificaitonTitle.text = self.item.title;
    self.notificationSubTitle.text = self.item.subtitle;
    self.notificationMessage.text = self.item.message;
    [self.notificaitonTitle sizeToFit];
    [self.notificationMessage sizeToFit];
    
    self.notificationSubTitle.frame = CGRectMake(self.notificationSubTitle.frame.origin.x, self.notificaitonTitle.frame.origin.y + self.notificaitonTitle.frame.size.height, self.notificationSubTitle.frame.size.width, self.notificationSubTitle.frame.size.height);
    self.lineImageView.frame = CGRectMake(self.lineImageView.frame.origin.x, self.notificationSubTitle.frame.origin.y + self.notificationSubTitle.frame.size.height, self.lineImageView.frame.size.width, self.lineImageView.frame.size.height);
    self.notificationMessage.frame = CGRectMake(self.notificationMessage.frame.origin.x, self.lineImageView.frame.origin.y + self.lineImageView.frame.size.height + 10, self.notificationMessage.frame.size.width, self.notificationMessage.frame.size.height);
    CGSize contentSize = CGSizeMake(self.view.frame.size.width, self.notificationMessage.frame.origin.y + self.notificationMessage.frame.size.height);
    self.scrollView.contentSize = contentSize;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = _(@"NOTIFICATION_CONTENT_TITLE");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)backBtnDidClick{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)shareClick{
    NSString* message = [NSString stringWithFormat:@"%@\n%@\n%@", self.item.title, self.item.subtitle, self.item.message];
    NSLog(@"shareClick string:%@",message);
    
    UIActivity *customCopyLinkActivity = [[UIActivity alloc] init];
    
    NSArray *applicationActivities = @[customCopyLinkActivity];
    
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[message] applicationActivities:applicationActivities];

    
    [activityView setCompletionWithItemsHandler:(UIActivityViewControllerCompletionWithItemsHandler)^(NSString *activityType, BOOL completed) {
        if(completed && activityType == UIActivityTypeCopyToPasteboard){
            SuccessView *successView;;
            VIEW(successView, SuccessView);
            [[KGModal sharedInstance] setShowCloseButton:FALSE];
            [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
        }
    }];
    [self presentViewController:activityView animated:YES completion:nil];
}

- (void)setUI:(NSNotification*) notification{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary* dic = [notification object];
        
        self.notificaitonTitle.text = [dic objectForKey:@"title"];
        self.notificationSubTitle.text = [dic objectForKey:@"subtitle"];
        self.notificationMessage.text = [dic objectForKey:@"message"];
        
    });
}
@end
