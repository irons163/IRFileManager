//
//  PhotoCollectionViewModel.m
//  IR_FileManager
//
//  Created by Phil on 2020/1/30.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "PhotoCollectionViewModel.h"
#import "PhotoCollectionReusableView.h"
#import "PhotoCollectionViewCell.h"
#import "PhotoCollectionViewSectionType.h"

@interface CollectionViewItem()
@property (readwrite) File *file;
@end

@implementation CollectionViewItem
@dynamic type;
@end

@implementation CollectionViewSectionItem
@end

@implementation PhotoCollectionViewModel {
    NSMutableArray *photosGroupByDate;
}

- (instancetype)initWithCollectionView:(UICollectionView*)collectionView {
    if (self = [super init]) {
        items = [[NSMutableArray<id<SectionModelItem>> alloc] init];
        
        // Register cell classes
        [collectionView registerNib:[UINib nibWithNibName:PhotoCollectionReusableView.identifier bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PhotoCollectionReusableView.identifier];
        [collectionView registerNib:[UINib nibWithNibName:PhotoCollectionViewCell.identifier bundle:nil] forCellWithReuseIdentifier:PhotoCollectionViewCell.identifier];
        
//        queue = [[NSOperationQueue alloc]init];
//        queue.maxConcurrentOperationCount = 2;
    }
    return self;
}

- (void)update {
    [items removeAllObjects];
    [self setupRows];
}

- (void)setupRows {
    self->photosGroupByDate = [self groupByDate:self.photos];
    
    for (NSDictionary *dic in photosGroupByDate) {
        NSMutableArray *rowItems = [NSMutableArray array];
        NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
        for (File *file in photosByTheSameDate) {
            CollectionViewItem *item = [[CollectionViewItem alloc] initWithType:ItemType_Photo withTitle:@"Row"];
            item.file = file;
            [rowItems addObject:item];
        }
        
        NSArray *demoRowItems = [NSArray arrayWithArray:rowItems];
        CollectionViewSectionItem *item = [[CollectionViewSectionItem alloc] initWithRowCount:[demoRowItems count]];
        item.type = PhotoSection;
        item.sectionTitle = [[NSString alloc]initWithFormat:@"%@", [[dic allKeys] firstObject]];
        item.rows = demoRowItems;
        [items addObject:item];
    }
}

- (NSMutableArray *)groupByDate:(NSMutableArray *)itmes {
    NSMutableArray *photosGroup, *photos;
    NSMutableDictionary* groupDic;
    NSString* previousDateString;
    
    photosGroup = [NSMutableArray array];
    for(File* file in itmes){
        BOOL hasNewDateGroup = NO;
        NSString* dateString = [self getDateStringShowInPhotoAlbum:file.createTime];
        if(previousDateString == nil || ![previousDateString isEqualToString:dateString]){
            photos = [NSMutableArray array];
            groupDic = [NSMutableDictionary dictionary];
            hasNewDateGroup = YES;
        }
        [photos addObject:file];
        previousDateString = dateString;
        if(hasNewDateGroup){
            [groupDic setValue:photos forKey:dateString];
            [photosGroup addObject:groupDic];
        }
    }
    
    return photosGroup;
}

- (NSString *)getDateStringShowInPhotoAlbum:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *datestring = [formatter stringFromDate:date];
    return datestring;
}

- (File *)getFileWithIndexPath:(NSIndexPath *)indexPath {
    File* file;
    
    NSDictionary* dic = [photosGroupByDate objectAtIndex:indexPath.section];
    NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
    
    file = ((File*)[photosByTheSameDate objectAtIndex:indexPath.row]);
    return file;
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return items.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    id<SectionModelItem> item = [items objectAtIndex:indexPath.section];
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        PhotoCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PhotoCollectionReusableView.identifier forIndexPath:indexPath];
        headerView.titleLabel.text = item.sectionTitle;
        [headerView.titleLabel sizeToFit];
        
        reusableview = headerView;
    }
    
    return reusableview;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary* dic = [photosGroupByDate objectAtIndex:section];
    NSMutableArray* photosByTheSameDate = [dic valueForKey:[[dic allKeys] firstObject]];
    NSInteger itemsCount = photosByTheSameDate.count;
    return itemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id<SectionModelItem> item = [items objectAtIndex:indexPath.section];
    CollectionViewItem *row = (CollectionViewItem *)[item.rows objectAtIndex:[indexPath row]];
    
    switch (item.type) {
        case PhotoSection:
        {
            switch (row.type) {
                case ItemType_Photo:
                {
                    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PhotoCollectionViewCell.identifier forIndexPath:indexPath];
                    File *file = row.file;
                    
                    cell.imageview.image = [UIImage imageNamed:@"img_photo.jpg"];
                    
                    if(_editMode == NormalMode){
                        cell.checkboxImageView.hidden = YES;
                    }else{
                        cell.checkboxImageView.hidden = NO;
                    }
                    
                    int position = 0;
                    for(int section = 0; section < indexPath.section; section++){
                        position += [collectionView numberOfItemsInSection:section];
                    }
                    
                    position += indexPath.row;
                    
                    if([_selectedPhotos containsObject:file]){
                        [cell setSelected:YES];
                        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                        
                    }else{
                        [cell setSelected:NO];
                        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
                    }
                    
                    return cell;
                }
            }
            break;
        }
        default:
            break;
    }
    return [[UICollectionViewCell alloc] init];
}


@end
