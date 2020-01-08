//
//  firmwareViewController.m
//  EnViewerSOHO
//
//  Created by WeiJun on 2015/2/6.
//  Copyright (c) 2015年 sniApp. All rights reserved.
//

#import "firmwareViewController.h"
#import "AppDelegate.h"
//#import "RDVRootViewController.h"
#import "deviceClass.h"
//#import "StaticLoginInfo.h"
#import "dataDefine.h"

#define TIME_LIMIT 300.0f

@interface firmwareViewController ()

@property (strong, nonatomic) NSTimer *timer;

@end

@implementation firmwareViewController
@synthesize m_NavigationBar;
@synthesize m_focusRed ,m_textGray;


-(id)initWithUpgradeResponse:(NSDictionary*)_response device:(id)_device{
    if (![super init]) {
        return nil;
    }
    
    m_upgradeResponse = _response;
    
    if ([_device isKindOfClass:[DeviceClass class]]) {
        m_upgradeDevice = _device;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.m_textGray = [UIColor colorWithRed:61.0f/255.0f green:61.0f/255.0f blue:61.0f/255.0f alpha:1.0f];
    self.m_focusRed = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
    self.m_textGray = self.m_focusRed;
    
    [m_NavigationBar setTranslucent:YES];
    //[self.view bringSubviewToFront:self.m_NavigationBar];
    
    self.title = @"    Detail    ";
    
    self.noteLbl.text = NSLocalizedString(@"NOTE_MESSAGE", nil);
    
    [self initTitleBarAndBackground];
    
    self.versionTitle.text = [NSString stringWithFormat:@"%@" ,NSLocalizedString(@"NEW_VERSION_TITLE", nil)];
    self.versionDetail.text = [m_upgradeResponse objectForKey:@"version"];
    self.releaseDateTitle.text = [NSString stringWithFormat:@"%@" ,NSLocalizedString(@"RELEASE_DATE_TITLE", nil)];
    self.releaseDateDetail.text = [m_upgradeResponse objectForKey:@"release_date"];
    self.changelogTitle.text = [NSString stringWithFormat:@"%@" ,NSLocalizedString(@"CHANGE_LOG", nil)];
    self.changelogDetail.text = [self convertChangeLog:[m_upgradeResponse objectForKey:@"change_log"]];
    [self.changelogDetail sizeToFit];
    
    if ([self getIosVersion] < 7) {
        self.view.frame = CGRectMake(0, -20, self.view.frame.size.width, self.view.frame.size.height+20);
    }
}

//-(void)viewDidAppear:(BOOL)animated{
//    [self adjustUI];
//}

-(void)viewDidUnload{
    [self setM_NavigationBar:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    //[self.view bringSubviewToFront:self.m_NavigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 1. title bar background and title
 2. back button icon and title
 3. background has page button or not
 */
-(void) initTitleBarAndBackground
{
    //you can use any string instead "com.mycompany.myqueue"
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.mycompany.myqueue", 0);
    
    dispatch_async(backgroundQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat iOffset = [self getIosVersion] >= 7 ? 10.0f : 10.0f;
            CGFloat hoffset = [self getIosVersion] >= 7 ? 10.0f : -5.0f;
            
            
            if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
            {
                hoffset = [self getIosVersion] >= 7 ? 0 : -5.0f;
            }
            
            CGRect tmpNaviRect =  self.m_NavigationBar.frame;
            if([self getIosVersion] >= 7)
            {
                tmpNaviRect.size.height = 64.0f;
                tmpNaviRect.origin.y = 0.0f;
                [self.m_NavigationBar setFrame:tmpNaviRect];
            }
            UIImage *image = [UIImage imageNamed:@"btn_Nav_back.png"];
            UIImage* iBackImage = [UIImage imageNamed:@"ibtn_nav_back"];
            CGRect buttonFrame = CGRectMake(0-iOffset, image.size.height/2/2+hoffset, image.size.width/2, image.size.height/2);
            
            if([self getIosVersion] < 7)
            {
                buttonFrame = CGRectMake(0, image.size.height/2/2+hoffset, image.size.width/2, image.size.height/2);
            }
            
            UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
            CGRect txtBtnRect = CGRectMake(image.size.width-10-iOffset, hoffset, 50, 44);
            if([self getIosVersion] < 7)
            {
                txtBtnRect = CGRectMake(image.size.width-10, hoffset, 50, 44);
            }
            UIButton *txtBtn = [[UIButton alloc] initWithFrame:txtBtnRect];
            [txtBtn setTitle:NSLocalizedString(@"ButtonTextBack", nil) forState:UIControlStateNormal];
            [txtBtn.titleLabel setFont:[UIFont systemFontOfSize:20.0f]];
            UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(0-iOffset*2, hoffset, image.size.width + txtBtn.frame.size.width, 44)];
            [tmpView addSubview:button];
            [tmpView addSubview: txtBtn];
            [button addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchDown];
            [txtBtn addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchDown];
            [button setImage:image forState:UIControlStateNormal];
            if (iBackImage) {
                [button setImage:iBackImage forState:UIControlStateHighlighted];
            }
            [self.m_btnBack setCustomView:tmpView];
            
            NSInteger iTitleLength = [self getTitleLengthByBackButtonSize:tmpView.frame.size.width streamBtnWidth:tmpView.frame.size.width];
            
            UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake(0-iOffset/2 - 4.0f, hoffset, iTitleLength + 15, 44.0f)];
            navLabel.backgroundColor = [UIColor clearColor];
            [navLabel setText:self.title];
            navLabel.textAlignment = NSTextAlignmentCenter;
            [ navLabel setFont:[UIFont systemFontOfSize:20.0f]];
            [ navLabel setTextColor:self.m_focusRed];
            
            UIView *tmpTitle = [[UIView alloc] initWithFrame:CGRectMake(0.0f - iOffset/2, 0, iTitleLength, 44.0f)];
            [tmpTitle addSubview:navLabel];
            [self.m_title setCustomView:tmpTitle];
            
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] > 4.9)
            {
                //iOS 5
                UIImage *toolBarIMG = [UIImage imageNamed: @"bg_nav.png"];
                
                if ([self.m_NavigationBar respondsToSelector:@selector(setBackgroundImage:forToolbarPosition:barMetrics:)]) {
                    [self.m_NavigationBar setBackgroundImage:toolBarIMG forToolbarPosition:0 barMetrics:0];
                }
            } else {
                //iOS 4
                [self.m_NavigationBar insertSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_nav.png"]] atIndex:0];
            }
            
        });
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    
}

-(void)goback
{
    AppDelegate* appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (!appdelegate.isUpgrading) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        }else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(NSInteger) getTitleLengthByBackButtonSize:(NSInteger) _backButtonSize streamBtnWidth:(NSInteger)_streamButtonSize
{
    //NSInteger iTitleLength = [self.title length] * 20;
    CGFloat iTitleLength = [self.title sizeWithFont:[UIFont fontWithName:@"Helvetica" size:20.0]].width;
    CGRect currentRect = [self getCurrentScreenSizeByOrientation:NO];
    
    NSLog(@"%f",currentRect.size.width);
    if (currentRect.size.width - _backButtonSize - _streamButtonSize < iTitleLength)
    {
        iTitleLength = currentRect.size.width - _backButtonSize - _streamButtonSize - 10.0f -16.0f;
    }
    
    return iTitleLength;
}

//get current screen width & height
-(CGRect) getCurrentScreenSizeByOrientation:(BOOL) blnIncludeFuncaionBars;
{
    CGRect rtnRect;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    CGFloat setHeight = screenHeight;
    CGFloat setWidth = screenWidth;
    
    
    //    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
    if([UIApplication sharedApplication].statusBarOrientation  > 2)
    {//if landscape mode , switch width and height
        setHeight = screenWidth;
        setWidth = screenHeight;
        
        
        setWidth = screenHeight > screenWidth ? screenHeight : screenWidth;
        setHeight = screenHeight < screenWidth ? screenHeight : screenWidth;
        NSLog(@"getCurrentScreenSizeByOrientation:%d width=%f height=%f"
              ,[UIApplication sharedApplication].statusBarOrientation
              ,setWidth,setHeight);
    }
    else
    {//if portrait mode , screen height need deduct status bar and navigation bar's height
        if(blnIncludeFuncaionBars)
        {
            setHeight -= self.m_NavigationBar.frame.size.height;
            UIApplication *application = [UIApplication sharedApplication];
            setHeight -= application.statusBarFrame.size.height;
        }
    }
    rtnRect = CGRectMake(0, 0, setWidth, setHeight);
    
    NSLog(@"width=%f height=%f"          ,setWidth,setHeight);
    return rtnRect;
}

-(void)adjustUI
{
    return;//2015/03/12 By Daniel
    CGRect screenRect = [self getScreenSize];
    CGRect tbRect = self.view.frame;
    CGFloat fStatusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat fNavBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    if ([self getIosVersion] < 7)
    {
        tbRect.size.height = [self getIosVersion] >= 7 ? screenRect.size.height - 100 : screenRect.size.height - fStatusHeight - fNavBarHeight;
        tbRect.size.height = screenRect.size.height - fStatusHeight - fNavBarHeight;
        //            [self.view setFrame:screenRect];
        
    }
    tbRect.size.width = screenRect.size.width;
    tbRect.size.height = screenRect.size.height;
    
    [self.view setFrame:tbRect];
}

-(CGRect) getScreenSize;
{
    CGRect rtnRect;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    CGFloat setHeight = screenHeight;
    CGFloat setWidth = screenWidth;
    
    if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {//if landscape mode , switch width and height
        setHeight = screenWidth;
        setWidth = screenHeight;
    }
    
    rtnRect = CGRectMake(0, 0, setWidth, setHeight);
    return rtnRect;
}

-(NSInteger) getIosVersion
{
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    return [[vComp objectAtIndex:0] intValue];
}

-(void)showProgress{
    [self.m_loader stopAnimating];
    
    AppDelegate* appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appdelegate.isUpgrading = YES;
    self.upgradeButton.userInteractionEnabled = NO;
    
    if (!circleProgress) {
        circleProgress = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, 130, 130)];
        circleProgress.numberColor = [UIColor whiteColor];
        circleProgress.circleColor = [UIColor whiteColor];
        [self.progressview addSubview:circleProgress];
        circleProgress.center = self.progressview.center;
    }
    
    [circleProgress update:0];
    
    self.titleLbl.text = [NSString stringWithFormat:@"%@" ,NSLocalizedString(@"UPGRADING_TITLE", nil)];
    self.warningLbl.text = [NSString stringWithFormat:@"%@" ,NSLocalizedString(@"UPGRADING_WARNING", nil)];
    
    startTime = [NSDate date];
    
    self.progressview.hidden = NO;
    
    [self startTimer];
}

-(void)stopProgress{
    [self.timer invalidate];
    self.timer = nil;
    
    self.titleLbl.text = [NSString stringWithFormat:@"%@" ,NSLocalizedString(@"UPGRADE_FINISH_TITLE", nil)];
    self.warningLbl.hidden = YES;
    
    self.okButton.hidden = NO;
    [self.progressview bringSubviewToFront:self.okButton];
}

-(void)doUpgrade{
    NSInteger commandPort = m_upgradeDevice.commandHttpsAgentPort;
    if ([m_upgradeDevice.scheme isEqualToString:@"http"]) {
        commandPort = m_upgradeDevice.commandHttpAgentPort;
    }
    NSString *strCmd =[NSString stringWithFormat:UPGRADE_FIRMWARE
                       ,m_upgradeDevice.scheme
                       ,m_upgradeDevice.commandDeviceAddress
                       ,commandPort
                       ];
    
    NSError *err;
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:[m_upgradeResponse objectForKey:@"id"],@"id", nil] options:0 error:&err];
    
    NSString *JSONString = [[NSString alloc] initWithBytes:[sendData bytes] length:[sendData length] encoding:NSUTF8StringEncoding];

//    [[StaticHttpRequest sharedInstance] doLoginRequestWithUrl:strCmd Body:nil CallbackID:0 Target:self];
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:strCmd Method:@"POST" Body:JSONString CallbackID:0 Target:self];
    
//    [[StaticHttpRequest sharedInstance] doJsonRequestWithToken:m_Token
//                                                  externalLink:nil
//                                                           Url:strCmd
//                                                        method:@"POST"
//                                                      postData:sendData
//                                                    callbackID:0
//                                                        target:self];
}

-(void)showErrorMessage{
    [self.m_loader stopAnimating];
    UIAlertView *tmpAlert = [[UIAlertView alloc] init];
    NSString *strTitle = NSLocalizedString(@"accessDeviceFaileTitle", nil);
    NSString *strMsg = NSLocalizedString(@"accessDeviceFailMsg", nil);
    
    [tmpAlert addButtonWithTitle:NSLocalizedString(@"ButtonTextOk", nil)];
    [tmpAlert setTitle:strTitle];
    [tmpAlert setMessage:strMsg];
    [tmpAlert show];
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    appDelegate.sharedAlertView = tmpAlert;
}

-(NSString*)convertChangeLog:(NSString*)_logString{
    NSString* resultString = [_logString stringByReplacingOccurrencesOfString:@"::_n::" withString:@"\n"];
    resultString = [resultString stringByReplacingOccurrencesOfString:@"::_t::" withString:@"   "];
    return resultString;
}

- (IBAction)upgradeButtonClick:(id)sender {
    [self.m_loader startAnimating];
    
    if (m_upgradeDevice) {
        //NSString* connectAddress = nil;
//        multiPortClass* connectPort;
//        if (m_upgradeDevice.m_prefType == ADDRESS_TYPE) {
//            connectAddress = m_upgradeDevice.m_httpCMDAddress;
//            connectPort = m_upgradeDevice.m_httpCMDPort;
//        }else{
//            connectAddress = m_upgradeDevice.m_deviceAddress;
//            connectPort = m_upgradeDevice.m_httpPort;
//        }
//        
//        m_DeviceConnector = [[deviceConnector alloc] deviceConnectorWithAddress:connectAddress
//                                                                            UID:m_upgradeDevice.m_strUID
//                                                                           port:connectPort
//                                                                           user:m_upgradeDevice.m_userName
//                                                                            pwd:m_upgradeDevice.m_password delegate:self
//                                                                     deviceInfo:m_upgradeDevice
//                                                                          state:LOGIN_CONNECTOR
//                                                                           type:IPCAM_TYPE
//                                                                         scheme:m_upgradeDevice.m_scheme
//                                                                  ConnectorType:m_upgradeDevice.m_prefType];
//        
//        
//        [m_DeviceConnector loginToDeviceWithGetRTSPInfo:NO checkPrevious:NO];
        
        [self doUpgrade];
    }
    
    //[self showProgress];
}



#pragma mark - Timer

- (void)startTimer {
    if ((!self.timer) || (![self.timer isValid])) {
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.00
                                                      target:self
                                                    selector:@selector(poolTimer)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)poolTimer
{
    int percent = [self getCurrentPercent];
    [circleProgress update:percent];
    if (self.timer && percent >= 100) {
        [self stopProgress];
    }
}

-(int)getCurrentPercent{
    float percent = (fabs((float)[startTime timeIntervalSinceNow])/TIME_LIMIT)*100;
    NSLog(@"%f",percent);
    if (percent > 100.f) {
        return 100;
    }
    return (int)percent;
}

//#pragma mark UITableViewDataSource
//
//- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section{
//    return 2;
//}
//
//-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
//    }
//    
//    NSString *strTitleMsg = @"";
//    NSString *strDetailMsg = @"";
//    switch (indexPath.row) {
//        case 0:
//        {
//            strTitleMsg = [NSString stringWithFormat:@"%@" ,NSLocalizedStringFromTable(@"NEW_VERSION_TITLE", @"InfoPlist", nil)];
//            strDetailMsg = [m_upgradeResponse objectForKey:@"version"];
//        }
//            break;
//        case 1:
//        {
//            strTitleMsg = [NSString stringWithFormat:@"%@" ,NSLocalizedStringFromTable(@"RELEASE_DATE_TITLE", @"InfoPlist", nil)];
//            strDetailMsg = [m_upgradeResponse objectForKey:@"release_date"];
//            
//        }
//            break;
//        default:
//            break;
//    }
//    
//    [cell.detailTextLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
//    [cell.detailTextLabel setTextColor:[UIColor colorWithRed:118.0f/255.0f green:119.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
//    [cell.textLabel setText:strTitleMsg];
//    [cell.detailTextLabel setText:strDetailMsg];
//    [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:18.0f]];
//    [cell.textLabel setTextColor:[UIColor colorWithRed:41.0f/255.0f green:41.0f/255.0f blue:41.0f/255.0f alpha:1.0f]];
//    
//    return cell;
//}

#pragma mark DeviceConnectorDelegate
//-(void) didfinishLoginActionByResultType:(NSInteger) _resultCode deviceInfo:(NSDictionary *) _deviceInfo errorDesc :(NSString *) _strErrorDesc address:(NSString *) _strAddress port:(NSInteger) _commandPort
//{
//    if (_resultCode == 0) {
//        m_upgradeDevice.m_scheme = [[StaticHttpRequest sharedInstance] getSchecmeFromLoginResult:_deviceInfo];
//        m_upgradeDevice.m_httpCMDAddress = [NSString stringWithFormat:@"%@", _strAddress];
//        if ([m_upgradeDevice.m_scheme isEqualToString:@"http"]) {
//            m_upgradeDevice.m_httpCMDPort.m_Http_Port = _commandPort;
//        }else{
//            m_upgradeDevice.m_httpCMDPort.m_Https_Port = _commandPort;
//        }
//        
//        if ([_deviceInfo objectForKey:@"MicSupport"]) {
//            m_upgradeDevice.m_blnMicSupport = [[_deviceInfo objectForKey:@"MicSupport"] boolValue];
//        }
//        
//        if ([_deviceInfo objectForKey:@"SpeakerSupport"]) {
//            m_upgradeDevice.m_blnSpeakerSupport = [[_deviceInfo objectForKey:@"SpeakerSupport"] boolValue];
//        }
//        
//        if ([[_deviceInfo objectForKey:@"Token"] length] > 0) {
//            m_Token = [NSString stringWithFormat:@"%@", [_deviceInfo objectForKey:TOKEN_TAG]];
//        }
//        
//        [self doUpgrade];
//    }else{
//        [self showErrorMessage];
//    }
//}

#pragma mark StaticHttpRequestDelegate

-(void)didFinishStaticRequestJSON:(NSDictionary *)strAckResult CommandIp:(NSString *)ip CommandPort:(int)port CallbackID:(NSUInteger)callback{
    if ([[[strAckResult objectForKey:UPGRADE_ACKTAG] lowercaseString] isEqualToString:@"ok"]) {
        [self showProgress];
    }else{
        [self showErrorMessage];
    }
}

-(void)failToStaticRequestWithErrorCode:(NSInteger)iFailStatus description:(NSString *)desc callbackID:(NSUInteger)callback{
    [self showErrorMessage];
}

- (IBAction)okClick:(id)sender {
//    [[StaticLoginInfo sharedInstance] removeAllLoginInfo];
    AppDelegate* appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appdelegate.isUpgrading = NO;
    
    if (!self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
//    UINavigationController* navigationController = appdelegate.mRootView.viewControllers[appdelegate.mRootView.selectedIndex];
    
//    [navigationController popToRootViewControllerAnimated:NO];
//    navigationController.navigationBarHidden = YES;
//    navigationController.navigationBarHidden = NO;
//    
//    [appdelegate.mRootView.delegate tabBarController:appdelegate.mRootView shouldSelectViewController:appdelegate.mRootView.viewControllers[0]];
//    [appdelegate.mRootView setSelectedIndex:0];
//    [appdelegate.mRootView.tabBar tabBarItemWasSelected:appdelegate.mRootView.tabBar.items[0]];
//    
//    DeviceRootController* deviceRootView = appdelegate.mRootView.viewControllers[0];
//    [deviceRootView doRecheck];
}

- (IBAction)backClick:(id)sender {
    [self goback];
}
@end
