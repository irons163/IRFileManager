//
//  LogoViewController.h
//  CloudBox
//
//  Created by Wowoya on 13/2/28.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LogoViewControllerDelegate <NSObject>

- (void)didFinishedLogoAnim;

@end

@interface LogoViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIWebView *webViewToDisplayGIF;
@property (weak) id<LogoViewControllerDelegate> delegate;
@end
