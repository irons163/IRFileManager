//
//  UploadingViewController.m
//  EnShare
//
//  Created by Phil on 2016/11/7.
//  Copyright © 2016年 Senao. All rights reserved.
//

#import "UploadingViewController.h"
#import "CollectionDataFile.h"

@interface UploadingViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

@end

@implementation UploadingViewController{
    bool isCanceled;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusLabel.text = NSLocalizedString(@"UPLOADING", nil);
    [self.cancelButton setTitle:_(@"Close") forState:UIControlStateNormal];
    
    if(_uploadItems==nil)
        [self dismissViewControllerAnimated:YES completion:nil];
    
    totalUploadItemsCount = _uploadItems.count;
    uploadedItemsCount = 0;
    _uploadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", uploadedItemsCount, totalUploadItemsCount];
    
    [self.progressView startAnimating];
    
    [self performSelectorInBackground:@selector(doUpload) withObject:nil];
#ifdef MESSHUDrive
    _bgImageView.image = [UIImage imageNamed:@"bg_gray"];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)doUpload{
    __block void (^failure)() = ^{
        [self.progressView stopAnimating];
        [self.progressView setHidden:YES];
        self.statusLabel.text = NSLocalizedString(@"FAIL", nil);
        if ([DataManager sharedInstance].needShow == 1) {
            self.infoLabel.text = NSLocalizedString(@"NO_Internet_Upload", nil);
        }
        if ([DataManager sharedInstance].needShow == 2) {
            self.infoLabel.text = NSLocalizedString(@"NO_Space", nil);
        }
        
        [DataManager sharedInstance].needShow = 0;
    };
    
    __block void (^success)() = ^{
        if(uploadedItemsCount < _uploadItems.count -1){
            if(isCanceled){
                return;
            }
            [self willDoNextUploadAfterSuccess];
            [[DataManager sharedInstance] doUpload:[self getUploadFilename:uploadedItemsCount] withSuccessBlock:success failureBlock:failure isFromAlbum:isFromAlbum];
        }else{
            [self allSuccess];
        }
    };
    
    [[DataManager sharedInstance] doUpload:[self getUploadFilename:uploadedItemsCount] withSuccessBlock:success failureBlock:failure isFromAlbum:isFromAlbum];
}

-(void)willDoNextUploadAfterSuccess{
    uploadedItemsCount++;
    dispatch_async(dispatch_get_main_queue(), ^{
        _uploadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", uploadedItemsCount, totalUploadItemsCount];
    });
}

-(void)allSuccess{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView stopAnimating];
        [self.progressView setHidden:YES];
        self.statusLabel.text = NSLocalizedString(@"SUCCESS", nil);
        _uploadStatusInfoLabel.text = [NSString stringWithFormat:@"%d/%d", uploadedItemsCount+1, totalUploadItemsCount];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

-(NSString*)getUploadFilename:(int)index{
    if([_uploadItems[index] isKindOfClass:CollectionDataFile.class]){
        CollectionDataFile* file = _uploadItems[index];
        return file.name;
    }else{
        return _uploadItems[index];
    }
    
}

- (IBAction)cancelUploadClick:(id)sender {
    isCanceled = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
    [[DataManager sharedInstance] stopUploadAndDoNext:NO];
}

-(void)setFromAlbum:(BOOL)isFromAlbum{
    self->isFromAlbum = isFromAlbum;
}

@end
