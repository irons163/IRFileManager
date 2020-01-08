//
//  PhotoViewController.m
//  EnShare
//
//  Created by ke on 2013/11/7.
//  Copyright (c) 2013年 Senao. All rights reserved.
//

#import "PhotoViewController.h"
#ifdef smalink
#import "UIColor+Helper.h"
#endif

@interface PhotoViewController (){
    ALAssetsLibrary *assetsLibrary;
    NSMutableArray *tableArray;
    BOOL backTag;//判斷是否為back
    int selectNum;
}

@end

@implementation PhotoViewController

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
#ifdef smalink
    self.infoView.backgroundColor = [UIColor colorWithRGB:0x3e92cc];
    self.selectNumLbl.textColor = [UIColor colorWithRGB:0xffffff];
    self.selectedLbl.textColor = [UIColor colorWithRGB:0xffffff];
#endif
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        self.mainView.frame = CGRectMake(0, 20, self.mainView.frame.size.width, self.mainView.frame.size.height-20);
    } else {// iOS 6
    }
    [UIView setAnimationsEnabled:YES];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    tableArray = [[NSMutableArray alloc]init];
    assetsLibrary = [PhotoViewController defaultAssetsLibrary];
    
    self.doneBtn.enabled = NO;
    selectNum = 0;
}

- (void)viewWillAppear:(BOOL)animated{
    
    //self.loadingLbl.hidden = YES;
    [self.view setUserInteractionEnabled:NO];
    
    [tableArray removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
    //從相簿中取得分類
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            //NSLog(@"名稱: %@, 數目: %d ",[group valueForProperty:ALAssetsGroupPropertyName], [group numberOfAssets]);
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:_(@"CAMERA_ROLL")] || [[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Saved Photos"]) {
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                    if (asset != nil) {
                        
                        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
                        
                        NSMutableDictionary *tDict = [[NSMutableDictionary alloc]init];
                        
                        [tDict setObject:assetRep forKey:@"ASSETREP"];
                        CGImageRef thumbnail = asset.thumbnail;
                        if(thumbnail)
                            [tDict setObject:[UIImage imageWithCGImage:thumbnail] forKey:@"THUMBNAIL"];
                        else{
                            thumbnail = asset.aspectRatioThumbnail;
                            [tDict setObject:[UIImage imageWithCGImage:thumbnail] forKey:@"THUMBNAIL"];
                        }
                            
                        [tDict setObject:[asset valueForProperty:@"ALAssetPropertyAssetURL"] forKey:@"URL"];
                        
                        int seconds = [[asset valueForProperty:@"ALAssetPropertyDuration"] integerValue];
                        int min = seconds/60;
                        int sec = seconds%60;
                        [tDict setObject:[NSString stringWithFormat:@"%d:%d", min, sec] forKey:@"DURATION"];
                        
                        [tDict setObject:@"NO" forKey:@"SELECT"];
                        
                        [tableArray addObject:tDict];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.collectionView reloadData];
                        });
                    } else {
                        //列舉完成時的處理常式
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.collectionView reloadData];
                            self.loadingView.hidden = YES;
                            [self.view setUserInteractionEnabled:YES];
                        });
                    }
                }];
                
            }
            
        } else {
            //列舉完成時的處理常式
        }
    }failureBlock:^(NSError *error) {
        //失敗處理常式
        //LogMessage(nil, 0, @"%@", error);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.permissionView.hidden = NO;
            self.loadingView.hidden = YES;
            [self.view setUserInteractionEnabled:YES];
        });
    }];
    
    });
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)dealloc{
    self.mainView = nil;
    self.loadingLbl = nil;
    self.loadingView = nil;
    self.selectAllBtn = nil;
    self.doneBtn = nil;
    self.collectionView = nil;
    self.delegate = nil;
}

#pragma mark - 取得ALAssetsLibrary
+ (ALAssetsLibrary *)defaultAssetsLibrary{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once (&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

#pragma mark - delegate
- (void)doDelegate{
    if (!backTag) {
        
        NSMutableArray *photoArray = [[NSMutableArray alloc] init];
//        NSMutableArray *videoArray = [[NSMutableArray alloc] init];
        
        for (NSDictionary *tDict in tableArray) {
            if ([[tDict objectForKey:@"SELECT"] isEqualToString:@"YES"]) {
                
                NSString *url = [[[tDict objectForKey:@"URL"] absoluteString] lowercaseString];
                if ([url rangeOfString:@"ext=jpg"].length>0 || [url rangeOfString:@"ext=png"].length>0) {
                    [photoArray addObject:[tDict objectForKey:@"ASSETREP"]];
                    
                }
//                else if ([url rangeOfString:@"ext=mov"].length>0 || [url rangeOfString:@"ext=mp4"].length>0) {
//                    [videoArray addObject:[tDict objectForKey:@"ASSETREP"]];
//                }
            }
        }
        
        [self.delegate getAlbumPhotoAssets:photoArray];
//        [self.delegate getAlbumVideoAssets:videoArray];
    }
}

#pragma mark - 按鈕事件
- (IBAction)backClk:(id)sender {
    backTag = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneClk:(id)sender {
    backTag = NO;
    [self performSelectorInBackground:@selector(updateUI) withObject:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectAllClk:(id)sender {
    selectNum = 0;
    self.selectAllBtn.selected = !self.selectAllBtn.selected;
    if (self.selectAllBtn.selected) {//選擇全部
        [self.selectAllBtn setImage:[UIImage imageNamed:@"btn_selectnon"] forState:UIControlStateNormal];
        [self.selectAllBtn setImage:[UIImage imageNamed:@"ibtn_selectnon"] forState:UIControlStateHighlighted];
        for (int i = 0; i<[tableArray count]; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            //[self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            NSMutableDictionary *tDict = [tableArray objectAtIndex:indexPath.row];
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
            imageView.image = [UIImage imageNamed:@"photo_overlay"];
            [cell addSubview:imageView];
            [tDict setObject:@"YES" forKey:@"SELECT"];
            selectNum++;
        }
        self.doneBtn.enabled = YES;
    }else{//取消全部
        [self.selectAllBtn setImage:[UIImage imageNamed:@"btn_selectall"] forState:UIControlStateNormal];
        [self.selectAllBtn setImage:[UIImage imageNamed:@"ibtn_selectall"] forState:UIControlStateHighlighted];
        for (int i = 0; i<[tableArray count]; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            //[self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            NSMutableDictionary *tDict = [tableArray objectAtIndex:[tableArray count]-1-indexPath.row];
            
            NSArray *viewsToRemove = [cell subviews];
            for (UIView *v in viewsToRemove) {
                [v removeFromSuperview];
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
            imageView.image = [tDict objectForKey:@"THUMBNAIL"];
            cell.backgroundView = imageView;
            
            NSString *url = [[[tDict objectForKey:@"URL"] absoluteString] lowercaseString];
            if ([url rangeOfString:@"ext=mov"].length>0 || [url rangeOfString:@"ext=mp4"].length>0) {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 55, 24, 16)];
                imageView.image = [UIImage imageNamed:@"ic_action_video"];
                [cell addSubview:imageView];
                
                UILabel *timeLbl = [[UILabel alloc]initWithFrame:CGRectMake(32, 58, 35, 10)];
                timeLbl.font=[timeLbl.font fontWithSize:13];
                timeLbl.textColor = [UIColor whiteColor];
                timeLbl.textAlignment = NSTextAlignmentRight;
                timeLbl.text = [tDict objectForKey:@"DURATION"];
                [cell addSubview:timeLbl];
            }
            
            [tDict setObject:@"NO" forKey:@"SELECT"];
            selectNum++;
        }
        self.doneBtn.enabled = NO;
    }
    
    self.selectNumLbl.text = [NSString stringWithFormat:@"%d", selectNum];
    
    START_ANIM(2);
    if (self.doneBtn.enabled) {
        self.infoView.frame = CGRectMake(0, 44, self.infoView.frame.size.width, self.infoView.frame.size.height);
    }else{
        selectNum = 0;
        self.selectNumLbl.text = [NSString stringWithFormat:@"%d", selectNum];
        self.infoView.frame = CGRectMake(0, 26, self.infoView.frame.size.width, self.infoView.frame.size.height);
    }
    END_ANIM();
}

- (void)updateUI{
    //self.loadingLbl.hidden = NO;
    self.loadingView.hidden = NO;
}

#pragma mark - UICollectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [tableArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    NSArray *viewsToRemove = [cell subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    
    NSMutableDictionary *tDict = [tableArray objectAtIndex:([tableArray count]-1-indexPath.row)];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
    imageView.image = [tDict objectForKey:@"THUMBNAIL"];
    cell.backgroundView = imageView;
    
    NSString *url = [[[tDict objectForKey:@"URL"] absoluteString] lowercaseString];
    if ([url rangeOfString:@"ext=mov"].length>0 || [url rangeOfString:@"ext=mp4"].length>0) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 55, 24, 16)];
        imageView.image = [UIImage imageNamed:@"ic_action_video"];
        [cell addSubview:imageView];
        
        UILabel *timeLbl = [[UILabel alloc]initWithFrame:CGRectMake(32, 58, 35, 10)];
        timeLbl.font=[timeLbl.font fontWithSize:13];
        timeLbl.textColor = [UIColor whiteColor];
        timeLbl.textAlignment = NSTextAlignmentRight;
        timeLbl.text = [tDict objectForKey:@"DURATION"];
        [cell addSubview:timeLbl];
    }
    
    if (self.selectAllBtn.selected || [[tDict objectForKey:@"SELECT"] isEqualToString:@"YES"]) {
        UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
        imageView2.image = [UIImage imageNamed:@"photo_overlay"];
        [cell addSubview:imageView2];
        cell.selected = YES;
    }
    
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    NSMutableDictionary *tDict = [tableArray objectAtIndex:([tableArray count]-1-indexPath.row)];
    
    if ([[tDict objectForKey:@"SELECT"] isEqualToString:@"NO"]) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
        imageView.image = [UIImage imageNamed:@"photo_overlay"];
        [cell addSubview:imageView];
        
        [tDict setObject:@"YES" forKey:@"SELECT"];
        selectNum++;
    }else{
        NSArray *viewsToRemove = [cell subviews];
        for (UIView *v in viewsToRemove) {
            [v removeFromSuperview];
        }
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
        imageView.image = [tDict objectForKey:@"THUMBNAIL"];
        cell.backgroundView = imageView;
        
        NSString *url = [[[tDict objectForKey:@"URL"] absoluteString] lowercaseString];
        if ([url rangeOfString:@"ext=mov"].length>0 || [url rangeOfString:@"ext=mp4"].length>0) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 55, 24, 16)];
            imageView.image = [UIImage imageNamed:@"ic_action_video"];
            [cell addSubview:imageView];
            
            UILabel *timeLbl = [[UILabel alloc]initWithFrame:CGRectMake(32, 58, 35, 10)];
            timeLbl.font=[timeLbl.font fontWithSize:13];
            timeLbl.textColor = [UIColor whiteColor];
            timeLbl.textAlignment = NSTextAlignmentRight;
            timeLbl.text = [tDict objectForKey:@"DURATION"];
            [cell addSubview:timeLbl];
        }
        
        [tDict setObject:@"NO" forKey:@"SELECT"];
        selectNum--;
    }
    
    
    for (NSDictionary *tDict in tableArray) {
        if ([[tDict objectForKey:@"SELECT"] isEqualToString:@"NO"]) {
            self.doneBtn.enabled = NO;
        }else{
            self.doneBtn.enabled = YES;
            break;
        }
    }
    

    self.selectNumLbl.text = [NSString stringWithFormat:@"%d", selectNum];
    
    START_ANIM(2);
    if (self.doneBtn.enabled) {
        self.infoView.frame = CGRectMake(0, 44, self.infoView.frame.size.width, self.infoView.frame.size.height);
    }else{
        self.infoView.frame = CGRectMake(0, 26, self.infoView.frame.size.width, self.infoView.frame.size.height);
    }
    END_ANIM();
    
}

@end
