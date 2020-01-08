//
//  MainPageViewController.m
//  EnSmart
//
//  Created by Phil on 2015/8/17.
//  Copyright (c) 2015年 Phil. All rights reserved.
//

#import "MainPageViewController_online.h"
#import "EnShareTools.h"
#import "DocumentListViewController_online.h"
#import "PhotoCollectionViewController_online.h"
#import "DiskViewController.h"
#import "MeshRouterSelectionViewController.h"
#import "LoginViewController.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"
#import "dataDefine.h"
#import "KGModal.h"
#import "SuccessView.h"
#import "RouterGlobal.h"
#import "AppDelegate.h"
#import "CommonTools.h"

@interface MainPageViewController_online (){
    
}

@end

@implementation MainPageViewController_online{
    UIButton *multidiskButton;
    UIButton *meshRouterSelectionButton;
    UIActivityIndicatorView *loadingView;
    //    NSMutableArray *taskes;
    //    NSMutableDictionary *results;
    NSMutableArray *items;
    NSMutableArray *favorites;
    NSString *path;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //    [self setNavigatinItem];
#ifdef MESSHUDrive
    self.navigationItem.title = _(@"PERSONAL_CLOUD_TITLE");
#else
    self.navigationItem.title = _(@"PERSONAL_STORAGE_TITLE");
#endif
    self.allButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine]];
    //    [self.navigationController.navigationBar setBackgroundColor:[UIColor colorWithColorCodeString:NavigationBarBGColor]];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationItem.hidesBackButton = YES;
    UIView* leftview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage* backImage = [UIImage imageNamed:@"nav_logout_icon"];
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
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, 35)];
    meshRouterSelectionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage *image = [UIImage imageNamed:@"ic_ibtn_meshrouter"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 30)];
    [meshRouterSelectionButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"ic_ibtn_meshrouter"];
    image = [CommonTools imageWithImage:image scaledToSize:CGSizeMake(30, 30)];
    [meshRouterSelectionButton setImage:image forState:UIControlStateHighlighted];
    [meshRouterSelectionButton addTarget:self action:@selector(meshRouterSelectionButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:meshRouterSelectionButton];
#ifdef MESSHUDrive
    CGSize imageSize = CGSizeMake(20, 30);
#else
    CGSize imageSize = CGSizeMake(30, 30);
#endif
    multidiskButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 0, 35, 35)];
    image = [UIImage imageNamed:@"ic_btn_multidisk"];
    image = [CommonTools imageWithImage:image scaledToSize:imageSize];
    [multidiskButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"ic_btn_multidisk"];
    image = [CommonTools imageWithImage:image scaledToSize:imageSize];
    [multidiskButton setImage:image forState:UIControlStateHighlighted];
    [multidiskButton addTarget:self action:@selector(multidiskBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:multidiskButton];
    
    if([DataManager sharedInstance].modelType == 1){
        meshRouterSelectionButton.hidden = NO;
        meshRouterSelectionButton.enabled = NO;
    }else{
        meshRouterSelectionButton.hidden = YES;
    }
    
    UIBarButtonItem  *rightItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    UIBarButtonItem *negativeSpacerRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerRight setWidth:-10];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacerRight, rightItem, nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.documentTitleLabel.text = _(@"Document");
    self.videoTitleLabel.text = _(@"Video");
    self.albumTitleLabel.text = _(@"Photo");
    self.musicTitleLabel.text = _(@"Music");
    self.allTitleLabel.text = _(@"All");
    
    [UIView setAnimationsEnabled:YES];
    
    //    taskes = [[NSMutableArray alloc] init];
    //    results = [[NSMutableDictionary alloc] init];
    items = [[NSMutableArray alloc] init];
    path = @"/";
    
    [DataManager sharedInstance].uiViewController = self.navigationController;
    
    loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [loadingView setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - loadingView.frame.size.width/2, [UIScreen mainScreen].bounds.size.height/2 - loadingView.frame.size.height/2, loadingView.frame.size.width, loadingView.frame.size.height)];
    [self.view addSubview:loadingView];
    loadingView.hidden=YES;
    
    [self refresh];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if(self.tabBarController.tabBar){
        CGRect tmp = self.bgImageView.frame;
        tmp.origin.y = - self.tabBarController.tabBar.frame.size.height;
        self.bgImageView.frame = tmp;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)gotoDocumentPageClick:(id)sender {
    DocumentListViewController_online* mainPageViewController = [[DocumentListViewController_online alloc] initWithNibName:@"DocumentListViewController_online" bundle:nil];
    mainPageViewController.fileType = DOCUMENT_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoVideoPageClick:(id)sender {
    DocumentListViewController_online * mainPageViewController = [[DocumentListViewController_online alloc] initWithNibName:@"DocumentListViewController_online" bundle:nil];
    mainPageViewController.fileType = VIDEO_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoMusicPageClick:(id)sender {
    DocumentListViewController_online * mainPageViewController = [[DocumentListViewController_online alloc] initWithNibName:@"DocumentListViewController_online" bundle:nil];
    mainPageViewController.fileType = MUSIC_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoAlbumPageClick:(id)sender {
    PhotoCollectionViewController_online * mainPageViewController = [[PhotoCollectionViewController_online alloc] initWithNibName:@"PhotoCollectionViewController_online" bundle:nil];
    mainPageViewController.fileType = PHOTO_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (IBAction)gotoAllPageClick:(id)sender {
    DocumentListViewController_online * mainPageViewController = [[DocumentListViewController_online alloc] initWithNibName:@"DocumentListViewController_online" bundle:nil];
    mainPageViewController.fileType = ALL_TYPE;
    [self.navigationController pushViewController:mainPageViewController animated:YES];
}

- (void)backBtnDidClick {
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)multidiskBtnDidClick {
    DiskViewController * diskViewController = [[DiskViewController alloc] initWithNibName:@"DiskViewController" bundle:nil];
    [self.navigationController pushViewController:diskViewController animated:YES];
}

- (void)meshRouterSelectionButtonDidClick {
    MeshRouterSelectionViewController * meshRouterSelectionViewController = [[MeshRouterSelectionViewController alloc] initWithNibName:@"MeshRouterSelectionViewController" bundle:nil];
    meshRouterSelectionViewController.delegate = self;
    meshRouterSelectionViewController.meshRouterChangedSuccessCallback = ^{
        [self refresh];
    };
    [self.navigationController pushViewController:meshRouterSelectionViewController animated:YES];
}

- (NSString*)getVideoID:(NSString*)videoURL{
    NSString *videoID = nil, *videoExt = nil;
    
    NSString *tVideoURL = videoURL;
    
    NSRange po = [videoURL rangeOfString:@"?"];
    if(po.location>0){
        tVideoURL = [tVideoURL substringFromIndex:po.location];
    }
    
    po = [tVideoURL rangeOfString:@"&"];
    if(po.location>0){
        videoID = [tVideoURL substringToIndex:po.location];
        videoID = [videoID stringByReplacingOccurrencesOfString:@"?id="withString:@""];
        
        tVideoURL = [tVideoURL substringFromIndex:po.location];
        videoExt = [[tVideoURL stringByReplacingOccurrencesOfString:@"&ext="withString:@""] lowercaseString];
    }
    
    videoID = [ NSString stringWithFormat:@"%@.%@", videoID , videoExt];
    
    //NSLog(@"%@",videoID);
    
    return videoID;
}

//從Album上傳時，先複製到temp資料夾
- (void)addUploadByImage:(UIImage*)image tImageName:(NSString*)tImageName {
    NSString *filename = [[tImageName pathComponents] lastObject];
    NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]];
    
    NSString *filePath = [resourceDocPath stringByAppendingPathComponent:filename];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:YES];
}

- (void)addUploadByVideo:(ALAssetRepresentation *)rep videoName:(NSString*)videoName {
    // 將video儲存下來
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]], videoName];
    NSLog(@"%@",filePath);
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) {
    }
    
    static const NSUInteger BufferSize = 1024*1024;
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    do {
        @try {
            bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:nil];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            
            offset += bytesRead;
        } @catch (NSException *exception) {
            NSLog(@"%@ exception",filePath);
            break;
        }
    } while (bytesRead > 0);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) viewDidAppear:(BOOL)animated{
    
}

-(NSAttributedString*)boldString:(NSAttributedString*)string Range:(NSRange)boldedRange{
    NSString *boldFontName = [[UIFont boldSystemFontOfSize:14] fontName];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    [attrString addAttribute: NSFontAttributeName value:[UIFont fontWithName:boldFontName size:14] range:boldedRange];
    return attrString;
}

//判斷是否有USB裝置
- (void)getStorageInfo{
    dispatch_async(dispatch_get_main_queue(), ^{
        [loadingView startAnimating];
        loadingView.hidden = NO;
        [self.view setUserInteractionEnabled:NO];
        
        RouterGlobal *global = [[RouterGlobal alloc]init];
        [global getStorageInfo:^(NSDictionary *resultDictionary) {
            
            NSLog(@"GetStorageInfo %@", resultDictionary);
            NSLog(@"usb count : %lu", (unsigned long)[(NSDictionary*)resultDictionary[@"StorageInformation"] count]);
            
            NSString* ip = [DataManager sharedInstance].getLocalIP;
            NSLog(@"Local : %@",ip);
            
            if (resultDictionary != nil) {
                if ([resultDictionary objectForKey:@"StorageInformation"] && [(NSDictionary*)[resultDictionary objectForKey:@"StorageInformation"] count] == 0) {
                    
                }else{
                    if ([DataManager sharedInstance].diskPath == nil) {
                        [DataManager sharedInstance].diskPath = resultDictionary[@"StorageInformation"][0][@"UsbPath"];
                        [DataManager sharedInstance].diskGuestPath = resultDictionary[@"StorageInformation"][0][@"UsbGuestPath"];
                        
                        if ([[DeviceClass sharedInstance] isAdminUser]) {
                            [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskPath;
                        }else{//guest
                            [DataManager sharedInstance].usbUploadPath = [DataManager sharedInstance].diskGuestPath;
                        }
                    }
                }
                
                if([DataManager sharedInstance].modelType == 1){
                    [self getDeviceStatus];
                }
                
                [loadingView stopAnimating];
                loadingView.hidden = YES;
                [self.view setUserInteractionEnabled:YES];
            }else{//訊息錯誤時，回到登入頁
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    });
}

- (void)getDeviceStatus{
    
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [global getDeviceStatus:^(NSDictionary *resultDictionary) {
        if (resultDictionary != nil) {
            LogMessage(nil, 0, @"GetDeviceStatus : %@", resultDictionary);
            [DataManager sharedInstance].lanIPAddress = [resultDictionary objectForKey:@"LanIPAddress"];
            
            meshRouterSelectionButton.hidden = NO;
            meshRouterSelectionButton.enabled = YES;
            
            [self getMeshRouter];
        }else{//訊息錯誤時，回到登入頁
            [self backClk:nil];
        }
    }];
}

- (void)getMeshRouter{
    RouterGlobal *global = [[RouterGlobal alloc]init];
    
    [[DeviceClass sharedInstance] useMasterConntectionDetail];
    
    [global getMeshNodeSimplifyInfo:^(NSDictionary *resultDictionary) {
        [[DeviceClass sharedInstance] useCurrentConntectionDetail];
        
        if (resultDictionary != nil) {
            if ([resultDictionary[GET_MESH_NODE_SIMPLIFY_INFO_ACKTAG] isEqualToString:@"OK"]) {
                for (NSDictionary *i in [resultDictionary objectForKey:@"MeshNodesList"]) {
                    if ([[i objectForKey:@"LANIPAddress"] isEqualToString:[DataManager sharedInstance].lanIPAddress]) {
                        self.currentMeshRouterLabel.text = [NSString stringWithUTF8String:[[i objectForKey:@"LocationName"] UTF8String]];
                        break;
                    }
                }
            }else{
                return;
            }
        }
    }];
}

- (IBAction)backClk:(id)sender {
    [[DeviceClass sharedInstance] stopLogin];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Callback

- (void)checkFavorite{
    if ([favorites count]>0) {
        for (int i=0;i<[favorites count];i++) {
            NSString *temp = [favorites objectAtIndex:i];
            if( [items indexOfObject:temp] > [items count]){
                [favorites removeObjectAtIndex:i];
            }
        }
    }
}

- (void)generate:(NSString*)fileName {
    LogMessage(nil, 0, @"%@", fileName);
    NSString *method = @"POST";
    NSString *body = @"";
    @try {
        body = [NSString stringWithFormat:@"{ \"UsbPath\" : \"%@\", \"FileType\" : \"%@\" }", path, [[DataManager sharedInstance] getType:[fileName pathExtension]] ];
    }
    @catch (NSException* ex) { }
    
    LogMessage(nil, 0, @"%@\n%@\n%@", GENERATE_FILE_LIST_BY_TYPE_COMMAND, method, body);
    
    [[StaticHttpRequest sharedInstance] doJsonRequestWithCommand:GENERATE_FILE_LIST_BY_TYPE_COMMAND
                                                          Method:method
                                                            Body:body
                                                      CallbackID:GENERATE_FILE_LIST_BY_TYPE_CALLBACK
                                                          Target:self];
}

- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}

-(void)refresh{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        [self getDeviceStatus];
//    });
    
    if ([[[StaticHttpRequest sharedInstance] detect3GWifi] isEqualToString:@"NO"]) {
        [self showWarnning:_(@"LOGIN_ALERT_INTERNET")];
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    
    [self performSelectorInBackground:@selector(getStorageInfo) withObject:nil];
}

- (void) doLoginWithUID:(NSString*)uid WithLocalIP:(NSString*)ipAddress loginDelegate:(id)loginDelegate{
    
    self.currentMeshRouterLabel.text = @"";
    [self.delegate doLoginWithUID:uid WithLocalIP:ipAddress loginDelegate:loginDelegate];
}

@end
