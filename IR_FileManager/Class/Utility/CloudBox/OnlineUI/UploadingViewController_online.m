//
//  UploadingViewController_online.m
//  EnShare
//
//  Created by Phil on 2016/12/5.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "UploadingViewController_online.h"
#import "CircleProgressView.h"
#import "UIColor+Helper.h"
#import "EnShareTools.h"
#import "ColorDefine.h"
#import "Masonry.h"

@interface UploadingViewController_online ()

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;



@end

@implementation UploadingViewController_online{
    CircleProgressView* circleProgress;
    NSTimer *timer;
    NSDate *startTime;
    long totalFilesSize;
    long finishedFilesSize;
    NSMutableArray* filesSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.statusLabel.text = NSLocalizedString(@"UPLOADING", nil);
    
    filesSize = [NSMutableArray array];
    NSString *fileFolder;
    if(isFromAlbum)
        fileFolder = NSTemporaryDirectory();
    else
        fileFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    for(NSString* fileName in self.uploadItems){
        NSString *filePath = [fileFolder stringByAppendingPathComponent:fileName];
        NSNumber *size = [EnShareTools getFileSize:filePath];
        [filesSize addObject:size];
        totalFilesSize += [size longValue];
    }
    
    [self.progressView removeFromSuperview];//use circle progress.
#ifdef MESSHUDrive
    _bgImageView.image = [UIImage imageNamed:@"bg_gray"];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self showProgress];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self stopProgress];
}

-(void)willDoNextUploadAfterSuccess{
    [DataManager sharedInstance].progressFloat = 0;
    finishedFilesSize += [((NSNumber*)filesSize[uploadedItemsCount]) longValue];
    [super willDoNextUploadAfterSuccess];
}

-(void)allSuccess{
    [circleProgress update:100];
    [self stopProgress];
    [super allSuccess];
    self.uploadSuccessCallback();
}

#pragma mark - Progress
-(void)showProgress{
    //    AppDelegate* appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    //    appdelegate.isUpgrading = YES;
    //    self.upgradeButton.userInteractionEnabled = NO;
    
    if (!circleProgress) {
        circleProgress = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, 130, 130)];
#ifdef MESSHUDrive
        circleProgress.circleColor = [UIColor colorWithColorCodeString:SwapTextColor];
        circleProgress.numberColor = [UIColor colorWithColorCodeString:TextColor];
#else
        circleProgress.circleColor = [UIColor whiteColor];
        circleProgress.numberColor = [UIColor colorWithColorCodeString:@"ff00b4f5"];
#endif
        [self.view addSubview:circleProgress];
        [circleProgress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.statusLabel.mas_top).offset(-20);
            make.centerX.equalTo(self.view);
            make.size.mas_equalTo(130);
        }];
    }
    
    [circleProgress update:0];
    
    startTime = [NSDate date];
    
    self.progressView.hidden = NO;
    
    [self startTimer];
}

-(void)stopProgress{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
}


#pragma mark - Timer

- (void)startTimer {
    if ((!timer) || (![timer isValid])) {
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.2f
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
    if (timer && percent >= 100) {
        [self stopProgress];
    }
}

-(int)getCurrentPercent{
    double finishedPersent = finishedFilesSize/(double)totalFilesSize;
    double currentUploadPersent = [((NSNumber*)filesSize[uploadedItemsCount]) longValue]/(double)totalFilesSize;
    float percent = ([DataManager sharedInstance].progressFloat*currentUploadPersent + finishedPersent) *100;
    
        NSLog(@"Uploading percent:%f",percent);
    if (percent > 100.f) {
        return 100;
    }
    return (int)percent;
}


//-(int)getCurrentPercent{
//    
//    if (self.timeToNotification > 0) {
//        if (fabs((float)[startTime timeIntervalSinceNow]) >= self.timeToNotification) {
//            if (self.delegate && [self.delegate respondsToSelector:@selector(timeUpNotification)]) {
//                dispatch_once(&onceToken, ^{
//                    [self.delegate timeUpNotification];
//                    self.timeToNotification = 0;
//                });
//            }
//        }
//    }
//    
//    float percent = (fabs((float)[startTime timeIntervalSinceNow])/self.timeLimit)*100;
//    //    NSLog(@"%f",percent);
//    if (percent > 100.f) {
//        return 100;
//    }
//    return (int)percent;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
