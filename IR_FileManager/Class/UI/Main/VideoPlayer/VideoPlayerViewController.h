//
//  VideoPlayerViewController.h
//  IR_FileManager
//
//  Created by Phil on 2020/1/15.
//  Copyright © 2020 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJRangeSliderWithProgress/BJRangeSliderWithProgress.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IRVideoDelegate <NSObject>

-(void)doneDidTouch;
-(void)forwardDidTouch;
-(void)rewindDidTouch;
-(BOOL)forwardAfterEndVideo;

@end

@protocol IRVideoCallBackDelegate <NSObject>
-(void)didVideoPlay:(NSString*)path;
@end

@interface VideoPlayerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, BJRangeSliderWithProgressDelegate, IRVideoDelegate>{
    int64_t playingFileContextDuration;
}

+ (id)movieViewControllerWithContentPath:(NSArray *) pathArray videoPosition:(int)videoPosition;

@property BOOL isSinglePlay;
@property (weak) id<IRVideoCallBackDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
