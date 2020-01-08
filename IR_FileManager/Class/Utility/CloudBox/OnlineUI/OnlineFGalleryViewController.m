//
//  OnlineFGalleryViewController.m
//  EnShare
//
//  Created by Phil on 2016/12/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "OnlineFGalleryViewController.h"
#ifdef enshare
#import "SenaoGA.h"
#endif

@interface OnlineFGalleryViewController ()

@end

@implementation OnlineFGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [super setAccessibilityElementsHidden:YES];

}

- (void)setNavigatinItem {
    self.navigationItem.hidesBackButton = YES;
    UIView* leftview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage* backImage = [UIImage imageNamed:@"router_cut-27.png"];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:backImage forState:UIControlStateNormal];
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect backButtonFrame = backButton.frame;
    backButtonFrame.origin.x = 0;
    backButtonFrame.origin.y = 5;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(closeClk:) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)createToolbarItems{
    [super createToolbarItems];
    
    [_barItems removeObject:_favoriteButton]; //remove favorite button.
}

-(void)shareClk:(id)sender{
    [self shareForFile];
    
#ifdef enshare
    [SenaoGA setEvent:nil Action:@"Storage_Edit-Share" Label:nil Value:nil];
#endif
}

-(void)shareForFile{
    NSString *filePath = [self.delegate photoGallery:self filePathAtIndex:_currentIndex];
    
        // 下載檔案
        [[DataManager sharedInstance] download:filePath type:nil completion:^(NSString *file) {
            // 分享
            [self shareByFileURLStringWithPath:file];
        } error:^(void) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DOWNLOAD_ALERT", nil)
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
