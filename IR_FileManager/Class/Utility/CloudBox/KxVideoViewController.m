//
//  KxVideoViewController.m
//  EnShare
//
//  Created by Phil on 2015/6/15.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "KxVideoViewController.h"
#import "VideoFrameExtractor.h"
#import "KxMovieViewController.h"
#import "UIColor+Helper.h"
#ifdef MESSHUDrive
#import "ColorDefine.h"
#endif
#import "Masonry.h"

@interface KxVideoViewController (){
//    KxMovieGLView       *_glView;
    UIImageView         *_imageView;
    UIView              *_topHUD;
    UIToolbar           *_topBar;
    UIToolbar           *_bottomBar;
    BJRangeSliderWithProgress *_progressSlider;
    
    UIBarButtonItem     *_playBtn;
    UIBarButtonItem     *_pauseBtn;
    UIBarButtonItem     *_rewindBtn;
    UIBarButtonItem     *_fforwardBtn;
    UIBarButtonItem     *_spaceItem;
    UIBarButtonItem     *_fixedSpaceItem;
    
    UIButton            *_doneButton;
    UILabel             *_progressLabel;
    UILabel             *_leftLabel;
    UIButton            *_infoButton;
    UITableView         *_tableView;
    UIActivityIndicatorView *_activityIndicatorView;
    UILabel             *_subtitlesLabel;
    
#ifdef DEBUG
    UILabel             *_messageLabel;
    NSTimeInterval      _debugStartTime;
    NSUInteger          _debugAudioStatus;
    NSDate              *_debugAudioStatusTS;
#endif
    
    int frames;
    CGFloat progressosOffset;
    
    int checkFrameCounter;
}

@end

@implementation KxVideoViewController{
    KxMovieViewController * playerView;
    StaticHttpRequest * m_httpSender;
    NSMutableArray *videoArray;
    int videoPosition;
    int type;
    NSString *videoPath;
    BOOL _hiddenHUD;
}

NSString *m_recordingPath;
NSString *m_aviTmpPath;
NSInteger m_CurrentOSVersion;
const int FROM_NET = 0;
const int FROM_LOCAL = 1;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if(type==FROM_LOCAL){
        [self createKxMovieViewControllerWithPath:videoPath isSliderMax:false];
    }else{
        [self createKxMovieViewControllerWithPath:videoPath isSliderMax:true];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadView{
    // LoggerStream(1, @"loadView");
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];
    
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];

    [self.view addSubview:_activityIndicatorView];
    
    [_activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    [_activityIndicatorView startAnimating];
    
#ifdef DEBUG
    _messageLabel = [[UILabel alloc] init];
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.textColor = [UIColor redColor];
    _messageLabel.hidden = YES;
    _messageLabel.font = [UIFont systemFontOfSize:14];
    _messageLabel.numberOfLines = 2;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_messageLabel];
    
    [_messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).with.offset(20);
        make.right.equalTo(self.view.mas_right).with.offset(-20);
        make.top.equalTo(self.view.mas_top).with.offset(40);
        make.height.mas_equalTo(40);
    }];
#endif
    
    CGFloat topH = 50;
    CGFloat botH = 50;
    
    _topHUD    = [[UIView alloc] init];
    _topBar    = [[UIToolbar alloc] init];
    _bottomBar = [[UIToolbar alloc] init];
    _bottomBar.tintColor = [UIColor blackColor];
    
    _topHUD.backgroundColor = [UIColor colorWithRed:152.f/255.f green:198.f/255.f blue:19.f/255.f alpha:1.f];
    _bottomBar.barTintColor = [UIColor colorWithRed:152.f/255.f green:198.f/255.f blue:19.f/255.f alpha:1.f];
    
#ifdef MESSHUDrive
    _topHUD.backgroundColor = [UIColor colorWithColorCodeString:NavigationBarBGColor];
    _bottomBar.barTintColor = [UIColor colorWithColorCodeString:NavigationBarBGColor];
#else
    _topHUD.backgroundColor = [UIColor colorWithRGB:0x00b4f5];
    _bottomBar.barTintColor = [UIColor colorWithRGB:0x00b4f5];
#endif
    
    [self.view addSubview:_topBar];
    [self.view addSubview:_topHUD];
    [self.view addSubview:_bottomBar];
    
    [_topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.top.and.width.equalTo(self.view);
//        make.height.mas_equalTo(topH);
        make.bottom.equalTo(self.mas_topLayoutGuide).mas_offset(topH);
    }];
    
    [_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.bottom.and.width.equalTo(self.view);
//        make.height.mas_equalTo(botH);
        make.top.equalTo(self.mas_bottomLayoutGuide).mas_offset(-topH);
    }];
    
    [_topHUD mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.top.and.width.equalTo(self.view);
//        make.height.mas_equalTo(topH);
        make.bottom.equalTo(self.mas_topLayoutGuide).mas_offset(topH);
    }];
    
    // top hud
    UIColor* topTitleColor = [UIColor whiteColor];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.backgroundColor = [UIColor clearColor];
    [_doneButton setTitleColor:topTitleColor forState:UIControlStateNormal];
    [_doneButton setTitle:_(@"ButtonTextOk") forState:UIControlStateNormal];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:)
          forControlEvents:UIControlEventTouchUpInside];
    
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 1, 50, topH)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = topTitleColor;
    _progressLabel.text = @"";
    _progressLabel.font = [UIFont systemFontOfSize:12];
    
    _progressSlider = [[BJRangeSliderWithProgress alloc] init];
    _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressSlider.showProgress = YES;
    _progressSlider.showRange = YES;
    _progressSlider.showThumbs = YES;
    _progressSlider.sliding = NO;
    _progressSlider.minValue = 0;
    _progressSlider.maxValue = 1;
    _progressSlider.leftValue = 0;
    _progressSlider.rightValue = 0;
    //    _progressSlider.continuous = NO;
    //    _progressSlider.value = 0;
    //    [_progressSlider setThumbImage:[UIImage imageNamed:@"kxmovie.bundle/sliderthumb"]
    //                          forState:UIControlStateNormal];
    
    _leftLabel = [[UILabel alloc] init];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = topTitleColor;
    _leftLabel.text = @"";
    _leftLabel.font = [UIFont systemFontOfSize:12];
    _leftLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    _infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    _infoButton.showsTouchWhenHighlighted = YES;
    _infoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_infoButton addTarget:self action:@selector(infoDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    _infoButton.hidden = YES;
    
    [_topHUD addSubview:_doneButton];
    [_topHUD addSubview:_progressLabel];
    [_topHUD addSubview:_progressSlider];
    [_topHUD addSubview:_leftLabel];
    [_topHUD addSubview:_infoButton];
    
    [_doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_topHUD).with.offset(8);
        make.bottom.equalTo(_topHUD);
        make.height.mas_equalTo(topH);
    }];
    [_progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_doneButton.mas_right).with.offset(8);
        make.width.mas_greaterThanOrEqualTo(40);
        make.height.mas_equalTo(topH);
        make.centerY.equalTo(_doneButton);
    }];
    [_progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_progressLabel.mas_right).with.offset(4);
        make.right.equalTo(_leftLabel.mas_left).with.offset(-5);
        //        make.width.mas_equalTo(60);
        make.height.mas_equalTo(topH);
        make.centerY.equalTo(_doneButton);
    }];
    [_leftLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_infoButton.mas_left).with.offset(-8);
        make.width.mas_greaterThanOrEqualTo(40);
        make.height.mas_equalTo(topH);
        make.centerY.equalTo(_doneButton);
    }];
    [_infoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_topHUD).with.offset(-8);
        make.height.and.width.mas_equalTo(25);
        make.centerY.equalTo(_doneButton);
    }];
    
    // bottom hud
    
    _spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                               target:nil
                                                               action:nil];
    
    _fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                    target:nil
                                                                    action:nil];
    _fixedSpaceItem.width = 30;
    
    _rewindBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                                               target:self
                                                               action:@selector(rewindDidTouch:)];
    
    _playBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                             target:self
                                                             action:@selector(playDidTouch:)];
    _playBtn.width = 50;
    
    _pauseBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                              target:self
                                                              action:@selector(playDidTouch:)];
    _pauseBtn.width = 50;
    
    _fforwardBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                                                 target:self
                                                                 action:@selector(forwardDidTouch:)];
    
    [self updateBottomBar];
    /*
    if (_decoder) {
        
        [self setupPresentView];
        
    } else {
        
        _progressLabel.hidden = YES;
        _progressSlider.hidden = YES;
        _leftLabel.hidden = YES;
        _infoButton.hidden = YES;
    }*/
    
    _progressLabel.hidden = YES;
    _progressSlider.hidden = YES;
    _leftLabel.hidden = YES;
    _infoButton.hidden = YES;
}

- (void) updateBottomBar
{
    UIBarButtonItem *playPauseBtn = _playBtn;
    [_bottomBar setItems:@[_spaceItem, _rewindBtn, _fixedSpaceItem, playPauseBtn,
                           _fixedSpaceItem, _fforwardBtn, _spaceItem] animated:NO];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

+(id)kxVideoInitWithContentPathFromNet: (NSArray *) pathArray
                  videoPosition: (int)videoPosition{
    return [[KxVideoViewController alloc] initWithContentPath:pathArray videoPosition:videoPosition type:FROM_NET];
}

+(id)kxVideoInitWithContentPathFromLocal: (NSArray *) pathArray
                  videoPosition: (int)videoPosition{
    return [[KxVideoViewController alloc] initWithContentPath:pathArray videoPosition:videoPosition type:FROM_LOCAL];
}

-(id)initWithContentPath: (NSArray *) _pathArray
           videoPosition: (int)_videoPosition
                    type:(int)_type{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self initKxVideo];
        videoArray = _pathArray;
        videoPosition = _videoPosition;
        type = _type;
        NSString* _path = _pathArray[_videoPosition];
        //NSAssert(path.length > 0, @"empty path");
        NSLog(@"Path Length : %lu",(unsigned long)_path.length);
        videoPath = _path;
        av_register_all();
//        avcodec_register_all();
        avformat_network_init();
//        if(type==FROM_NET)
//            [self dothing:videoPath];
        
    }
    return self;
}


-(void)updateProgressWithTotalBytesRead:(long long)_totalBytesRead TotalBytesExpectedToRead:(long long)_totalBytesExpectedToRead{
    
    
    
    if (_totalBytesExpectedToRead == 0) {
        //        [m_httpSender stopDownload];
        //        [m_downloadMask setHidden:YES];
        //        m_blnfileNotFound = YES;
        //        m_currentState = WAITTING;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *err;
        
                [fileManager removeItemAtPath:m_aviTmpPath error:&err];
//                    [self showFileNotExistMsg];
                if (!playerView) {
                    [self performSelectorOnMainThread:@selector(showFileNotExistMsg) withObject:nil waitUntilDone:YES];
                }
    }else{
        //        if (m_downloadMask.hidden) {
        //            if (m_currentState == DOWNLOADING) {
        //                [m_downloadMask setHidden:NO];
        //            }
        //            if (m_blnfileNotFound) {
        //                m_blnfileNotFound = NO;
        //            }
        //            if (m_fileSize != (NSUInteger)_totalBytesExpectedToRead) {
        //                m_fileSize = (NSUInteger)_totalBytesExpectedToRead;
        //            }
        //
        //        }
        float newProgress = (long double)_totalBytesRead/(long double)_totalBytesExpectedToRead;
        //        if (m_currentState == PLAYING) {
        //            if (playingFileContextDuration < 0) {
        //                [m_httpSender stopDownload];
        //                [m_downloadMask setHidden:YES];
        //                m_blnfileNotFound = YES;
        //                m_currentState = WAITTING;
        //                NSFileManager *fileManager = [NSFileManager defaultManager];
        //                NSError *err;
        //
        //                [fileManager removeItemAtPath:m_aviTmpPath error:&err];
        //                //            [self showFileNotExistMsg];
        //                if (!playerView) {
        //                    [self performSelectorOnMainThread:@selector(showFileNotExistMsg) withObject:nil waitUntilDone:YES];
        //                }
        //                return;
        //            }
        NSLog(@"Downloaning %f%%",newProgress);
        
        if (!playerView && (playingFileContextDuration > 0 || newProgress == 1)) {
            if (frames < 0 && newProgress < 1) {
                frames = 0;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self checkFramesByPath:m_aviTmpPath];
                    if(frames < 0)
                        checkFrameCounter++;
                    else
                        checkFrameCounter=0;
                    
                    if(checkFrameCounter>=3){
//                        [self stopDownload];
//                        [self createKxMovieViewControllerWithPath:videoPath isSliderMax:true];
                    }
                });
            }
            if ((newProgress >= 1 || frames > 0) && !playerView) {
                
                if (newProgress < 1) {
//                    if (newProgress < 0.5) {
//                        progressosOffset = newProgress;
//                    }else{
                        progressosOffset = newProgress/3.0;
//                    }
                }else{
                    progressosOffset = 0;
                }
                
                NSLog(@"Start Play!");
                
                [self createKxMovieViewControllerWithPath:m_aviTmpPath isSliderMax:false];
//                [self createKxMovieViewControllerWithPath:videoPath isSliderMax:true];
                
                /*
                if (m_blnFromPush) {
                    [m_loader stopAnimating];
                }else{
                    [((RDVRootViewController*)self.rdv_tabBarController).m_Loader stopAnimating];
                }*/
                
                
            }
        }
        
        /*
        frames = -1;
        if (frames < 0 && newProgress < 1) {
            frames = 0;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self checkFramesByPath:m_aviTmpPath];
            });
        }
        
        
        if (newProgress >= 1 || frames > 0){
            //[self playVideo];
//            KxMovieViewController * playerView = [KxMovieViewController movieViewControllerWithContentPath:m_aviTmpPath parameters:parameters duration:playingFileContextDuration];
            KxMovieViewController * playerView = [KxMovieViewController movieViewControllerWithContentPath:videoArray videoPosition:videoPosition];
            [self presentViewController:playerView animated:YES completion:nil];
        }*/
        
        
        /*
         if (!videoViewController && newProgress == 1) {
         if (frames < 0 && newProgress < 1) {
         frames = 0;
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         [self checkFramesByPath:m_aviTmpPath];
         });
         }
         
         if ((newProgress >= 1 || frames > 0) && !videoViewController) {
         
         if (newProgress < 1) {
         if (newProgress < 0.5) {
         progressosOffset = newProgress;
         }else{
         progressosOffset = newProgress/2.0;
         }
         }else{
         progressosOffset = 0;
         }
         
         NSLog(@"Start Play!");
         
         NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
         
         // increase buffering for .wmv, it solves problem with delaying audio frames
         if ([m_aviTmpPath.pathExtension isEqualToString:@"wmv"]) {
         parameters[KxMovieParameterMinBufferedDuration] = @(5.0);
         }
         
         // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
         if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
         parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
         }
         
         playerView = [KxMovieViewController movieViewControllerWithContentPath:m_aviTmpPath parameters:parameters duration:playingFileContextDuration];
         
         if (m_blnFromPush) {
         [m_loader stopAnimating];
         }else{
         [((RDVRootViewController*)self.rdv_tabBarController).m_Loader stopAnimating];
         }
         
         [self presentViewController:playerView animated:YES completion:nil];
         }
         }*/
        
        //        if (playerView) {
        if (newProgress < 1) {
            if (newProgress < 1) {
                //                    if (newProgress < 0.5) {
                //                        progressosOffset = newProgress;
                //                    }else{
                progressosOffset = newProgress/3.0;
                //                    }
            }else{
                progressosOffset = 0;
            }
            [self updateDownloadProgress:newProgress-progressosOffset];
        }else{
            [self updateDownloadProgress:newProgress];
        }
        //        }
        //        }else if(m_currentState == DOWNLOADING){
        /*
         [m_downProgressBar setProgress:newProgress animated:YES];
         [m_lblProgressInfo setText:[NSString stringWithFormat:@"%.2f/%.2f(MB), %.2f%%"
         ,_totalBytesExpectedToRead*newProgress/1024.0f/1024.0f
         ,(unsigned long)_totalBytesExpectedToRead/1024.0f/1024.0f
         ,newProgress*100.0f]];*/
        //        }
    }
    
    
}

-(void)checkFramesByPath:(NSString *)path{
    NSLog(@"Start checkFramesByPath");
    frames = 0;
//    VideoFrameExtractor *m_framer = [[VideoFrameExtractor alloc] initWithVideoMemory:path];
    VideoFrameExtractor *m_framer = [[VideoFrameExtractor alloc] initWithVideo:path];
    if (!m_framer) {
        NSLog(@"checkFramesByPath init failed");
        [[StaticHttpRequest sharedInstance] sleepWithTimeInterval:1.0f Function:__func__ Line:__LINE__ File:__FILE__];
        frames = -1;
        return;
    }
    
    int64_t tmpDuration = [m_framer getDuration];
    
    if (tmpDuration > 0) {
        NSLog(@"checkFramesByPath duration %f",(CGFloat)tmpDuration/AV_TIME_BASE);
        AVPacket tmpPacket;
        int iFrameType = 0;
        if ([m_framer getAVPacket:&tmpPacket frameType:&iFrameType]) {
            if (iFrameType == RECORD_VIDEO_IFRAME || iFrameType == RECORD_VIDEO_PFRAME) {
                m_framer = nil;
                NSLog(@"Finish checkFramesByPath");
                frames = 1;
            }else{
                m_framer = nil;
                NSLog(@"checkFramesByPath got no video frame");
                [[StaticHttpRequest sharedInstance] sleepWithTimeInterval:1.0f Function:__func__ Line:__LINE__ File:__FILE__];
                frames = -1;
            }
        }else{
            m_framer = nil;
            NSLog(@"checkFramesByPath got no frame");
            [[StaticHttpRequest sharedInstance] sleepWithTimeInterval:1.0f Function:__func__ Line:__LINE__ File:__FILE__];
            frames = -1;
        }
    }else{
        m_framer = nil;
        NSLog(@"checkFramesByPath got no duration");
        [[StaticHttpRequest sharedInstance] sleepWithTimeInterval:1.0f Function:__func__ Line:__LINE__ File:__FILE__];
        frames = -1;
    }
}

-(void)updateDownloadProgress:(CGFloat)value{
    [playerView updateDownloadProgress:value];
}

-(void)dothing:(NSString*) path{

    if (!m_httpSender) {
        m_httpSender = [StaticHttpRequest sharedInstance];
    }
    
    //    fileItemData* tmpPlaybackFiel = [m_aryFileList objectAtIndex:_cell.tag];
    //    NSString* path = tmpPlaybackFiel.m_strFileUrl;
    
    //    m_currentState = PLAYING;
    
    NSLog(@"path:%@",path);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self getDurationByPath:path];
    });
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; //Get the docs directory
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentsPath = [documentsDirectory stringByAppendingPathComponent:@".tmp"];
    
    [fileManager removeItemAtPath:documentsPath error:nil];
    
    if (![fileManager fileExistsAtPath:documentsPath]){
        [fileManager createDirectoryAtPath:documentsPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    //    m_aviTmpPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"tmp.avi"];
    //    m_recordingPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"tmp.mov"];
    
    NSURL *url = [NSURL URLWithString:path];
    
    m_aviTmpPath = [[NSString alloc] initWithFormat:@"%@/%@%@", documentsPath, @"tmp.", [url pathExtension]];
    m_recordingPath = [[NSString alloc] initWithFormat:@"%@/%@", documentsPath, @"tmp.mov"];
    
    
    NSError *err;
    
//    [fileManager removeItemAtPath:m_aviTmpPath error:&err];
    
    NSArray *files=[fileManager contentsOfDirectoryAtPath:documentsPath error:&err];
    NSLog(@"mag1 directory: %@",files);
    
    [m_httpSender doDownloadtoPath:m_aviTmpPath
                               url:path
                        callbackID:nil
                            target:self];
}

-(void)getDurationByPath:(NSString *)path{
    NSLog(@"Start getDurationByPath");
    AVFormatContext *formatCtx = NULL;
    playingFileContextDuration = 0;
    formatCtx = avformat_alloc_context();
    if (!formatCtx) {
        NSLog(@"getDurationByPath AVFormatContext alloc failed");
        playingFileContextDuration = -1;
        return;
    }
    
    if (avformat_open_input(&formatCtx, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL) < 0) {
        
        if (formatCtx)
            avformat_free_context(formatCtx);
        playingFileContextDuration = -1;
        NSLog(@"getDurationByPath Open input failed");
        return;
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        avformat_close_input(&formatCtx);
        playingFileContextDuration = -1;
        NSLog(@"getDurationByPath Stream Info Not Found");
        return;
    }
    
    if (!formatCtx)
    {
        playingFileContextDuration = -1;
    }
    else
    {
        if (formatCtx-> duration > 0) {
            playingFileContextDuration = formatCtx->duration;
        }else{
            playingFileContextDuration = -1;
            NSLog(@"getDurationByPath No Duration");
        }
        
    }
    avformat_close_input(&formatCtx);
    NSLog(@"Finish getDurationByPath %f",(CGFloat)playingFileContextDuration / AV_TIME_BASE);
}

-(void)doneDidTouch{
    [self doneDidTouch:nil];
}

- (void) doneDidTouch: (id) sender
{
    if (self.presentingViewController || !self.navigationController){
        /*
        UINavigationController* nagVC = (UINavigationController*)self.presentingViewController;
        NSLog(@"%@",nagVC.viewControllers);
        UIViewController * v = nagVC.viewControllers[nagVC.viewControllers.count-1];
        
        [self dismissViewControllerAnimated:NO completion:^{
            [v dismissViewControllerAnimated:YES completion:nil];
        }];*/
        
        //        UINavigationController* nagVC = (UINavigationController*)self.presentingViewController;
        //        NSLog(@"%@",nagVC.viewControllers);
        //        [nagVC.viewControllers[nagVC.viewControllers.count-1] dismissViewControllerAnimated:YES completion:nil
        //         ];
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self stopDownload];
        }];
    }else{
        [self stopDownload];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) playDidTouch: (id) sender
{
    if(!playerView){
        return;
    }else{
        [playerView playDidTouch:nil];
    }
}

- (BOOL) forwardAfterEndVideo{
    videoPosition++;
    
    if (videoPosition >= [videoArray count]) {
        return false;
    }
    
    [self changeVideo:videoArray :videoPosition];
    return true;
}

-(void) forwardDidTouch{
    
    [self forwardDidTouch:nil];
}

- (void) forwardDidTouch: (id) sender
{
    if(self.view.userInteractionEnabled==NO)
        return;
    self.view.userInteractionEnabled = NO;
    //    [self setMoviePosition: _moviePosition + 10];
    videoPosition++;
    
    if (videoPosition >= [videoArray count]) {
        videoPosition = 0;
    }
    
    [self changeVideo:videoArray :videoPosition];
}

-(void) rewindDidTouch{
    
    [self rewindDidTouch:nil];
}

- (void) rewindDidTouch: (id) sender
{
    if(self.view.userInteractionEnabled==NO)
        return;
    self.view.userInteractionEnabled = NO;
    //    [self setMoviePosition: _moviePosition - 10];
    //[self setMoviePosition: _moviePosition - 10];
    if (videoPosition <= 0) {
        videoPosition = [videoArray count];
    }
    videoPosition--;
    
    [self changeVideo:videoArray :videoPosition];
}

- (void)changeVideo: (NSArray *) videoArray :(int) videoPosition
{
    if(playerView!=nil){
//        if([playerView isHideHUD]!=_hiddenHUD){
            [self showHUD:![playerView isHideHUD]];
//        }
        [playerView pauseAndRelease];
        [playerView dismissViewControllerAnimated:NO completion:^{
            
            [self initKxVideo];
            NSString* path = videoArray[videoPosition];
            //NSAssert(path.length > 0, @"empty path");
            NSLog(@"Path Length : %lu",(unsigned long)path.length);
            videoPath = path;
            
            //            NSLog(@"KxMovie Wait Start");
//                        sleep(3);
            //            NSLog(@"Kxmovie wait finish");
            
            av_register_all();
            avformat_network_init();
            if(type==FROM_NET)
                [self createKxMovieViewControllerWithPath:videoPath isSliderMax:true];
//                [self dothing:videoPath];
            else
                [self createKxMovieViewControllerWithPath:videoPath isSliderMax:false];
            

        }];
        
    }
}

-(void)createKxMovieViewControllerWithPath:(NSString*)path isSliderMax: (bool)isSliderMax{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    // increase buffering for .wmv, it solves problem with delaying audio frames
//    if ([m_aviTmpPath.pathExtension isEqualToString:@"wmv"]) {
//        parameters[KxMovieParameterMinBufferedDuration] = @(5.0);
//    }
    
//    if ([path.pathExtension isEqualToString:@"wmv"]) {
    if(type==FROM_NET){
        parameters[KxMovieParameterMinBufferedDuration] = @(1.0);
        parameters[KxMovieParameterMidBufferedDuration] = @(2.0);
        parameters[KxMovieParameterMaxBufferedDuration] = @(3.0);
    }else{
        parameters[KxMovieParameterMinBufferedDuration] = @(1.0);
        parameters[KxMovieParameterMaxBufferedDuration] = @(2.0);
    }
//    }
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    }
    
    playerView = [KxMovieViewController movieViewControllerWithContentPath:path parameters:parameters duration:playingFileContextDuration isSliderMax:isSliderMax];
//     playerView = [KxMovieViewController movieViewControllerWithContentPath:@"http://vimeo-prod-src-std-asia.storage.googleapis.com/videos/400655962?GoogleAccessId=GOOGHOVZWCHVINHSLPGA&Expires=1438768964&Signature=Vo%2BNBiicblHfUkBJX4Tlxm25tio%3D" parameters:parameters duration:playingFileContextDuration isSliderMax:isSliderMax];
     playerView.delegate = self;
    playerView.isSinglePlay = self.isSinglePlay;
//    playerView.fullscreen = self.fullscreen;
    
    //[self presentViewController:playerView animated:NO completion:nil];
    
    [self presentViewController:playerView animated:NO completion:^{
        [self.delegate didVideoPlay:path];
        
        if(type==FROM_LOCAL)
            [playerView updateDownloadProgress:1.0];
        else if(isSliderMax){
            [playerView updateDownloadProgress:0.0];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            
            self.view.userInteractionEnabled = YES;
        });
        
    }];
}

-(void) initKxVideo
{
    //    [self startSearchPlaybackFile];
    if (m_httpSender) {
        [self stopDownload];
    }
//    m_currentState = WAITTING;
    frames = -1;
    if (playerView) {
        playerView = nil;
    }
}

-(void)stopDownload{
    if (m_httpSender) {
        [m_httpSender stopDownload];
    }
}

- (void) showHUD: (BOOL) show
{
    _hiddenHUD = !show;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];

    CGFloat alpha = _hiddenHUD ? 0 : 1;
    _topBar.alpha = alpha;
    _topHUD.alpha = alpha;
    _bottomBar.alpha = alpha;
    
//    [UIView animateWithDuration:0.2
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
//                     animations:^{
//                         
//                         CGFloat alpha = _hiddenHUD ? 0 : 1;
//                         _topBar.alpha = alpha;
//                         _topHUD.alpha = alpha;
//                         _bottomBar.alpha = alpha;
//                     }
//                     completion:nil];
    
}

@end
