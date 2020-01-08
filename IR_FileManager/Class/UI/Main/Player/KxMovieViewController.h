//
//  ViewController.h
//  kxmovieapp
//
//  Created by Kolyvan on 11.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import <UIKit/UIKit.h>
#import "BJRangeSliderWithProgress.h"
//#import "StaticHttpRequest.h"
#import "KxVideoViewController.h"

@class KxMovieDecoder;

extern NSString * const KxMovieParameterMinBufferedDuration;    // Float
extern NSString * const KxMovieParameterMaxBufferedDuration;    // Float
extern NSString * const KxMovieParameterDisableDeinterlacing;   // BOOL
extern NSString * const KxMovieParameterMidBufferedDuration;    // Float

@interface KxMovieViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, BJRangeSliderWithProgressDelegate>{
    int64_t playingFileContextDuration;
}

+ (id) movieViewControllerWithContentPath: (NSArray *) pathArray
                            videoPosition: (int)videoPosition;

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                 duration: (int64_t) contextDuration
                              isSliderMax: (bool) isSliderMax;

@property (readonly) BOOL playing;

- (void) play;
- (void) pause;
- (void) playDidTouch: (id) sender;

-(void)updateDownloadProgress:(CGFloat)value;

-(void)pauseAndRelease;

-(BOOL)isHideHUD;

@property (nonatomic, weak) id<KxVideoDelegate> delegate;

@property BOOL isSinglePlay;

@end
