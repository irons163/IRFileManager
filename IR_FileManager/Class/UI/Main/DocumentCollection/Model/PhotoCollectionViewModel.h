//
//  PhotoCollectionViewModel.h
//  IR_FileManager
//
//  Created by Phil on 2020/1/30.
//  Copyright © 2020 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IRCollectionTableViewModel/IRCollectionTableViewModel.h>
#import "PhotoCollectionViewSectionType.h"
#import "File+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditMode) {
    NormalMode,
    DeleteMode,
    UploadMode
};

typedef NS_ENUM(NSInteger, PhotoCollectionViewItemType){
    ItemType_Photo
};

@interface CollectionViewItem : RowBasicModelItem
@property (readonly) PhotoCollectionViewItemType type;
@property (readonly) File *file;
@end

@interface CollectionViewSectionItem : SectionBasicModelItem
@property (nonatomic) NSString* sectionTitle;
@property (nonatomic) SectionType type;
@end

@interface PhotoCollectionViewModel : TableViewBasicViewModel<UICollectionViewDataSource>

@property (nonatomic) NSMutableArray *photos;
@property (nonatomic) NSMutableArray* selectedPhotos;
@property (nonatomic) EditMode editMode;

- (instancetype)initWithCollectionView:(UICollectionView*)collectionView;

- (void)update;
- (File *)getFileWithIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
