//
//  IntroductionViewController.m
//  EnShare
//
//  Created by Phil on 2017/4/17.
//  Copyright © 2017年 Senao. All rights reserved.
//

#import "IntroductionViewController.h"
//#import "dataDefine.h"
#import "Masonry.h"
#import "StaticLanguage.h"
#import "DefineKeys.h"

@interface IntroductionViewController (){
    
    IBOutlet UIScrollView *introductionScrollView;
    IBOutlet UIPageControl *pageControl;
    IBOutlet UIView *introductionPage1;
    IBOutlet UILabel *introductionPage1Title1;
    IBOutlet UILabel *introductionPage1Title2;
    IBOutlet UILabel *introductionPage2Title1;
    IBOutlet UILabel *introductionPage2Title2;
    IBOutlet UILabel *introductionPage3Title;
    IBOutlet UILabel *introductionPage3Info;
    IBOutlet UILabel *introductionPage4Title;
    IBOutlet UILabel *introductionPage4Info;
    IBOutlet UILabel *introductionPage5Title;
    IBOutlet UILabel *introductionPage6Title1;
    IBOutlet UIView *introductionPage2;
    IBOutlet UIView *introductionPage3;
    IBOutlet UIView *introductionPage4;
    IBOutlet UIView *introductionPage5;
    IBOutlet UIView *introductionPage6;
    IBOutlet UIButton *doneButton;
    
    NSArray *photosArray;
}

@end

@implementation IntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    photosArray = @[introductionPage5,
                    introductionPage1,
                    introductionPage2,
                    introductionPage3,
                    introductionPage4,
                    introductionPage6];
    
    [introductionScrollView addSubview:introductionPage1];
    [introductionScrollView addSubview:introductionPage2];
    [introductionScrollView addSubview:introductionPage3];
    [introductionScrollView addSubview:introductionPage4];
    [introductionScrollView addSubview:introductionPage5];
    [introductionScrollView addSubview:introductionPage6];
    
    [introductionPage1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.left.and.top.equalTo(introductionScrollView);
        make.bottom.equalTo(self.view);
    }];
    
    [introductionPage2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(introductionScrollView);
        make.left.equalTo(introductionPage1.mas_right);
        make.bottom.equalTo(self.view);
    }];
    
    [introductionPage3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(introductionScrollView);
        make.left.equalTo(introductionPage2.mas_right);
        make.bottom.equalTo(self.view);
    }];
    
    [introductionPage4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(introductionScrollView);
        make.left.equalTo(introductionPage3.mas_right);
        make.bottom.equalTo(self.view);
    }];
    
    [introductionPage5 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(introductionScrollView);
        make.left.equalTo(introductionPage4.mas_right);
        make.bottom.equalTo(self.view);
    }];
    
    [introductionPage6 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(introductionScrollView);
        make.left.equalTo(introductionPage5.mas_right);
        make.right.equalTo(introductionScrollView);
        make.bottom.equalTo(self.view);
    }];
    
    introductionPage1Title1.text = _(@"INTRODUCTION_P1_TITLE1");
    [introductionPage1Title1 sizeToFit];
    introductionPage1Title2.text = _(@"INTRODUCTION_P1_TITLE2");
    [introductionPage1Title2 sizeToFit];
    introductionPage2Title1.text = _(@"INTRODUCTION_P2_TITLE1");
    [introductionPage2Title1 sizeToFit];
    introductionPage2Title2.text = _(@"INTRODUCTION_P2_TITLE2");
    [introductionPage2Title2 sizeToFit];
    introductionPage3Title.text = _(@"INTRODUCTION_P3_TITLE");
    [introductionPage3Title sizeToFit];
    introductionPage3Info.text = _(@"INTRODUCTION_P3_INFO");
    [introductionPage3Info sizeToFit];
    introductionPage4Title.text = _(@"INTRODUCTION_P4_TITLE");
    [introductionPage4Title sizeToFit];
    introductionPage4Info.text = _(@"INTRODUCTION_P4_INFO");
    [introductionPage4Info sizeToFit];
    introductionPage5Title.text = _(@"INTRODUCTION_P5_TITLE");
    [introductionPage5Title sizeToFit];
    introductionPage6Title1.text = _(@"INTRODUCTION_P6_TITLE1");
    [introductionPage6Title1 sizeToFit];
    
    [doneButton setTitle:_(@"SKIP") forState:UIControlStateNormal];

    [introductionScrollView setPagingEnabled:YES];
    [introductionScrollView setShowsHorizontalScrollIndicator:NO];
    [introductionScrollView setShowsVerticalScrollIndicator:NO];
    [introductionScrollView setScrollsToTop:NO];
    
    [pageControl setNumberOfPages:photosArray.count];
    [pageControl setCurrentPage:0];
    [self updateDotBorder];
    
//    [self updateAllViewsConstraints:self.view];
//    for(NSLayoutConstraint *c in self.view.constraints){
//        if(c.secondAttribute == NSLayoutAttributeTopMargin){
//            NSLog(@"TopMargin");
//            [NSLayoutConstraint deactivateConstraints:@[c]];
//            [NSLayoutConstraint constraintWithItem:c.firstItem attribute:c.firstAttribute relatedBy:c.relation toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:c.multiplier constant:c.constant].active = YES;
//        }
//    }
}

//-(void)updateAllViewsConstraints:(UIView*)rootView{
//    for(NSLayoutConstraint *c in rootView.constraints){
//        if(c.secondAttribute == NSLayoutAttributeTopMargin){
//            NSLog(@"TopMargin");
//        }
//    }
//
//    for(UIView *subView in rootView.subviews){
//        [self updateAllViewsConstraints:subView];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [self updatePhotoSingleView];
}

- (void)viewWillAppear:(BOOL)animated{
    
}

-(void)viewDidAppear:(BOOL)animated{
    
    
    [self updateDotBorder];
}

- (void)updatePhotoSingleView{
    //UIPageControl設定
    CGFloat width, height;
    CGFloat paddingForPhotoSingleDisplayScrollView = 0.0f;
    width = introductionScrollView.frame.size.width;
    height = introductionScrollView.frame.size.height - paddingForPhotoSingleDisplayScrollView * 2;
    [introductionScrollView setContentSize:CGSizeMake(width * photosArray.count, height)];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat width = introductionScrollView.frame.size.width;
    NSInteger currentPage = ((introductionScrollView.contentOffset.x - width / 2) / width) + 1;
    [pageControl setCurrentPage:currentPage];
    
#ifdef MESSHUDrive
    if(currentPage == pageControl.numberOfPages - 1){
        [doneButton setTitle:_(@"COMPLETED") forState:UIControlStateNormal];
    }else{
        [doneButton setTitle:_(@"SKIP") forState:UIControlStateNormal];
    }
#endif
}

- (void)updateDotBorder{
#ifdef MESSHUDrive
    pageControl.pageIndicatorTintColor = [UIColor blackColor];
    pageControl.currentPageIndicatorTintColor = [UIColor redColor];
#else
    for (int i = 0; i < pageControl.numberOfPages; i++) {
        UIView* dot = [pageControl.subviews objectAtIndex:i];
        dot.layer.borderColor = [UIColor grayColor].CGColor;
        dot.layer.borderWidth = 1;
        
        [dot layoutIfNeeded];
    }
#endif
}

- (IBAction)changeCurrentPage:(UIPageControl *)sender {
    NSInteger page = pageControl.currentPage;
    
    CGFloat width, height;
    width = introductionScrollView.frame.size.width;
    height = introductionScrollView.frame.size.height;
    CGRect frame = CGRectMake(width*page, 0, width, height);
    
    [introductionScrollView scrollRectToVisible:frame animated:YES];
}

- (IBAction)doneClick:(id)sender {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"YES" forKey:INTRODUCTION_KEY];
    [userDefault synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
