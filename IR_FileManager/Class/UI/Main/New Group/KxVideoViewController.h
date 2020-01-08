//
//  KxVideoViewController.h
//  EnShare
//
//  Created by Phil on 2015/6/15.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "StaticHttpRequest.h"
#import "BJRangeSliderWithProgress.h"

@protocol KxVideoDelegate <NSObject>

-(void)doneDidTouch;
-(void)forwardDidTouch;
-(void)rewindDidTouch;
-(BOOL)forwardAfterEndVideo;

@end

@protocol KxVideoCallBackDelegate <NSObject>
-(void)didVideoPlay:(NSString*)path;
@end

@interface KxVideoViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, BJRangeSliderWithProgressDelegate, KxVideoDelegate>{
    int64_t playingFileContextDuration;
}

+(id)kxVideoInitWithContentPathFromNet: (NSArray *) pathArray
                         videoPosition: (int)videoPosition;
+(id)kxVideoInitWithContentPathFromLocal: (NSArray *) pathArray
                           videoPosition: (int)videoPosition;

@property BOOL isSinglePlay;
@property (weak) id<KxVideoCallBackDelegate> delegate;

@end
