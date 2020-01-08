//
//  firmwareViewController.h
//  EnViewerSOHO
//
//  Created by WeiJun on 2015/2/6.
//  Copyright (c) 2015年 sniApp. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "deviceConnector.h"
#import "StaticHttpRequest.h"
#import "deviceClass.h"
#import "CircleProgressView.h"

@interface firmwareViewController : UIViewController<StaticHttpRequestDelegate>
{
    UIColor *m_focusRed;
    UIColor *m_textGray;
    NSDictionary* m_upgradeResponse;
//    deviceConnector *m_DeviceConnector;
    DeviceClass* m_upgradeDevice;
    NSString* m_Token;
    CircleProgressView* circleProgress;
    NSDate *startTime;
}

-(id)initWithUpgradeResponse:(NSDictionary*)_response device:(id)_device;

@property (nonatomic ,retain) UIColor *m_focusRed;
@property (nonatomic ,retain) UIColor *m_textGray;

@property (weak, nonatomic) IBOutlet UIView *m_navView;
@property (retain, nonatomic) IBOutlet UIToolbar *m_NavigationBar;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *m_btnBack;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *m_title;
@property (retain, nonatomic) IBOutlet UILabel *versionTitle;
@property (retain, nonatomic) IBOutlet UILabel *versionDetail;
@property (retain, nonatomic) IBOutlet UILabel *releaseDateTitle;
@property (retain, nonatomic) IBOutlet UILabel *releaseDateDetail;
@property (retain, nonatomic) IBOutlet UILabel *changelogTitle;
@property (retain, nonatomic) IBOutlet UILabel *changelogDetail;
@property (retain, nonatomic) IBOutlet UILabel *noteLbl;
@property (retain, nonatomic) IBOutlet UIButton *upgradeButton;
- (IBAction)upgradeButtonClick:(id)sender;
@property (retain, nonatomic) IBOutlet UIView *progressview;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *m_loader;
@property (retain, nonatomic) IBOutlet UILabel *titleLbl;
@property (retain, nonatomic) IBOutlet UILabel *warningLbl;
@property (retain, nonatomic) IBOutlet UIButton *okButton;
- (IBAction)okClick:(id)sender;
- (IBAction)backClick:(id)sender;
@end
