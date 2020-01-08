//
//  ViewController.m
//  kxmovieapp
//
//  Created by Kolyvan on 11.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import "KxMovieViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "KxMovieDecoder.h"
#import "KxAudioManager.h"
#import "KxMovieGLView.h"
#import "KxLogger.h"
#import "AppDelegate.h"
#include "libavformat/avformat.h"
//#import "HttpAPICommander.h"
#import "VideoFrameExtractor.h"
#import "AFHTTPRequestOperationManager.h"
#import "UIColor+Helper.h"
#ifdef MESSHUDrive
#import "ColorDefine.h"
#endif
#import "Masonry.h"
#import "StaticLanguage.h"

NSString * const KxMovieParameterMinBufferedDuration = @"KxMovieParameterMinBufferedDuration";
NSString * const KxMovieParameterMaxBufferedDuration = @"KxMovieParameterMaxBufferedDuration";
NSString * const KxMovieParameterDisableDeinterlacing = @"KxMovieParameterDisableDeinterlacing";
NSString * const KxMovieParameterMidBufferedDuration = @"KxMovieParameterMidBufferedDuration";

////////////////////////////////////////////////////////////////////////////////

static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;

    NSMutableString *format = [(isLeft && seconds >= 1.0 ? @"-" : @"") mutableCopy];
    if (h != 0) [format appendFormat:@"%d:%0.2d", h, m];
    else        [format appendFormat:@"%d", m];
    [format appendFormat:@":%0.2d", s];

    return format;
}

////////////////////////////////////////////////////////////////////////////////

enum {

    KxMovieInfoSectionGeneral,
    KxMovieInfoSectionVideo,
    KxMovieInfoSectionAudio,
    KxMovieInfoSectionSubtitles,
    KxMovieInfoSectionMetadata,    
    KxMovieInfoSectionCount,
};

enum {

    KxMovieInfoGeneralFormat,
    KxMovieInfoGeneralBitrate,
    KxMovieInfoGeneralCount,
};

////////////////////////////////////////////////////////////////////////////////


static NSMutableDictionary * gHistory;

#define LOCAL_MIN_BUFFERED_DURATION   2.0//0.2
#define LOCAL_MAX_BUFFERED_DURATION   4.0//0.4
#define NETWORK_MIN_BUFFERED_DURATION 2.0
#define NETWORK_MAX_BUFFERED_DURATION 4.0
#define UPDATE_POSITION_INTERVAL 0.8

#define REGISTER_HWACCEL(X,x) { \
extern AVHWAccel ff_##x##_hwaccel; \
if(CONFIG_##X##_HWACCEL) av_register_hwaccel(&ff_##x##_hwaccel); }

@interface KxMovieViewController () {
    NSTimer *queueTimer;
    NSTimer *bufferChangeTimer;
    dispatch_once_t __onceToken;

    KxMovieDecoder      *_decoder;
    dispatch_queue_t    _dispatchQueue;
    NSMutableArray      *_videoFrames;
    NSMutableArray      *_audioFrames;
    NSMutableArray      *_subtitles;
    NSData              *_currentAudioFrame;
    NSUInteger          _currentAudioFramePos;
    CGFloat             _moviePosition;
    BOOL                _disableUpdateHUD;
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger          _tickCounter;
    BOOL                _fullscreen;
//    BOOL                _hiddenHUD;
    BOOL                _fitMode;
    BOOL                _infoMode;
    BOOL                _restoreIdleTimer;
    BOOL                _interrupted;

    KxMovieGLView       *_glView;
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
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
        
#ifdef DEBUG
    UILabel             *_messageLabel;
    NSTimeInterval      _debugStartTime;
    NSUInteger          _debugAudioStatus;
    NSDate              *_debugAudioStatusTS;
#endif

    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    CGFloat             _midBufferedDuration;
    BOOL                _buffered;
    
    BOOL                _savedIdleTimer;
    
    NSDictionary        *_parameters;
    
    int                 _videoPosition;
    NSArray             *_pathArray;
    
    NSMutableDictionary* targetDictionary;
    
    int frames;
    CGFloat progressosOffset;
    
    bool _isSliderMax;
    BOOL playModeFirst;
}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;
@property (readwrite, strong) KxArtworkFrame *artworkFrame;
@end

@implementation KxMovieViewController

NSString *m_recordingPath;
NSString *m_aviTmpPath;
NSInteger m_CurrentOSVersion;
BOOL      _hiddenHUD;

+ (void)initialize
{
    if (!gHistory)
        gHistory = [NSMutableDictionary dictionary];
}

- (BOOL)prefersStatusBarHidden { return YES; }

-(void)dothing:(NSString*) path{
    NSLog(@"path:%@",path);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self getDurationByPath:path];
    });
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    
    //    m_aviTmpPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"tmp.avi"];
    //    m_recordingPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"tmp.mov"];
    m_aviTmpPath = [[NSString alloc] initWithFormat:@"%@/%@", documentsPath, @"tmp.mp4"];
    m_recordingPath = [[NSString alloc] initWithFormat:@"%@/%@", documentsPath, @"tmp.mov"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    
    [fileManager removeItemAtPath:m_aviTmpPath error:&err];
}

+ (id) movieViewControllerWithContentPath: (NSArray *) pathArray
                            videoPosition: (int)videoPosition
{

    av_register_all();
//    avcodec_register_all();

    avformat_network_init();
    
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    [audioManager activateAudioSession];
    return [[KxMovieViewController alloc] initWithContentPath: pathArray videoPosition: videoPosition];
}

- (id) initWithContentPath: (NSArray *) pathArray
             videoPosition: (int) videoPosition
{
    _videoPosition = videoPosition;
    _pathArray = pathArray;
    NSString* path = _pathArray[_videoPosition];
    //NSAssert(path.length > 0, @"empty path");
    NSLog(@"Path Length : %lu",(unsigned long)path.length);
    

    
    [self dothing:path];
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    // increase buffering for .wmv, it solves problem with delaying audio frames
    if ([path.pathExtension isEqualToString:@"wmv"]) {
        parameters[KxMovieParameterMinBufferedDuration] = @(5.0);
    }
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    }
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        _moviePosition = 0;
        //        self.wantsFullScreenLayout = YES;
        
        _parameters = parameters;
        
        __weak KxMovieViewController *weakSelf = self;
        
        KxMovieDecoder *decoder = [[KxMovieDecoder alloc] init];
        
        decoder.interruptCallback = ^BOOL(){
            
            __strong KxMovieViewController *strongSelf = weakSelf;
            return strongSelf ? [strongSelf interruptDecoder] : YES;
        };
        
        _path = path;
        _decoder = decoder;
//        _weakSelf = weakSelf;
        
    }
    return self;
}

NSString * _path;
KxMovieDecoder * _decoder;
//__weak KxMovieViewController * _weakSelf;

-(void)playVideo{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        /*
         if ([DataManager sharedInstance].uidLoginStatus) {
         [[DataManager sharedInstance] startTunnel:[[NSUserDefaults standardUserDefaults] stringForKey:@"UID"]:9091 :YES];
         }
         if ([DataManager sharedInstance].uidLoginStatus) {
         [[DataManager sharedInstance] startTunnel:[[NSUserDefaults standardUserDefaults] stringForKey:@"UID"]:9000 :YES];
         }*/
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self getDurationByPath:_path];
            
            NSError *error = nil;
            [_decoder openFile:m_aviTmpPath error:&error duration:playingFileContextDuration];
            //                [decoder openFile:path error:&error duration:playingFileContextDuration];
            
            NSLog(@"%lld",playingFileContextDuration);
            
            __strong KxMovieViewController *strongSelf = self;
            if (strongSelf) {
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [strongSelf setMovieDecoder:_decoder withError:error];
                });
            }
        });
        
        
    });
}

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                 duration: (int64_t)contextDuration
                                 isSliderMax: (bool)isSliderMax
{    
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    [audioManager activateAudioSession];    
    return [[KxMovieViewController alloc] initWithContentPath: path parameters: parameters duration:contextDuration isSliderMax:isSliderMax];
}

- (id) initWithContentPath: (NSString *) path
                parameters: (NSDictionary *) parameters
                  duration: (int64_t) contextDuration
                    isSliderMax: (bool)isSliderMax
{
    NSAssert(path.length > 0, @"empty path");
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        _isSliderMax = isSliderMax;
        
        _moviePosition = 0;
//        self.wantsFullScreenLayout = YES;

        _parameters = parameters;
        
        __weak KxMovieViewController *weakSelf = self;
        
        KxMovieDecoder *decoder = [[KxMovieDecoder alloc] init];
        
        decoder.interruptCallback = ^BOOL(){
            
            __strong KxMovieViewController *strongSelf = weakSelf;
            return strongSelf ? [strongSelf interruptDecoder] : YES;
        };
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
            NSError *error = nil;
            [decoder openFile:path error:&error duration:contextDuration];
                        
            __strong KxMovieViewController *strongSelf = weakSelf;
            if (strongSelf) {
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [strongSelf setMovieDecoder:decoder withError:error];                    
                });
            }
        });
    }
    return self;
}

- (void) dealloc
{
    [self pause];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_dispatchQueue) {
        // Not needed as of ARC.
//        dispatch_release(_dispatchQueue);
        _dispatchQueue = NULL;
    }
    
    LoggerStream(1, @"%@ dealloc", self);
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

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    
    [self.view addSubview:_activityIndicatorView];
    
    [_activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
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

    _progressLabel = [[UILabel alloc] init];
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
//    if(_isSliderMax){
//        _progressSlider.rightValue = 0.5;
//    }
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

    if (_decoder) {
        
        [self setupPresentView];
        
    } else {
        
        _progressLabel.hidden = YES;
        _progressSlider.hidden = YES;
        _leftLabel.hidden = YES;
        _infoButton.hidden = YES;
    }
    
    if(_hiddenHUD){
        [self showHUD: NO];
    }else{
        [self showHUD: YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
    if (applicationState != UIApplicationStateBackground) {
        if(_bufferedDuration -0.5f <= 0){
//            _maxBufferedDuration = _bufferedDuration;
            _maxBufferedDuration = 0;
            _minBufferedDuration = 0;
            _midBufferedDuration = -10; //disable
            [_decoder receiveMemoryWarning];
            return;
        }
        float newMaxBufferedDuration = _minBufferedDuration;
        if(newMaxBufferedDuration < _bufferedDuration -0.5f){
            _maxBufferedDuration = newMaxBufferedDuration;
        }else{
            _maxBufferedDuration = _bufferedDuration -0.5f;
        }
//        if(_maxBufferedDuration - 1.0f < _minBufferedDuration){
//            return;
//        }
//        _maxBufferedDuration -= 1.0f;
        if(_minBufferedDuration > _maxBufferedDuration){
            _minBufferedDuration = _maxBufferedDuration;
        }
        [_decoder receiveMemoryWarning];
        return;
    }
    
    NSLog(@"didReceiveMemoryWarning kxMovie");
    
    if (self.playing) {
        
        [self pause];
        [self freeBufferedFrames];
        
        if (_maxBufferedDuration > 0) {
            
            _minBufferedDuration = _maxBufferedDuration = 0;
            [self play];
            
            LoggerStream(0, @"didReceiveMemoryWarning, disable buffering and continue playing");
            
        } else {
            
            // force ffmpeg to free allocated memory
            [_decoder closeFile];
            [_decoder openFile:nil error:nil duration:0];
            
            [[[UIAlertView alloc] initWithTitle:_(@"FAILURE")
                                        message:_(@"OUT_OF_MEMORY")
                                       delegate:nil
                              cancelButtonTitle:_(@"ButtonTextOk")
                              otherButtonTitles:nil] show];
        }
        
    } else {
        
        [self freeBufferedFrames];
        [_decoder closeFile];
        [_decoder openFile:nil error:nil duration:0];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    // LoggerStream(1, @"viewDidAppear");
    
    [super viewDidAppear:animated];
    
    if (self.presentingViewController)
        [self fullscreenMode:YES];
    
    if (_infoMode)
        [self showInfoView:NO animated:NO];
    
    _savedIdleTimer = [[UIApplication sharedApplication] isIdleTimerDisabled];
    
//    [self showHUD: YES];
    if(_hiddenHUD){
        [self showHUD: NO];
    }else{
        [self showHUD: YES];
    }
    
    if (_decoder) {
        
        [self restorePlay];
        
    } else {

        [_activityIndicatorView startAnimating];
    }
   
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    [UIApplication sharedApplication].idleTimerDisabled=YES;//not let iphone go to sleep
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [_activityIndicatorView stopAnimating];
    
    if (_decoder) {
          
        [self pause];
        
        if (_moviePosition == 0 || _decoder.isEOF)
            [gHistory removeObjectForKey:_decoder.path];
#ifdef RestorePlay
        else if (!_decoder.isNetwork)
            [gHistory setValue:[NSNumber numberWithFloat:_moviePosition]
                        forKey:_decoder.path];
#endif
         [_decoder closeFile];
        [_decoder openFile:nil error:nil duration:0];
                    _decoder = nil;
    }
    
    if (_fullscreen)
        [self fullscreenMode:NO];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_savedIdleTimer];
    
    [_activityIndicatorView stopAnimating];
    _buffered = NO;
    _interrupted = YES;
    
    LoggerStream(1, @"viewWillDisappear %@", self);
    
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) applicationWillResignActive: (NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self showHUD:YES];
        [self pause];
    });
    
    LoggerStream(1, @"applicationWillResignActive");
}

#pragma mark - gesture recognizer

- (void) handleTap: (UITapGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        if (sender == _tapGestureRecognizer) {

            [self showHUD: _hiddenHUD];
            
        } else if (sender == _doubleTapGestureRecognizer) {
                
            UIView *frameView = [self frameView];
            
            if (frameView.contentMode == UIViewContentModeScaleAspectFit)
                frameView.contentMode = UIViewContentModeScaleAspectFill;
            else
                frameView.contentMode = UIViewContentModeScaleAspectFit;
            
        }        
    }
}

- (void) handlePan: (UIPanGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        const CGPoint vt = [sender velocityInView:self.view];
        const CGPoint pt = [sender translationInView:self.view];
        const CGFloat sp = MAX(0.1, log10(fabsf(vt.x)) - 1.0);
        const CGFloat sc = fabsf(pt.x) * 0.33 * sp;
        if (sc > 10) {
            
            const CGFloat ff = pt.x > 0 ? 1.0 : -1.0;            
            [self setMoviePosition: _moviePosition + ff * MIN(sc, 600.0)];
        }
        //LoggerStream(2, @"pan %.2f %.2f %.2f sec", pt.x, vt.x, sc);
    }
}

#pragma mark - public

-(void) play
{
    if (self.playing)
        return;
    
    if (!_decoder.validVideo &&
        !_decoder.validAudio) {
        
        return;
    }
    
    if (_interrupted)
        return;

    self.playing = YES;
    _interrupted = NO;
    _disableUpdateHUD = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;

#ifdef DEBUG
    _debugStartTime = -1;
#endif

//    if(_decoder.getBufferDuration < 20){
//        [_decoder readFrames];
//    }else{
//        [self asyncDecodeFrames];
//    }

    [self asyncDecodeFrames];
    
    [self updatePlayButton];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });

    if (_decoder.validAudio)
        [self enableAudio:YES];

    LoggerStream(1, @"play movie");
}

- (void) pause
{
    if (!self.playing)
        return;

    self.playing = NO;
//    _interrupted = YES;
    [self enableAudio:NO];
    [self updatePlayButton];
    LoggerStream(1, @"pause movie");
}

-(void)updateDownloadProgress:(CGFloat)value{
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (_progressSlider) {
            _progressSlider.rightValue = value;
        }
    //});
}

-(void)resetBufferProgress{
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
    if(!_isSliderMax)//Local
        return;
    if (_progressSlider) {
        _progressSlider.rightValue = _progressSlider.leftValue;
    }
    //});
}

-(void)updateBufferProgressBy:(double)value{
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
    if(!_isSliderMax)//Local
        return;
    if (_progressSlider) {
        if(_progressSlider.rightValue < _moviePosition/_decoder.duration + value)
            _progressSlider.rightValue = _moviePosition/_decoder.duration + value;
    }
    //});
}

-(void)updateBufferProgressTo:(double)value{
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
    if(!_isSliderMax)//Local
        return;
    if (_progressSlider) {
        if(_progressSlider.rightValue < value)
            _progressSlider.rightValue = value;
    }
    //});
}

- (void) setMoviePosition: (CGFloat) position
{
   __block BOOL playMode = self.playing;
    
    self.playing = NO;
    _disableUpdateHUD = YES;
    [self enableAudio:NO];
    
    if(!_isSliderMax){ //Local
        [self updatePosition:position playMode:playMode];
    }else{ //Net
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if (queueTimer!=nil) {
                playMode = playModeFirst;
                [queueTimer invalidate];
                queueTimer = nil;
            }else{
                playModeFirst = playMode;
            }
            
            NSMutableDictionary* tmpDictionary = [NSMutableDictionary dictionary];
            [tmpDictionary setObject:@(position) forKey:@"POSITION"];
            [tmpDictionary setObject:@(playMode) forKey:@"PLAYMODE"];
            
    //        queueTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(exec:) userInfo:tmpDictionary repeats:NO];
            queueTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_POSITION_INTERVAL target:self selector:@selector(exec:) userInfo:tmpDictionary repeats:NO];
            
    //        [self updatePosition:position playMode:playMode];
        });
    }
}

#pragma mark - actions

- (void) doneDidTouch: (id) sender
{
    _hiddenHUD = NO;
    if (self.presentingViewController || !self.navigationController){
        [self pauseAndRelease];
        
        [self dismissViewControllerAnimated:NO completion:^{
            [self.delegate doneDidTouch];
        }];
        
    }else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void) infoDidTouch: (id) sender
{
    [self showInfoView: !_infoMode animated:YES];
}

- (void) playDidTouch: (id) sender
{
    if (self.playing)
        [self pause];
    else
        [self play];
}

- (void) forwardAfterEndVideo{
    if(![self.delegate forwardAfterEndVideo]){
        [self doneDidTouch:nil];
    };
}

- (void) forwardDidTouch: (id) sender
{
//    self.view.userInteractionEnabled = NO;
    [self.delegate forwardDidTouch];
}

- (void) rewindDidTouch: (id) sender
{
//    self.view.userInteractionEnabled = NO;
    [self.delegate rewindDidTouch];
}

#pragma mark BJRangeSliderWithProgressDelegate
-(void)progressDidChange:(CGFloat)value{
    [self setMoviePosition:value * _decoder.duration];
}

#pragma mark - private

- (void) setMovieDecoder: (KxMovieDecoder *) decoder
               withError: (NSError *) error
{
    LoggerStream(2, @"setMovieDecoder");
            
    if (!error && decoder) {
        
        _decoder        = decoder;
        _dispatchQueue  = dispatch_queue_create("KxMovie", DISPATCH_QUEUE_SERIAL);
        _videoFrames    = [NSMutableArray array];
        _audioFrames    = [NSMutableArray array];
        
        if (_decoder.subtitleStreamsCount) {
            _subtitles = [NSMutableArray array];
        }
    
        if (_decoder.isNetwork) {
            
            _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
            
        } else {
            
            _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
        }
        
        if (!_decoder.validVideo)
            _minBufferedDuration *= 10.0; // increase for audio
                
        // allow to tweak some parameters at runtime
        if (_parameters.count) {
            
            id val;
            
            val = [_parameters valueForKey: KxMovieParameterMinBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _minBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: KxMovieParameterMaxBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _maxBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: KxMovieParameterDisableDeinterlacing];
            if ([val isKindOfClass:[NSNumber class]]){
                _decoder.disableDeinterlacing = [val boolValue];
            }
            
            val = [_parameters valueForKey: KxMovieParameterMidBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]]){
                _midBufferedDuration = [val floatValue];
            }
            
            if (_maxBufferedDuration < _minBufferedDuration)
                _maxBufferedDuration = _minBufferedDuration * 2;
        }
        
        LoggerStream(2, @"buffered limit: %.1f - %.1f", _minBufferedDuration, _maxBufferedDuration);
        
        if (self.isViewLoaded) {
            
            [self setupPresentView];
            
            _progressLabel.hidden   = NO;
            _progressSlider.hidden  = NO;
            _leftLabel.hidden       = NO;
//            _infoButton.hidden      = NO;
            
            if (_activityIndicatorView.isAnimating) {
                
                [_activityIndicatorView stopAnimating];
                // if (self.view.window)
                [self restorePlay];
            }
        }
        
    } else {
        
         if (self.isViewLoaded && self.view.window) {
        
             [_activityIndicatorView stopAnimating];
             if (!_interrupted)
                 [self handleDecoderMovieError: error];
         }
    }
}

- (void) restorePlay
{
    NSNumber *n = [gHistory valueForKey:_decoder.path];
    if (n)
        [self updatePosition:n.floatValue playMode:YES];
    else
        [self play];
}

- (void) setupPresentView
{
    CGRect bounds = self.view.bounds;
    
    if (_decoder.validVideo) {
        //iOS BUG! Cannot use CGRectZero, otherwise the glview will render nothing.
        _glView = [[KxMovieGLView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) decoder:_decoder];
    } 
    
    if (!_glView) {
        
        LoggerVideo(0, @"fallback to use RGB video frame and UIKit");
        [_decoder setupVideoFrameFormat:KxVideoFrameFormatRGB];
        _imageView = [[UIImageView alloc] initWithFrame:bounds];
        _imageView.backgroundColor = [UIColor blackColor];
    }
    
    UIView *frameView = [self frameView];
    frameView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view insertSubview:frameView atIndex:0];
    
    [frameView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(self.view);
//        make.width.equalTo(self.view);
//        make.height.equalTo(frameView.mas_width).multipliedBy(9.0/16.0);
        make.edges.equalTo(self.view);
    }];
    
    if (_decoder.validVideo) {
    
        [self setupUserInteraction];
    
    } else {
       
        _imageView.image = [UIImage imageNamed:@"kxmovie.bundle/music_icon.png"];
        _imageView.contentMode = UIViewContentModeCenter;
    }
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if (_decoder.duration == MAXFLOAT) {
        
        _leftLabel.text = @"\u221E"; // infinity
        _leftLabel.font = [UIFont systemFontOfSize:14];
        
        CGRect frame;
        
        frame = _leftLabel.frame;
        frame.origin.x += 40;
        frame.size.width -= 40;
        _leftLabel.frame = frame;
        
        frame =_progressSlider.frame;
        frame.size.width += 40;
        _progressSlider.frame = frame;
        
    } else {
        
//        [_progressSlider addTarget:self
//                            action:@selector(progressDidChange:)
//                  forControlEvents:UIControlEventValueChanged];
        _progressSlider.delegate = self;
    }
    
    if (_decoder.subtitleStreamsCount) {
        
        CGSize size = self.view.bounds.size;
        
        _subtitlesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, size.height, size.width, 0)];
        _subtitlesLabel.numberOfLines = 0;
        _subtitlesLabel.backgroundColor = [UIColor clearColor];
        _subtitlesLabel.opaque = NO;
        _subtitlesLabel.adjustsFontSizeToFitWidth = NO;
        _subtitlesLabel.textAlignment = NSTextAlignmentCenter;
        _subtitlesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _subtitlesLabel.textColor = [UIColor whiteColor];
        _subtitlesLabel.font = [UIFont systemFontOfSize:16];
        _subtitlesLabel.hidden = YES;

        [self.view addSubview:_subtitlesLabel];
    }
}

- (void) setupUserInteraction
{
    UIView * view = [self frameView];
    view.userInteractionEnabled = YES;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    [_tapGestureRecognizer requireGestureRecognizerToFail: _doubleTapGestureRecognizer];
    
    [view addGestureRecognizer:_doubleTapGestureRecognizer];
    [view addGestureRecognizer:_tapGestureRecognizer];
    
//    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
//    _panGestureRecognizer.enabled = NO;
//    
//    [view addGestureRecognizer:_panGestureRecognizer];
}

- (UIView *) frameView
{
    return _glView ? _glView : _imageView;
}

- (void) audioCallbackFillData: (float *) outData
                     numFrames: (UInt32) numFrames
                   numChannels: (UInt32) numChannels
{
    //fillSignalF(outData,numFrames,numChannels);
    //return;

    if (_buffered) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }

    @autoreleasepool {
        
        while (numFrames > 0) {
            
            if (!_currentAudioFrame) {
                
                @synchronized(_audioFrames) {
                    
                    NSUInteger count = _audioFrames.count;
                    
                    if (count > 0) {
                        
                        KxAudioFrame *frame = _audioFrames[0];

#ifdef DUMP_AUDIO_DATA
                        LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
                        if (_decoder.validVideo) {
                        
                            const CGFloat delta = _moviePosition - frame.position;
                            
                            if (delta < -0.1) {
                                
                                memset(outData, 0, numFrames * numChannels * sizeof(float));
#ifdef DEBUG
                                LoggerStream(0, @"desync audio (outrun) wait %.4f %.4f", _moviePosition, frame.position);
                                _debugAudioStatus = 1;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                break; // silence and exit
                            }
                            
                            [_audioFrames removeObjectAtIndex:0];
                            
                            if (delta > 0.1 && count > 1) {
                                
#ifdef DEBUG
                                LoggerStream(0, @"desync audio (lags) skip %.4f %.4f", _moviePosition, frame.position);
                                _debugAudioStatus = 2;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                continue;
                            }
                            
                        } else {
                            
                            [_audioFrames removeObjectAtIndex:0];
                            _moviePosition = frame.position;
                            _bufferedDuration -= frame.duration;
                        }
                        
                        _currentAudioFramePos = 0;
                        _currentAudioFrame = frame.samples;                        
                    }
                }
            }
            
            if (_currentAudioFrame) {
                
                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;                
                
            } else {
                
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                //LoggerStream(1, @"silence audio");
#ifdef DEBUG
                _debugAudioStatus = 3;
                _debugAudioStatusTS = [NSDate date];
#endif
                break;
            }
        }
    }
}

- (void) enableAudio: (BOOL) on
{
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
            
    if (on && _decoder.validAudio) {
                
        audioManager.outputBlock = ^(float *outData, UInt32 numFrames, UInt32 numChannels) {
            
            [self audioCallbackFillData: outData numFrames:numFrames numChannels:numChannels];
        };
        
        [audioManager play];
        
        LoggerAudio(2, @"audio device smr: %d fmt: %d chn: %d",
                    (int)audioManager.samplingRate,
                    (int)audioManager.numBytesPerSample,
                    (int)audioManager.numOutputChannels);
        
    } else {
        
        [audioManager pause];
        audioManager.outputBlock = nil;
    }
}

- (BOOL) addFrames: (NSArray *)frames
{
    if (_decoder.validVideo) {
        
        @synchronized(_videoFrames) {
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeVideo) {
                    [_videoFrames addObject:frame];
                    _bufferedDuration += frame.duration;
//                    [self updateBufferProgressBy:_bufferedDuration/_decoder.duration];
//                    [self updateBufferProgressBy:[_decoder getBufferDuration]/_decoder.duration];
                    [self updateBufferProgressTo:[_decoder getBufferDuration]/_decoder.duration];
//                    NSLog(@"updateBufferProgressTo:%lf,%f",[_decoder getBufferDuration], _decoder.duration);
//                    NSLog(@"first %f last %f now %f",((KxMovieFrame*)_videoFrames.firstObject).position,((KxMovieFrame*)_videoFrames.lastObject).position,_decoder.position);
                }
        }
    }
    
    if (_decoder.validAudio) {
        
        @synchronized(_audioFrames) {
            
            for (KxMovieFrame *frame in frames)
                
                if (frame.type == KxMovieFrameTypeAudio) {
                    [_audioFrames addObject:frame];
                    if (!_decoder.validVideo){
                        _bufferedDuration += frame.duration;
//                        [self updateBufferProgressBy:_bufferedDuration/_decoder.duration];
//                        [self updateBufferProgressBy:[_decoder getBufferDuration]/_decoder.duration];
                        [self updateBufferProgressTo:[_decoder getBufferDuration]/_decoder.duration];
//                        NSLog(@"updateBufferProgressTo:%lf,%f",[_decoder getBufferDuration], _decoder.duration);
                    }
                }
        }
        
        if (!_decoder.validVideo) {
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeArtwork)
                    self.artworkFrame = (KxArtworkFrame *)frame;
        }
    }
    
    if (_decoder.validSubtitles) {
        
        @synchronized(_subtitles) {
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeSubtitle) {
                    [_subtitles addObject:frame];
                }
        }
    }
    
    return self.playing && _bufferedDuration < _maxBufferedDuration;
}

- (BOOL) decodeFrames
{
    //NSAssert(dispatch_get_current_queue() == _dispatchQueue, @"bugcheck");
    
    NSArray *frames = nil;
    
    if (_decoder.validVideo ||
        _decoder.validAudio) {
        
//        frames = [_decoder decodeFrames:0];
        [_decoder readFrames];
        frames = [_decoder decodeFramesNew:0];
    }
    
    if (frames.count) {
        return [self addFrames: frames];
    }
    return NO;
}

- (void) asyncDecodeFrames
{
    if (self.decoding)
        return;
    
    __weak KxMovieViewController *weakSelf = self;
    __weak KxMovieDecoder *weakDecoder = _decoder;
    
//    const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;
    const CGFloat duration = _decoder.isNetwork ? 0.0f : 0.0f;
    
    self.decoding = YES;
    
    dispatch_async(_dispatchQueue, ^{
        
        {
            __strong KxMovieViewController *strongSelf = weakSelf;
            if (!strongSelf.playing){
                strongSelf.decoding = NO;
                return;
            }
        }
        
        BOOL good = YES;
        while (good) {
            
            good = NO;
            
            @autoreleasepool {
                
                __strong KxMovieDecoder *decoder = weakDecoder;
                
                if (decoder && (decoder.validVideo || decoder.validAudio)) {
                    
//                    NSArray *frames;
//                    if(!_isSliderMax)//Local
//                    {
//                        frames = [decoder decodeFrames:duration];
//                    }else{
//                        [decoder readFrames];
//                        frames = [decoder decodeFramesNew:duration];
//                    }
                    
                    NSArray *frames = [decoder decodeFramesNew:duration];
                    if (frames.count) {
                        
                        __strong KxMovieViewController *strongSelf = weakSelf;
                        if (strongSelf)
                            good = [strongSelf addFrames:frames];
                    }
                }
            }
        }
                
        {
            __strong KxMovieViewController *strongSelf = weakSelf;
            if (strongSelf) strongSelf.decoding = NO;
        }
    });
}

- (void) tick
{
//    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || _decoder.isEOF)) {
//        
//        _tickCorrectionTime = 0;
//        _buffered = NO;
//        [_activityIndicatorView stopAnimating];        
//    }

    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || _decoder.isEOF)) {
        
        _tickCorrectionTime = 0;
        _buffered = NO;
        [_activityIndicatorView stopAnimating];
    }
    
    if (self.playing) {
        
        if(!_isSliderMax)//Local
        {
            [_decoder stopMaxBufferDuration];
        }else{
            if(_bufferedDuration > _midBufferedDuration){
                
                if (bufferChangeTimer==nil) {
                    bufferChangeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(changeBuffer:) userInfo:nil repeats:NO];
                }
                
                //            [_decoder increaseMaxBufferDuration];
            }else if(_bufferedDuration <= _midBufferedDuration){
                [bufferChangeTimer invalidate];
                bufferChangeTimer = nil;
                [_decoder stopMaxBufferDuration];
            }
        }
        
        CGFloat interval = 0;
        if (!_buffered)
            interval = [self presentFrame];
        
        const NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0);
        
        if (0 == leftFrames) {
            
//            if (_decoder.isEOF) {
//                [self pause];
//                [self updateHUD];
//                dispatch_async(dispatch_get_main_queue(), ^(void) {
////                    [self doneDidTouch:nil];
//                    [self forwardDidTouch:nil];
//                });
//                return;
//            }
            
            if (_minBufferedDuration > 0 && !_buffered) {
                                
                _buffered = YES;
                [_activityIndicatorView startAnimating];
            }
        }
        
        
        
        if (!leftFrames ||
//            !(_bufferedDuration > _minBufferedDuration)) {
            !(_bufferedDuration > _maxBufferedDuration)) {
            
//            if(_decoder.getBufferDuration < 20){
//                [_decoder readFrames];
//            }else{
//                [self asyncDecodeFrames];
//            }
            
            [self asyncDecodeFrames];
        }
        
        if ([_leftLabel.text isEqualToString:@"00:00"] ||
            [_leftLabel.text isEqualToString:@"0:00"] ||
            [_leftLabel.text isEqualToString:@"00"]) {
            
            dispatch_once(&__onceToken, ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
                    [self pause];
                    [self updateHUD];
//                    [self doneDidTouch:nil];
                    
                    if(self.isSinglePlay){
                        [self doneDidTouch:nil];
                    }else{
                        //[self forwardDidTouch:nil];
                        [self forwardAfterEndVideo];
                    }
                });
//                dispatch_async(dispatch_get_main_queue(), ^(void) {
//                    [self pause];
//                    [self updateHUD];
//                    [self doneDidTouch:nil];
//                });
            });
            
//            return; //not return immidiate, let the video more play 2s.
        }
        
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self tick];
        });
    }else{
        
//        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self tick];
            [_decoder readFrames];
//            [self updateBufferProgressBy:[_decoder getBufferDuration]/_decoder.duration];
            [self updateBufferProgressTo:[_decoder getBufferDuration]/_decoder.duration];
//            NSLog(@"updateBufferProgressTo:%lf,%f",[_decoder getBufferDuration], _decoder.duration);
            if (bufferChangeTimer==nil) {
                bufferChangeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(changeBuffer:) userInfo:nil repeats:NO];
            }
        });
    }
    
    if ((_tickCounter++ % 3) == 0) {
        [self updateHUD];
    }
}

- (CGFloat) tickCorrection
{
    if (_buffered)
        return 0;
    
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (!_tickCorrectionTime) {
        
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }
    
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    
    //if ((_tickCounter % 200) == 0)
    //    LoggerStream(1, @"tick correction %.4f", correction);
    
    if (correction > 1.f || correction < -1.f) {
        
        LoggerStream(1, @"tick correction reset %.2f", correction);
        correction = 0;
        _tickCorrectionTime = 0;
    }
    
    return correction;
}

- (CGFloat) presentFrame
{
    CGFloat interval = 0;
    
    if (_decoder.validVideo) {
        
        KxVideoFrame *frame;
        
        @synchronized(_videoFrames) {
            
            if (_videoFrames.count > 0) {
                
                frame = _videoFrames[0];
                [_videoFrames removeObjectAtIndex:0];
                _bufferedDuration -= frame.duration;
            }
        }
        
        if (frame)
            interval = [self presentVideoFrame:frame];
        
    } else if (_decoder.validAudio) {

        //interval = _bufferedDuration * 0.5;
                
        if (self.artworkFrame) {
            
            _imageView.image = [self.artworkFrame asImage];
            self.artworkFrame = nil;
        }
    }

    if (_decoder.validSubtitles)
        [self presentSubtitles];
    
#ifdef DEBUG
    if (self.playing && _debugStartTime < 0)
        _debugStartTime = [NSDate timeIntervalSinceReferenceDate] - _moviePosition;
#endif

    return interval;
}

- (CGFloat) presentVideoFrame: (KxVideoFrame *) frame
{
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
//    if (appDelegate.isBackground) {
//        return 0;
//    }
    
    if (_glView) {
        [_glView render:frame];
        
    } else {
        
        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
        _imageView.image = [rgbFrame asImage];
    }
    
    _moviePosition = frame.position;
        
    return frame.duration;
}

- (void) presentSubtitles
{
    NSArray *actual, *outdated;
    
    if ([self subtitleForPosition:_moviePosition
                           actual:&actual
                         outdated:&outdated]){
        
        if (outdated.count) {
            @synchronized(_subtitles) {
                [_subtitles removeObjectsInArray:outdated];
            }
        }
        
        if (actual.count) {
            
            NSMutableString *ms = [NSMutableString string];
            for (KxSubtitleFrame *subtitle in actual.reverseObjectEnumerator) {
                if (ms.length) [ms appendString:@"\n"];
                [ms appendString:subtitle.text];
            }
            
            if (![_subtitlesLabel.text isEqualToString:ms]) {
                
                CGSize viewSize = self.view.bounds.size;
                CGSize size = [ms sizeWithFont:_subtitlesLabel.font
                             constrainedToSize:CGSizeMake(viewSize.width, viewSize.height * 0.5)
                                 lineBreakMode:NSLineBreakByTruncatingTail];
                _subtitlesLabel.text = ms;
                _subtitlesLabel.frame = CGRectMake(0, viewSize.height - size.height - 10,
                                                   viewSize.width, size.height);
                _subtitlesLabel.hidden = NO;
            }
            
        } else {
            
            _subtitlesLabel.text = nil;
            _subtitlesLabel.hidden = YES;
        }
    }
}

- (BOOL) subtitleForPosition: (CGFloat) position
                      actual: (NSArray **) pActual
                    outdated: (NSArray **) pOutdated
{
    if (!_subtitles.count)
        return NO;
    
    NSMutableArray *actual = nil;
    NSMutableArray *outdated = nil;
    
    for (KxSubtitleFrame *subtitle in _subtitles) {
        
        if (position < subtitle.position) {
            
            break; // assume what subtitles sorted by position
            
        } else if (position >= (subtitle.position + subtitle.duration)) {
            
            if (pOutdated) {
                if (!outdated)
                    outdated = [NSMutableArray array];
                [outdated addObject:subtitle];
            }
            
        } else {
            
            if (pActual) {
                if (!actual)
                    actual = [NSMutableArray array];
                [actual addObject:subtitle];
            }
        }
    }
    
    if (pActual) *pActual = actual;
    if (pOutdated) *pOutdated = outdated;
    
    return actual.count || outdated.count;
}

- (void) updateBottomBar
{
    UIBarButtonItem *playPauseBtn = self.playing ? _pauseBtn : _playBtn;
    [_bottomBar setItems:@[_spaceItem, _rewindBtn, _fixedSpaceItem, playPauseBtn,
                           _fixedSpaceItem, _fforwardBtn, _spaceItem] animated:NO];
}

- (void) updatePlayButton
{
    [self updateBottomBar];
}

- (void) updateHUD
{
    if (_disableUpdateHUD)
        return;
    
    const CGFloat duration = _decoder.duration;
    const CGFloat position = _moviePosition -_decoder.startTime;
    
//    if (!_progressSlider.sliding)
//        _progressSlider.leftValue = position / duration;
    if (!_progressSlider.sliding){
        CGFloat newValue = position / duration;
//        if (newValue >= _progressSlider.rightValue) {
//            [self pause];
//        }
        _progressSlider.leftValue = newValue;
    }
    _progressLabel.text = formatTimeInterval(position, NO);
    
    if (_decoder.duration != MAXFLOAT)
        _leftLabel.text = formatTimeInterval(duration - position, YES);
/*
#ifdef DEBUG
    const NSTimeInterval timeSinceStart = [NSDate timeIntervalSinceReferenceDate] - _debugStartTime;
    NSString *subinfo = _decoder.validSubtitles ? [NSString stringWithFormat: @" %d",_subtitles.count] : @"";
    
    NSString *audioStatus;
    
    if (_debugAudioStatus) {
        
        if (NSOrderedAscending == [_debugAudioStatusTS compare: [NSDate dateWithTimeIntervalSinceNow:-0.5]]) {
            _debugAudioStatus = 0;
        }
    }
    
    if      (_debugAudioStatus == 1) audioStatus = @"\n(audio outrun)";
    else if (_debugAudioStatus == 2) audioStatus = @"\n(audio lags)";
    else if (_debugAudioStatus == 3) audioStatus = @"\n(audio silence)";
    else audioStatus = @"";

    _messageLabel.text = [NSString stringWithFormat:@"%d %d%@ %c - %@ %@ %@\n%@",
                          _videoFrames.count,
                          _audioFrames.count,
                          subinfo,
                          self.decoding ? 'D' : ' ',
                          formatTimeInterval(timeSinceStart, NO),
                          //timeSinceStart > _moviePosition + 0.5 ? @" (lags)" : @"",
                          _decoder.isEOF ? @"- END" : @"",
                          audioStatus,
                          _buffered ? [NSString stringWithFormat:@"buffering %.1f%%", _bufferedDuration / _minBufferedDuration * 100] : @""];
#endif
    */
}

- (void) showHUD: (BOOL) show
{
    _hiddenHUD = !show;    
    _panGestureRecognizer.enabled = _hiddenHUD;
        
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         
                         CGFloat alpha = _hiddenHUD ? 0 : 1;
                         _topBar.alpha = alpha;
                         _topHUD.alpha = alpha;
                         _bottomBar.alpha = alpha;
                     }
                     completion:nil];
    
}

- (void) fullscreenMode: (BOOL) on
{
    _fullscreen = on;
    UIApplication *app = [UIApplication sharedApplication];
    [app setStatusBarHidden:on withAnimation:UIStatusBarAnimationNone];
    // if (!self.presentingViewController) {
    //[self.navigationController setNavigationBarHidden:on animated:YES];
    //[self.tabBarController setTabBarHidden:on animated:YES];
    // }
}

- (void) setMoviePositionFromDecoder
{
    _moviePosition = _decoder.position;
}

- (void) setDecoderPosition: (CGFloat) position
{
    _decoder.position = position;
}

- (void) enableUpdateHUD
{
    _disableUpdateHUD = NO;
}


- (void)exec:(NSTimer*)timer {
//    if (queueblock!=nil) {
//        dispatch_async(_dispatchQueue, queueblock);
//        queueblock = nil;
//    }
    NSDictionary* tmpDictionary = timer.userInfo;
    NSLog(@"GOT EXEC........... %@",tmpDictionary);
    [self updatePosition:[[tmpDictionary objectForKey:@"POSITION"] floatValue] playMode:[[tmpDictionary objectForKey:@"PLAYMODE"] boolValue]];
    
    [queueTimer invalidate];
    queueTimer = nil;
}

- (void)changeBuffer:(NSTimer*)timer {
    [_decoder increaseMaxBufferDuration];
    [bufferChangeTimer invalidate];
    bufferChangeTimer = nil;
}

- (void) updatePosition: (CGFloat) position
               playMode: (BOOL) playMode
{
    [self freeBufferedFrames];
    
    position = MIN(_decoder.duration - 1, MAX(0, position));
    
    __weak KxMovieViewController *weakSelf = self;
    
    dispatch_async(_dispatchQueue, ^{
        if (playMode) {
                __strong KxMovieViewController *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
            
            dispatch_async(dispatch_get_main_queue(), ^{
        
                __strong KxMovieViewController *strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf play];
                }
            });
            
        } else {
                __strong KxMovieViewController *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
                [strongSelf decodeFrames];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong KxMovieViewController *strongSelf = weakSelf;
                if (strongSelf) {
                
                    [strongSelf enableUpdateHUD];
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf presentFrame];
                    [strongSelf updateHUD];
                }
            });
        }
        
    });
}

- (void) freeBufferedFrames
{
    @synchronized(_videoFrames) {
        [_videoFrames removeAllObjects];
    }
    
    @synchronized(_audioFrames) {
        
        [_audioFrames removeAllObjects];
        _currentAudioFrame = nil;
    }
    
    if (_subtitles) {
        @synchronized(_subtitles) {
            [_subtitles removeAllObjects];
        }
    }
    
    _bufferedDuration = 0;
    [self resetBufferProgress];
    [_decoder freeBuffered];
}

- (void) showInfoView: (BOOL) showInfo animated: (BOOL)animated
{
    if (!_tableView)
        [self createTableView];

    [self pause];
    
    CGSize size = self.view.bounds.size;
    CGFloat Y = _topHUD.bounds.size.height;
    
    if (showInfo) {
        
        _tableView.hidden = NO;
        
        if (animated) {
        
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 
                                 _tableView.frame = CGRectMake(0,Y,size.width,size.height - Y);
                             }
                             completion:nil];
        } else {
            
            _tableView.frame = CGRectMake(0,Y,size.width,size.height - Y);
        }
    
    } else {
        
        if (animated) {
            
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 
                                 _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
                                 
                             }
                             completion:^(BOOL f){
                                 
                                 if (f) {
                                     _tableView.hidden = YES;
                                 }
                             }];
        } else {
        
            _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
            _tableView.hidden = YES;
        }
    }
    
    _infoMode = showInfo;    
}

- (void) createTableView
{    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.hidden = YES;
    
    CGSize size = self.view.bounds.size;
    CGFloat Y = _topHUD.bounds.size.height;
    _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
    
    [self.view addSubview:_tableView];   
}

- (void) handleDecoderMovieError: (NSError *) error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_(@"Failure")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:_(@"ButtonTextOk")
                                              otherButtonTitles:nil];
    
    [alertView show];
    
//    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    appDelegate.sharedAlertView = alertView;
}

- (BOOL) interruptDecoder
{
    //if (!_decoder)
    //    return NO;
    return _interrupted;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return KxMovieInfoSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case KxMovieInfoSectionGeneral:
            return NSLocalizedString(@"General", nil);
        case KxMovieInfoSectionMetadata:
            return NSLocalizedString(@"Metadata", nil);
        case KxMovieInfoSectionVideo: {
            NSArray *a = _decoder.info[@"video"];
            return a.count ? NSLocalizedString(@"Video", nil) : nil;
        }
        case KxMovieInfoSectionAudio: {
            NSArray *a = _decoder.info[@"audio"];
            return a.count ?  NSLocalizedString(@"Audio", nil) : nil;
        }
        case KxMovieInfoSectionSubtitles: {
            NSArray *a = _decoder.info[@"subtitles"];
            return a.count ? NSLocalizedString(@"Subtitles", nil) : nil;
        }
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case KxMovieInfoSectionGeneral:
            return KxMovieInfoGeneralCount;
            
        case KxMovieInfoSectionMetadata: {
            NSDictionary *d = [_decoder.info valueForKey:@"metadata"];
            return d.count;
        }
            
        case KxMovieInfoSectionVideo: {
            NSArray *a = _decoder.info[@"video"];
            return a.count;
        }
            
        case KxMovieInfoSectionAudio: {
            NSArray *a = _decoder.info[@"audio"];
            return a.count;
        }
            
        case KxMovieInfoSectionSubtitles: {
            NSArray *a = _decoder.info[@"subtitles"];
            return a.count ? a.count + 1 : 0;
        }
            
        default:
            return 0;
    }
}

- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style
{
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == KxMovieInfoSectionGeneral) {
    
        if (indexPath.row == KxMovieInfoGeneralBitrate) {
            
            int bitrate = [_decoder.info[@"bitrate"] intValue];
            cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = NSLocalizedString(@"Bitrate", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d kb/s",bitrate / 1000];
            
        } else if (indexPath.row == KxMovieInfoGeneralFormat) {

            NSString *format = _decoder.info[@"format"];
            cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = NSLocalizedString(@"Format", nil);
            cell.detailTextLabel.text = format ? format : @"-";
        }
        
    } else if (indexPath.section == KxMovieInfoSectionMetadata) {
      
        NSDictionary *d = _decoder.info[@"metadata"];
        NSString *key = d.allKeys[indexPath.row];
        cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = key.capitalizedString;
        cell.detailTextLabel.text = [d valueForKey:key];
        
    } else if (indexPath.section == KxMovieInfoSectionVideo) {
        
        NSArray *a = _decoder.info[@"video"];
        cell = [self mkCell:@"VideoCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = a[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 2;
        
    } else if (indexPath.section == KxMovieInfoSectionAudio) {
        
        NSArray *a = _decoder.info[@"audio"];
        cell = [self mkCell:@"AudioCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = a[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 2;
        BOOL selected = _decoder.selectedAudioStream == indexPath.row;
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
    } else if (indexPath.section == KxMovieInfoSectionSubtitles) {
        
        NSArray *a = _decoder.info[@"subtitles"];
        
        cell = [self mkCell:@"SubtitleCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 1;
        
        if (indexPath.row) {
            cell.textLabel.text = a[indexPath.row - 1];
        } else {
            cell.textLabel.text = NSLocalizedString(@"Disable", nil);
        }
        
        const BOOL selected = _decoder.selectedSubtitleStream == (indexPath.row - 1);
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
     cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == KxMovieInfoSectionAudio) {
        
        NSInteger selected = _decoder.selectedAudioStream;
        
        if (selected != indexPath.row) {

            _decoder.selectedAudioStream = indexPath.row;
            NSInteger now = _decoder.selectedAudioStream;
            
            if (now == indexPath.row) {
            
                UITableViewCell *cell;
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                indexPath = [NSIndexPath indexPathForRow:selected inSection:KxMovieInfoSectionAudio];
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
    } else if (indexPath.section == KxMovieInfoSectionSubtitles) {
        
        NSInteger selected = _decoder.selectedSubtitleStream;
        
        if (selected != (indexPath.row - 1)) {
            
            _decoder.selectedSubtitleStream = indexPath.row - 1;
            NSInteger now = _decoder.selectedSubtitleStream;
            
            if (now == (indexPath.row - 1)) {
                
                UITableViewCell *cell;
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                indexPath = [NSIndexPath indexPathForRow:selected + 1 inSection:KxMovieInfoSectionSubtitles];
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            // clear subtitles
            _subtitlesLabel.text = nil;
            _subtitlesLabel.hidden = YES;
            @synchronized(_subtitles) {
                [_subtitles removeAllObjects];
            }
        }
    }
}

- (void)changeVideo: (NSArray *) videoArray :(int) videoPosition
{
    [self pause];
    
    [self freeBufferedFrames];
    if (_decoder) {
        [_decoder closeFile];
        [_decoder openFile:nil error:nil duration:0];
    }
//    _decoder = nil;
//    
//    _leftLabel.text =@"";
//    
//    _dispatchQueue = NULL;
    
    KxMovieViewController *videoViewController = [KxMovieViewController movieViewControllerWithContentPath:videoArray videoPosition:videoPosition];
    NSMutableArray* tempNavControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [tempNavControllers removeLastObject];
    [tempNavControllers addObject:videoViewController];
    [self.navigationController setViewControllers:tempNavControllers animated:NO];
}


-(void)updateProgressWithTotalBytesRead:(long long)_totalBytesRead TotalBytesExpectedToRead:(long long)_totalBytesExpectedToRead{
    
    if (_totalBytesExpectedToRead == 0) {
        //        [m_httpSender stopDownload];
        //        [m_downloadMask setHidden:YES];
        //        m_blnfileNotFound = YES;
        //        m_currentState = WAITTING;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *err;
        
        //        [fileManager removeItemAtPath:m_aviTmpPath error:&err];
        //            [self showFileNotExistMsg];
//        if (!videoViewController) {
//            [self performSelectorOnMainThread:@selector(showFileNotExistMsg) withObject:nil waitUntilDone:YES];
//        }
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
        
        frames = -1;
        if (frames < 0 && newProgress < 1) {
            frames = 0;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self checkFramesByPath:m_aviTmpPath];
            });
        }
        
        if (newProgress >= 1 || frames > 0){
            [self playVideo];
        }
    
        
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
    VideoFrameExtractor *m_framer = [[VideoFrameExtractor alloc] initWithVideoMemory:path];
    if (!m_framer) {
        NSLog(@"checkFramesByPath init failed");
        [NSThread sleepForTimeInterval:1.0f];
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
                [NSThread sleepForTimeInterval:1.0f];
                frames = -1;
            }
        }else{
            m_framer = nil;
            NSLog(@"checkFramesByPath got no frame");
            [NSThread sleepForTimeInterval:1.0f];
            frames = -1;
        }
    }else{
        m_framer = nil;
        NSLog(@"checkFramesByPath got no duration");
        [NSThread sleepForTimeInterval:1.0f];
        frames = -1;
    }
}

-(void)pauseAndRelease{
    /*
    [self pause];
    
    [self freeBufferedFrames];
    if (_decoder) {
        [_decoder closeFile];
//        [_decoder openFile:nil error:nil duration:0];
//        [_decoder closeFile];
    }
    _decoder = nil;
    
    _leftLabel.text =@"";
    
    _dispatchQueue = NULL;
    
    //[self dismissViewControllerAnimated:NO completion:nil];
    
     */
    if (self.playing) {
        
        [self pause];
        [self freeBufferedFrames];
        
//        if (_maxBufferedDuration > 0) {
//            
//            _minBufferedDuration = _maxBufferedDuration = 0;
//            [self play];
//            
//            LoggerStream(0, @"didReceiveMemoryWarning, disable buffering and continue playing");
//            
//        } else {
        
            // force ffmpeg to free allocated memory
//            [_decoder closeFile];
//            [_decoder openFile:nil error:nil duration:0];
//            _decoder = nil;
//            _dispatchQueue = NULL;
//            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
//                                        message:NSLocalizedString(@"Out of memory", nil)
//                                       delegate:nil
//                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
//                              otherButtonTitles:nil] show];
//        }
        
    } else {
        
        [self freeBufferedFrames];
//        [_decoder closeFile];
//        [_decoder openFile:nil error:nil duration:0];
//        _decoder = nil;
//        _dispatchQueue = NULL;
    }
    
}

-(BOOL)isHideHUD{
    return _hiddenHUD;
}

@end

