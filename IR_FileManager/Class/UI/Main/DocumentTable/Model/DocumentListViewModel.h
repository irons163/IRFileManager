//
//  DocumentListViewModel.h
//  IR_FileManager
//
//  Created by Phil on 2020/1/30.
//  Copyright © 2020 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IRCollectionTableViewModel/IRCollectionTableViewModel.h>
#import "DocumentListFileType.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DocumentListRowType){
    RowType_FileRow
};

@interface TableViewRowItem : RowBasicModelItem
@property (readonly) DocumentListRowType type;
@end

@interface TableViewSectionItem : SectionBasicModelItem
@property (nonatomic) NSString* sectionTitle;
@property (nonatomic) SectionType type;
@end

@interface DocumentListViewModel : TableViewBasicViewModel<UITableViewDataSource>

@property (nonatomic) NSMutableArray *files;
@property (nonatomic) FILE_TYPE fileType;

- (instancetype)initWithTableView:(UITableView*)tableView;

- (void)update;

@end

NS_ASSUME_NONNULL_END
