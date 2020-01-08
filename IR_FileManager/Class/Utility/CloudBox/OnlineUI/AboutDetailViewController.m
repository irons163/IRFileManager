//
//  AboutDetailViewController.m
//  EnShare
//
//  Created by Phil on 2016/12/8.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "AboutDetailViewController.h"
#import "KGModal.h"
#import "SuccessView.h"
#import "DialogView.h"
#import "LoadDocument.h"
#import "DataManager.h"
#import "dataDefine.h"
#ifdef enshare
#import "SenaoGA.h"
#endif
#import "AboutViewTableViewCell.h"
#import "Masonry.h"

@interface AboutDetailViewController (){
    LoadDocument* loadDocmuent;
#if ConnectionType
    int debugCount;
    NSTimer* debugTimer;
#endif
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mailBoxViewHeightConstraint;

@end

@implementation AboutDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.navigationItem.title = _(@"ABOUT_TITLE");
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
    [backButton addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        mainView.frame = CGRectMake(0, 20, mainView.frame.size.width, mainView.frame.size.height-20);
    } else {// iOS 6
    }
    
    contentView.backgroundColor = [UIColor colorWithRed:230.f/255.f green:232.f/255.f blue:227.f/255.f alpha:1];
    
    htmlView = [[UIWebView alloc] init];
    htmlView.backgroundColor = [UIColor colorWithRed:230.f/255.f green:232.f/255.f blue:227.f/255.f alpha:1];
    
    loadDocmuent=[[LoadDocument alloc] init];
    
    NSString *fileName = _(@"ABOUT_GENERAL");
    [loadDocmuent loadDocument:fileName inView:htmlView];
    [contentView addSubview:htmlView];
    [htmlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(htmlView.superview);
    }];
    
    [DataManager sharedInstance].uiViewController = self.navigationController;
    
    switch (self.aboutType) {
        case GENERAL_TYPE:
            [self generalClk];
            break;
        case LEGAL_INFO_TYPE:
            [self legalClk];
            break;
        case FAQ_TYPE:
            [self faqClk];
            break;
    }
    
    [self.navigationController.navigationBar setNeedsLayout];
#ifdef MESSHUDrive
    mailBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
#endif
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

#ifdef enshare
    [SenaoGA setScreenName:@"AboutPage"];
#endif
}

-(void)viewDidAppear:(BOOL)animated{
#if ConnectionType
    [self resetDebugCount];
#endif
}

- (void)dealloc{
    mainView = nil;
    contentView = nil;
    mailBtn = nil;
    ppBtn = nil;
//    eBtn = nil;
    htmlView = nil;
}

- (void)backBtnDidClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)generalClk {
#if ConnectionType
    if (!debugTimer) {
        debugTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(resetDebugCount) userInfo:nil repeats:NO];
    }
    
    debugCount++;
    
    if (debugCount >= 10) {
        NSLog(@"Debug Open");
        [self showAlert:[NSString stringWithFormat:@"Connection Type: %@",[DataManager sharedInstance].connectionType]];
        [self resetDebugCount];
    }
#endif
    
    mailBtn.hidden = FALSE;
    ppBtn.hidden = TRUE;
    
    self.mailBoxViewHeightConstraint.constant = 50;
    
    NSString *fileName = _(@"ABOUT_GENERAL");
    [htmlView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"]; //cleat cotent
    [loadDocmuent loadDocument:fileName inView:htmlView];
    htmlView.hidden = FALSE;
}

- (void)legalClk {
#if ConnectionType
    [self resetDebugCount];
#endif
    
    mailBtn.hidden = TRUE;
    htmlView.hidden = TRUE;
    ppBtn.hidden = YES;
//    eBtn.hidden = FALSE;
    
    self.mailBoxViewHeightConstraint.constant = 0;
    [self eClk];
}

- (void)faqClk {
#if ConnectionType
    [self resetDebugCount];
#endif
    
    mailBtn.hidden = TRUE;
    ppBtn.hidden = TRUE;
    
    self.mailBoxViewHeightConstraint.constant = 0;
    
    NSString *fileName = _(@"ABOUT_FAQ");
    [htmlView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"]; //cleat cotent
    [loadDocmuent loadDocument:fileName inView:htmlView];
    [contentView bringSubviewToFront:htmlView];
    
    htmlView.hidden = FALSE;
}

- (IBAction)mailClk:(id)sender{
    if ([MFMailComposeViewController canSendMail]) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSString *finalPath = [path stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        NSString *version = [plistData objectForKey:@"CFBundleVersion"];
        
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
#ifdef MESSHUDrive
        [picker setToRecipients:[NSArray arrayWithObject:@"app@messhu.com"]];
        [picker setSubject:@"Feedback to MESSHU Drive APP"];
#else
        [picker setToRecipients:[NSArray arrayWithObject:@"app@engeniuscloud.com"]];
        [picker setSubject:@"Feedback to EnGenius EnFile APP"];
#endif
        
        NSString *body = [NSString stringWithFormat:_(@"ABOUT_MAIL"), [[NSUserDefaults standardUserDefaults] stringForKey:MODEL_NAME_KEY], [[NSUserDefaults standardUserDefaults] stringForKey:FIRWARE_VERSION_KEY], version, [UIDevice currentDevice].model, [[UIDevice currentDevice] systemVersion] ];
        
        [picker setMessageBody:body isHTML:YES];
        [self presentViewController:picker animated:YES completion:nil];
    }else{
        NSLog(@"no mail");
        SuccessView *successView;;
        VIEW(successView, SuccessView);
        successView.infoLabel.text = NSLocalizedString(@"BACKUP_ALERT", nil);
        [[KGModal sharedInstance] setShowCloseButton:FALSE];
        [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
    }
}

- (IBAction)ppClk:(id)sender {
    htmlView.hidden = FALSE;
    ppBtn.hidden = TRUE;
    
    NSString *html = [NSString stringWithFormat:@"<h3>Privacy Policy</h3>\n\n<div>We recognize that privacy is important.  This Privacy Policy applies to all of the products, services and websites offered by EnGenius Technologies, Inc (“ENGENIUS”). Please take a moment to read the following policy to learn how we handle your personal information. </div>\n\n<h4>Why we collect personal information </h4>\n\n<div>ENGENIUS collects and uses your personal information to give you superior customer service, to provide you with convenient access to our products and services, and to make a wider range available to you. In addition, we use your personal information to keep you up to date on the latest product announcements, software updates, special offers, and other information we think you\'d like to hear about. This may occasionally include information from other technology companies about products and services that can add value to your ENGENIUS products. From time to time, we may also use your personal information to contact you to participate in a market research survey, so that we can gauge customer satisfaction and develop better products. </div>\n\n<h4>How we collect personal information </h4>\n\n<div>We collect information about you in several ways. For example, we might ask for your contact information when you correspond with us, call us to make a purchase or request service, register to attend a seminar, or participate in an online survey. In addition, when you register a new ENGENIUS product, sign up for an ENGENIUS webinar or live seminar, or ask to be included in an email mailing list, we collect and store the information you provide in a secure database. </div>\n\n<div>To save you time and make our web services even easier to use, some areas of the ENGENIUS website allow you to create an \"ENGENIUS TECHNOLOGIES, INC. ID\" using your personal information. Simply fill out a brief profile-your name, phone number, and email address-then choose a password and password hint (such as the month and day of your birth) for security. The system saves your information and assigns you a personal ENGENIUS TECHNOLOGIES, INC. ID. Next time you utilize any of our web services your information will be recalled for you. </div>\n\n<h4>When we disclose personal information </h4>\n\n<div>Because ENGENIUS TECHNOLOGIES, INC. is a global company, your personal information may be shared with ENGENIUS parent company, subsidiaries, affiliated companies or other trusted business or persons around the world (“ENGENIUS group”). They will be required to protect your personal information in accordance with the ENGENIUS Privacy Policy. ENGENIUS may occasionally share your personal contact information with carefully selected technology companies, to keep you informed about related products and services. For example, when new software or hardware is released, we may work with other developers to ensure that you\'re aware of the latest software or hardware available. If you do not want to receive promotional information from ENGENIUS or these technology companies, click nopromo@engeniustech.com and send us a message stating that you would like to not be included in such updates. </div>\n\n<div>ENGENIUS works with other companies that help us provide ENGENIUS products and services to you, and at times, we may need to provide your personal information to these companies. For example, we give shipping companies this information so they can deliver your products efficiently. The information they receive is for shipping and delivery purposes only, and we require that the companies safeguard your personal information in accordance with ENGENIUS Privacy Policies. </div>\n\n<div>ENGENIUS may share personal information in the event that we have a good faith belief that access, use, preservation or disclosure of such information is reasonably necessary to (a) satisfy any applicable law, regulation, legal process or enforceable governmental request, (b) enforce applicable Terms of Service, including investigation of potential violations thereof, (c) detect, prevent, or otherwise address fraud, security or technical issues, or (d) protect against harm to the rights, property or safety of ENGENIUS, its users or the public as required or permitted by law. </div>\n\n<h4>How we protect your personal information </h4>\n\n<div>ENGENIUS safeguards the security of the data you send us with physical, electronic, and managerial procedures. We urge you to take every precaution to protect your personal data when you are on the Internet. When using ENGENIUS website(s) change your passwords often, use a combination of letters and numbers, and make sure you use a secure browser. </div>\n\n<div>ENGENIUS website(s) uses industry-standard Secure Sockets Layer (SSL) encryption on all web pages where personal information is required. To register credit information, you must use an SSL-enabled browser such as Internet Explorer. This protects the confidentiality of your personal and credit card information while it is transmitted over the Internet. </div>\n\n<h4>Access to your personal information </h4>\n\n<div>When you use ENGENIUS website, we make good faith efforts to provide you with access to your personal information and either to correct this data if it is inaccurate or to delete such data at your request if it is not otherwise required to be retained by law or for legitimate business purposes. We ask individual users to identify themselves and the information requested to be accessed, corrected or removed before processing such requests, and we may decline to process requests that are unreasonably repetitive or systematic, require disproportionate technical effort, jeopardize the privacy of others, or would be extremely impractical (for instance, requests concerning information residing on backup tapes), or for which access is not otherwise required. In any case where we provide information access and correction, we perform this service free of charge, except if doing so would require a disproportionate effort. </div>\n\n<h4>Collecting other personal information </h4>\n\n<div>When you browse ENGENIUS website, you are able to do so anonymously. Generally, we don\'t collect personal information when you browse - not even your email address. Your browser, however, does automatically tell us the type of computer and operating system you are using. </div>\n\n<div>Like many websites, the ENGENIUS website uses \"cookie\" technology. When you first connect to our site, the cookie identifies your browser with a unique, random number. The cookies we use do not reveal any personal information about you, except perhaps your first name so we can welcome you on your next visit. Cookies help us understand which parts of our websites are the most popular, where our visitors are going, and how long they spend there. We use cookies to study traffic patterns on our site so we can make the site even better. </div>\n\n<div>In some of our email to you, we use a \"click-through URL.\" When you click one of these URLs, you pass through our web server before arriving at the website that is your destination. We may track click-throughs to help us determine your interest in particular topics and measure the effectiveness of our customer communications. </div>\n\n<h4>Our companywide commitment to privacy </h4>\n\n<div>To make sure your personal information remains confidential, we communicate these privacy guidelines to every ENGENIUS employee. In addition, ENGENIUS adheres to industry initiatives such as the Online Privacy Alliance (http://www.privacyalliance.org) to preserve privacy rights on the Internet and in all aspects of electronic commerce. Though not a member, ENGENIUS works to maintain the same standards outlined by the organization. </div>\n\n<div>ENGENIUS does not knowingly solicit personal information from children or send them requests for personal information. \n\n<div>ENGENIUS\'s website contains links to other sites that are not part of ENGENIUS group. ENGENIUS  does not share your personal information with those websites and is not responsible for their privacy practices. We encourage you to learn about the privacy policies of those companies. </div>\n\n<div>If we are going to use your personal information differently from that stated at the time of collection, we will try to contact you via email using the most recent information we have. If you have not given us permission to communicate with you, you will not be contacted, nor will we use your personal information in a new manner. </div>\n\n<div>The ENGENIUS Privacy Policy is subject to change at any time. We encourage you to review the privacy policy regularly for any changes.</div>\n"];

    [contentView bringSubviewToFront:htmlView];
}

- (void)eClk {
    ppBtn.hidden = TRUE;
    
    NSString *fileName = _(@"ABOUT_EULA");
    
    [htmlView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"]; //cleat cotent
    [loadDocmuent loadDocument:fileName inView:htmlView];
    [contentView bringSubviewToFront:htmlView];
    
    htmlView.hidden = FALSE;
}

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    switch (result) {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultFailed:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultSaved:
            break;
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
#if ConnectionType
-(void)resetDebugCount{
    debugCount = 0;
    if (debugTimer) {
        [debugTimer invalidate];
        debugTimer = nil;
        NSLog(@"TimeOut Rest Count");
    }
}

-(void)showAlert:(NSString*)str{
    DialogView *dialog = nil;
    VIEW(dialog, DialogView);
    dialog.okBtn.hidden = NO;
    dialog.helpBtn.hidden = YES;
    dialog.titleNameLbl.text = @"APP Debug";
    dialog.titleLbl.text = str;
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:dialog andAnimated:YES];
}

#endif

@end
