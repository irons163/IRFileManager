//
//  OnLineTabBarViewController.m
//  EnShare
//
//  Created by Phil on 2016/11/24.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "OnLineTabBarViewController.h"
#import "CommonTools.h"
#import "dataDefine.h"
#ifdef MESSHUDrive
#import "UIColor+Helper.h"
#import "ColorDefine.h"
#endif

@interface OnLineTabBarViewController ()

@end

@implementation OnLineTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotLogoutNotification) name:LogoutNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
#ifdef MESSHUDrive
    [self.tabBar setTintColor:[UIColor colorWithColorCodeString:TabbarTextColor]];
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
        [self.tabBar setUnselectedItemTintColor:[UIColor colorWithColorCodeString:TextColor]];
#endif
    
    UIImage* image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-13.png"] scaledToSize:CGSizeMake(30, 30)];
    UIImage*selectedImage = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-15.png"] scaledToSize:CGSizeMake(30, 30)];
#ifdef MESSHUDrive
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
#endif
    UITabBarItem* gotoSettingPageTarbarItem = [[UITabBarItem alloc] initWithTitle:_(@"SETTINGS_TITLE") image:image selectedImage:selectedImage];
    
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-14.png"] scaledToSize:CGSizeMake(30, 30)];
    selectedImage = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-16.png"] scaledToSize:CGSizeMake(30, 30)];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
#else
    image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-14.png"] scaledToSize:CGSizeMake(38, 30)];
    selectedImage = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-16.png"] scaledToSize:CGSizeMake(38, 30)];
#endif
    UITabBarItem* gotoPersonalStoragePageTarbarItem = [[UITabBarItem alloc] initWithTitle:_(@"PERSONAL_STORAGE_TITLE") image:image selectedImage:selectedImage];
#ifdef MESSHUDrive
    image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-17.png"] scaledToSize:CGSizeMake(30, 30)];
    selectedImage = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-18.png"] scaledToSize:CGSizeMake(30, 30)];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
#else
    image = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-17.png"] scaledToSize:CGSizeMake(20, 30)];
    selectedImage = [CommonTools imageWithImage:[UIImage imageNamed:@"router_cut-18.png"] scaledToSize:CGSizeMake(20, 30)];
#endif
    UITabBarItem* gotoAboutPageTarbarItem = [[UITabBarItem alloc] initWithTitle:_(@"ABOUT_TITLE") image:image selectedImage:selectedImage];
    
    //    NSArray *threeViewControllers = [[NSArray alloc]initWithObjects:gotoSettingPageTarbarItem, gotoSettingPageTarbarItem, gotoSettingPageTarbarItem, nil];
    //    [self setTabBarItem:gotoSettingPageTarbarItem];
    
    UITabBarItem* item = ((UITabBarItem*)[[self.tabBar items] objectAtIndex:0]);
    item.title = gotoSettingPageTarbarItem.title;
    item.image = gotoSettingPageTarbarItem.image;
    item.selectedImage = gotoSettingPageTarbarItem.selectedImage;
    
    item = ((UITabBarItem*)[[self.tabBar items] objectAtIndex:1]);
    item.title = gotoPersonalStoragePageTarbarItem.title;
    item.image = gotoPersonalStoragePageTarbarItem.image;
    item.selectedImage = gotoPersonalStoragePageTarbarItem.selectedImage;
    
    item = ((UITabBarItem*)[[self.tabBar items] objectAtIndex:2]);
    item.title = gotoAboutPageTarbarItem.title;
    item.image = gotoAboutPageTarbarItem.image;
    item.selectedImage = gotoAboutPageTarbarItem.selectedImage;
    
    [self setSelectedIndex:1];
}

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    NSUInteger index = [tabBar.items indexOfObject:item];
    
    if ([[self viewControllers][index] isKindOfClass:[UINavigationController class]])
    {
        [(UINavigationController *)[self viewControllers][index] popToRootViewControllerAnimated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LogoutNotification object:nil];
}

- (void)gotLogoutNotification
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
