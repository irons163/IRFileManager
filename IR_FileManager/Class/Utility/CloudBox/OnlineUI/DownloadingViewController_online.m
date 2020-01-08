//
//  DownloadingViewController_online.m
//  EnShare
//
//  Created by Phil on 2016/12/5.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "DownloadingViewController_online.h"
#import "OnLineDataFile.h"
#import "CircleProgressView.h"
#import "UIColor+Helper.h"
#import "ColorDefine.h"
#import "Masonry.h"

@interface DownloadingViewController_online ()
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

@end

@implementation DownloadingViewController_online {
    BOOL saveToAlbum;
    int totalDownloadItemsCount;
    int downloadedItemsCount;
    CircleProgressView* circleProgress;
    NSTimer *timer;
    NSDate *startTime;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.statusLabel.text = NSLocalizedString(@"DOWNLOADING", nil);
    [self.cancelButton setTitle:_(@"Close") forState:UIControlStateNormal];
    
    if(_downloadItems==nil)
        [self dismissViewControllerAnimated:YES completion:nil];
    
    totalDownloadItemsCount = _downloadItems.count;
    downloadedItemsCount = 0;
    _downloadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", downloadedItemsCount, totalDownloadItemsCount];
    
//    [self.progressView startAnimating];
    [self.progressView removeFromSuperview];//use circle progress.
    
    [self performSelectorInBackground:@selector(doDownload) withObject:nil];
    
    //    [self performSelectorInBackground:@selector(doUpload:) withObject:^{
    ////        file = _uploadItems[uploadedItemsCount];
    ////        _uploadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", uploadedItemsCount, totalUploadItemsCount];
    ////        [DataManager sharedInstance] doUpload:file.name withSuccessBlock: failureBlock:nil isFromAlbum:NO;
    //    }];
#ifdef MESSHUDrive
    _bgImageView.image = [UIImage imageNamed:@"bg_gray"];
#endif
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self showProgress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

-(void)doDownload{
    __block OnLineDataFile* file = _downloadItems[downloadedItemsCount];
    //    _uploadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", uploadedItemsCount, totalUploadItemsCount];
    //
    __block void (^failure)() = ^{
        [self.progressView stopAnimating];
        [self.progressView setHidden:YES];
        self.statusLabel.text = NSLocalizedString(@"FAIL", nil);
//        if ([DataManager sharedInstance].needShow == 1) {
//            self.infoLabel.text = NSLocalizedString(@"NO_Internet_Upload", nil);
//        }
//        if ([DataManager sharedInstance].needShow == 2) {
//            self.infoLabel.text = NSLocalizedString(@"NO_Space", nil);
//        }
        
//        [DataManager sharedInstance].needShow = 0;
    };
    
    __block void (^success)() = ^{
        if(downloadedItemsCount < _downloadItems.count -1){
            [DataManager sharedInstance].progressFloat = 0;
            downloadedItemsCount++;
            file = _downloadItems[downloadedItemsCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                _downloadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", downloadedItemsCount, totalDownloadItemsCount];
            });
            [self doDownload:file.filePath withSuccessBlock:success failureBlock:failure saveToAlbum:saveToAlbum type:file.type];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [circleProgress update:100];
                [self stopProgress];
                [self.progressView stopAnimating];
                [self.progressView setHidden:YES];
                self.statusLabel.text = NSLocalizedString(@"SUCCESS", nil);
                _downloadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", downloadedItemsCount+1, totalDownloadItemsCount];
                [self.delegate downloadSuccessCallback];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                });
            });
        }
    };
    
    
    [self doDownload:file.filePath withSuccessBlock:success failureBlock:failure saveToAlbum:saveToAlbum type:file.type];
    
    
}

- (void)doDownload:(NSString*)fullfilename
  withSuccessBlock:(void (^)())success
      failureBlock:(void (^)())failure
       saveToAlbum:(BOOL)saveToAlbum
              type:(NSString*)type{

    NSString *uid = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT uid FROM Collection WHERE type = '%@' AND filename = '%@'; ", [[DataManager sharedInstance] getType:[fullfilename pathExtension]], [fullfilename lastPathComponent]]];
    if (uid.length == 0) {
        [[DataManager sharedInstance] doDownload:fullfilename filename:[fullfilename lastPathComponent] withSuccessBlock:success failureBlock:failure saveToAlbum:saveToAlbum type:type];
    }else{
        NSString *ext = [NSString stringWithFormat:@".%@",[fullfilename pathExtension]];
        NSString *fileName = [[fullfilename lastPathComponent] stringByDeletingPathExtension];
        NSString *folder = [fullfilename stringByReplacingOccurrencesOfString:fileName withString:@""];
        folder = [folder stringByReplacingOccurrencesOfString:ext withString:@""];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSDate *date = [NSDate date];
        [formatter setDateFormat:@"YYYYMMddhhmmss'"];
        NSString *today = [formatter stringFromDate:date];
        
        fileName = [NSString stringWithFormat:@"%@%@_%@.%@", folder, fileName, today, [fullfilename pathExtension]];
        LogMessage(nil, 0, @"%@", fileName);
        
        [[DataManager sharedInstance] doDownload:fullfilename filename:[fileName lastPathComponent] withSuccessBlock:success failureBlock:failure saveToAlbum:saveToAlbum type:type];
    }
}

//- (void)showWarnning:(NSString*)info{
//    [DataManager sharedInstance].needShow = 0;
//    SuccessView *successView;;
//    VIEW(successView, SuccessView);
//    successView.infoLabel.text = NSLocalizedString(info, nil);
//    [[KGModal sharedInstance] setShowCloseButton:FALSE];
//    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
//}

- (IBAction)cancelDownloadClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[DataManager sharedInstance] stopDownloadAndDoNext:NO];
    [self.delegate downloadCancelClickedCallback];
}

-(void)setSaveToAlbum:(BOOL)saveToAlbum{
    self->saveToAlbum = saveToAlbum;
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
    [timer invalidate];
    timer = nil;
}


#pragma mark - Timer

- (void)startTimer {
    if ((!timer) || (![timer isValid])) {
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1f
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
    float p = downloadedItemsCount/(float)totalDownloadItemsCount;
    float percent = ([DataManager sharedInstance].progressFloat/totalDownloadItemsCount + p) *100;
    
//    NSLog(@"%f",percent);
    if (percent > 100.f) {
        return 100;
    }
    return (int)percent;
}

@end
