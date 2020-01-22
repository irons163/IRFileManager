//
//  VideoPlayerViewController.m
//  IR_FileManager
//
//  Created by Phil on 2020/1/15.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import <IRPlayer/IRPlayer.h>
#import "UIColor+Helper.h"
#import "Masonry.h"
#import "IRLanguageManager.h"

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#include "libavformat/avformat.h"

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

@interface VideoPlayerViewController () {
    NSTimer *queueTimer;
    NSTimer *bufferChangeTimer;
    dispatch_once_t __onceToken;

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
    NSString *_path;
}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;
@property (readwrite, strong) IRFFArtworkFrame *artworkFrame;
@property (nonatomic, strong) IRPlayerImp * player;
@property (nonatomic, assign) BOOL progressSilderTouching;
@end

@implementation VideoPlayerViewController

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
    return [[VideoPlayerViewController alloc] initWithContentPath: pathArray videoPosition: videoPosition];
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
        
        _path = path;
        
//        _weakSelf = weakSelf;
        
    }
    return self;
}

//NSString * _path;
//KxMovieDecoder * _decoder;
//__weak KxMovieViewController * _weakSelf;

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                 duration: (int64_t)contextDuration
                                 isSliderMax: (bool)isSliderMax
{
    return [[VideoPlayerViewController alloc] initWithContentPath: path parameters: parameters duration:contextDuration isSliderMax:isSliderMax];
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
    
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    self.player = [IRPlayerImp player];
    [self.player registerPlayerNotificationTarget:self
                                      stateAction:@selector(stateAction:)
                                   progressAction:@selector(progressAction:)
                                   playableAction:@selector(playableAction:)
                                      errorAction:@selector(errorAction:)];
    [self.player setViewTapAction:^(IRPlayerImp * _Nonnull player, IRPLFView * _Nonnull view) {
        NSLog(@"player display view did click!");
    }];
    [self.view insertSubview:self.player.view atIndex:0];
    
    self.player.decoder = [IRPlayerDecoder FFmpegDecoder];
    [self.player replaceVideoWithURL:[NSURL URLWithString:_path]];
    
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

    if (_player) {
        
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
//            [_decoder receiveMemoryWarning];
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
        
//        [_decoder receiveMemoryWarning];
        
        return;
    }
    
    NSLog(@"didReceiveMemoryWarning kxMovie");
    
    if (self.playing) {
        
        [self pause];
//        [self freeBufferedFrames];
        
        if (_maxBufferedDuration > 0) {
            
            _minBufferedDuration = _maxBufferedDuration = 0;
            [self play];
        } else {
            
            // force ffmpeg to free allocated memory
//            [_decoder closeFile];
//            [_decoder openFile:nil error:nil duration:0];
            
            [[[UIAlertView alloc] initWithTitle:_(@"FAILURE")
                                        message:_(@"OUT_OF_MEMORY")
                                       delegate:nil
                              cancelButtonTitle:_(@"ButtonTextOk")
                              otherButtonTitles:nil] show];
        }
        
    } else {
        
//        [self freeBufferedFrames];
//        [_decoder closeFile];
//        [_decoder openFile:nil error:nil duration:0];
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
    
    if (_player) {
        
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

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [_activityIndicatorView stopAnimating];
    
    if (_player) {
          
        [self pause];
    }
    
    if (_fullscreen)
        [self fullscreenMode:NO];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_savedIdleTimer];
    
    [_activityIndicatorView stopAnimating];
    _buffered = NO;
    _interrupted = YES;
    
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
    
//    if (!_player.decoder.videoEnable &&
//        !_decoder.validAudio) {
//
//        return;
//    }
    
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

    [self.player play];
    
    [self updatePlayButton];
    
    NSLog(@"play movie");
}

- (void)pause {
    if (!self.playing)
        return;

    self.playing = NO;
//    _interrupted = YES;
    [self.player pause];
    
    [self updatePlayButton];
    NSLog(@"pause movie");
}

- (void)updateDownloadProgress:(CGFloat)value {
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (_progressSlider) {
            _progressSlider.rightValue = value;
        }
    //});
}

- (void)resetBufferProgress {
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
    if(!_isSliderMax)//Local
        return;
    if (_progressSlider) {
        _progressSlider.rightValue = _progressSlider.leftValue;
    }
    //});
}

- (void)updateBufferProgressTo:(double)value {
    //dispatch_async(dispatch_get_main_queue(), ^(void) {
    if(!_isSliderMax)//Local
        return;
    if (_progressSlider) {
        if(_progressSlider.rightValue < value)
            _progressSlider.rightValue = value;
    }
    //});
}

- (void)setMoviePosition:(CGFloat)position {
   __block BOOL playMode = self.playing;
    
    self.playing = NO;
    _disableUpdateHUD = YES;
    
//    [self freeBufferedFrames];
    

    [_player seekToTime:_player.duration * position];
}

#pragma mark - actions

- (void)doneDidTouch:(id)sender {
    _hiddenHUD = NO;
    [self pauseAndRelease];
    
    if (self.presentingViewController || !self.navigationController){
        
        
        [self dismissViewControllerAnimated:NO completion:^{
            
        }];
        
    }else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)infoDidTouch:(id)sender {
    [self showInfoView: !_infoMode animated:YES];
}

- (void)playDidTouch:(id)sender {
    if (self.playing)
        [self pause];
    else
        [self play];
}

- (void)forwardAfterEndVideo {
//    if(![self.delegate forwardAfterEndVideo]){
//        [self doneDidTouch:nil];
//    };
    [self rewindDidTouch:nil];
}

- (void)forwardDidTouch:(id)sender {
////    self.view.userInteractionEnabled = NO;
//    [self.delegate forwardDidTouch];
    _videoPosition++;
    
    if (_videoPosition >= [_pathArray count]) {
        _videoPosition = 0;
    }
    
    [_player replaceVideoWithURL:[NSURL URLWithString:[_pathArray objectAtIndex:_videoPosition]]];
}

- (void)rewindDidTouch:(id)sender {
//    if(self.view.userInteractionEnabled==NO)
//        return;
//    self.view.userInteractionEnabled = NO;
    //    [self setMoviePosition: _moviePosition - 10];
    //[self setMoviePosition: _moviePosition - 10];
    if (_videoPosition <= 0) {
        _videoPosition = [_pathArray count];
    }
    _videoPosition--;
    
    [_player replaceVideoWithURL:[NSURL URLWithString:[_pathArray objectAtIndex:_videoPosition]]];
}

#pragma mark BJRangeSliderWithProgressDelegate
- (void)progressDidChange:(CGFloat)value {
    [self setMoviePosition:value];
}

#pragma mark - private

- (void)setMoviewithError:(NSError *)error {
    NSLog(@"setMovieDecoder");
            
    if (!error && _player) {
        _dispatchQueue  = dispatch_queue_create("KxMovie", DISPATCH_QUEUE_SERIAL);
        _videoFrames    = [NSMutableArray array];
        _audioFrames    = [NSMutableArray array];
        
        _subtitles = [NSMutableArray array];
    
//        if (_decoder.isNetwork) {
//            _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
//            _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
//        } else {
            _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
//        }
        
        if (!_player.videoEnable)
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
//                _decoder.disableDeinterlacing = [val boolValue];
            }
            
            val = [_parameters valueForKey: KxMovieParameterMidBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]]){
                _midBufferedDuration = [val floatValue];
            }
            
            if (_maxBufferedDuration < _minBufferedDuration)
                _maxBufferedDuration = _minBufferedDuration * 2;
        }
        
        NSLog(@"buffered limit: %.1f - %.1f", _minBufferedDuration, _maxBufferedDuration);
        
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

- (void)restorePlay {
    NSNumber *n = [gHistory valueForKey:_path];
    if (n)
        [self setMoviePosition:n.floatValue];
    else
        [self play];
}

- (void)setupPresentView {
    CGRect bounds = self.view.bounds;
    
    if (!_player.view) {
        
        NSLog(@"fallback to use RGB video frame and UIKit");
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
    
    if (_player) {
    
        [self setupUserInteraction];
    
    } else {
       
        _imageView.image = [UIImage imageNamed:@"kxmovie.bundle/music_icon.png"];
        _imageView.contentMode = UIViewContentModeCenter;
    }
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if (_player.duration == MAXFLOAT) {
        
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
    
//    if (_decoder.subtitleStreamsCount) {
//
//        CGSize size = self.view.bounds.size;
//
//        _subtitlesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, size.height, size.width, 0)];
//        _subtitlesLabel.numberOfLines = 0;
//        _subtitlesLabel.backgroundColor = [UIColor clearColor];
//        _subtitlesLabel.opaque = NO;
//        _subtitlesLabel.adjustsFontSizeToFitWidth = NO;
//        _subtitlesLabel.textAlignment = NSTextAlignmentCenter;
//        _subtitlesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        _subtitlesLabel.textColor = [UIColor whiteColor];
//        _subtitlesLabel.font = [UIFont systemFontOfSize:16];
//        _subtitlesLabel.hidden = YES;
//
//        [self.view addSubview:_subtitlesLabel];
//    }
}

- (void)setupUserInteraction {
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

- (UIView *)frameView {
    return _player.view ? _player.view : _imageView;
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
    
    const CGFloat duration = _player.duration;
    const CGFloat position = _moviePosition;
    
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
    
    if (_player.duration != MAXFLOAT)
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
    _moviePosition = _player.progress;
}

- (void) enableUpdateHUD
{
    _disableUpdateHUD = NO;
}


- (void)changeBuffer:(NSTimer*)timer {
//    [_decoder increaseMaxBufferDuration];
    [bufferChangeTimer invalidate];
    bufferChangeTimer = nil;
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


-(void)pauseAndRelease{
    if (self.playing) {
        [self pause];
    }
}

-(BOOL)isHideHUD{
    return _hiddenHUD;
}

#pragma mark - IRPlayer Actions

- (void)stateAction:(NSNotification *)notification
{
    IRState * state = [IRState stateFromUserInfo:notification.userInfo];
    
    NSString * text;
    switch (state.current) {
        case IRPlayerStateNone:
            text = @"None";
            break;
        case IRPlayerStateBuffering:
            text = @"Buffering...";
            break;
        case IRPlayerStateReadyToPlay:
            text = @"Prepare";
            _progressLabel.text = [self timeStringFromSeconds:self.player.duration];
            [self play];
            break;
        case IRPlayerStatePlaying:
            text = @"Playing";
            break;
        case IRPlayerStateSuspend:
            text = @"Suspend";
            break;
        case IRPlayerStateFinished:
            text = @"Finished";
            [self pause];
            break;
        case IRPlayerStateFailed:
            text = @"Error";
            break;
    }
    _messageLabel.text = text;
}

- (void)progressAction:(NSNotification *)notification
{
    IRProgress * progress = [IRProgress progressFromUserInfo:notification.userInfo];
    if (!self.progressSilderTouching) {
        _progressSlider.leftValue = progress.percent;
    }
    _leftLabel.text = [self timeStringFromSeconds:progress.current];
}

- (void)playableAction:(NSNotification *)notification
{
    IRPlayable * playable = [IRPlayable playableFromUserInfo:notification.userInfo];
    NSLog(@"playable time : %f", playable.current);
}

- (void)errorAction:(NSNotification *)notification
{
    IRError * error = [IRError errorFromUserInfo:notification.userInfo];
    NSLog(@"player did error : %@", error.error);
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end

