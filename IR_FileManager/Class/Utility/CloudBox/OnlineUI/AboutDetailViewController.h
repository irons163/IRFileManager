//
//  AboutDetailViewController.h
//  EnShare
//
//  Created by Phil on 2016/12/8.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMHTMLView.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "LayoutGuildReplaceViewController.h"

typedef enum{
    GENERAL_TYPE = 0,
    LEGAL_INFO_TYPE,
    FAQ_TYPE
}ABOUT_TYPE;

@interface AboutDetailViewController : LayoutGuildReplaceViewController <MFMailComposeViewControllerDelegate>{
    IBOutlet UIView *mainView;
    IBOutlet UIView *contentView;
    IBOutlet UIButton *mailBtn;
    IBOutlet UIButton *ppBtn;
//    IBOutlet UIButton *eBtn;
    //CMHTMLView *htmlView;
    UIWebView *htmlView;
}

- (IBAction)mailClk:(id)sender;
- (IBAction)ppClk:(id)sender;
//- (IBAction)eClk:(id)sender;

@property ABOUT_TYPE aboutType;

@end
