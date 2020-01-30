//
//  DocumentListViewModel.m
//  IR_FileManager
//
//  Created by Phil on 2020/1/30.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "DocumentListViewModel.h"
#import "DocumentTableViewCell.h"
#import "DocumentListSectionType.h"
#import "FileTypeUtility.h"
#import "Utilities.h"
#import "UIImageView+WebCache.h"

@implementation TableViewRowItem
@dynamic type;
@end

@implementation TableViewSectionItem
@end

@implementation DocumentListViewModel {
    NSOperationQueue *queue;
}

- (instancetype)initWithTableView:(UITableView *)tableView {
    if (self = [super init]) {
        items = [[NSMutableArray<id<SectionModelItem>> alloc] init];
        
        [tableView registerNib:[UINib nibWithNibName:DocumentTableViewCell.identifier bundle:nil] forCellReuseIdentifier:DocumentTableViewCell.identifier];
        
        queue = [[NSOperationQueue alloc]init];
        queue.maxConcurrentOperationCount = 2;
    }
    return self;
}

- (void)update {
    [items removeAllObjects];
    [self setupRows];
}

- (void)setupRows {
    NSMutableArray *rowItems = [NSMutableArray array];
    for (File *file in _files) {
        [rowItems addObject:[[TableViewRowItem alloc] initWithType:RowType_FileRow withTitle:@"Row"]];
    }
    
    NSArray *demoRowItems = [NSArray arrayWithArray:rowItems];
    TableViewSectionItem *item = [[TableViewSectionItem alloc] initWithRowCount:[demoRowItems count]];
    item.type = FileSection;
    item.sectionTitle = @"Section";
    item.rows = demoRowItems;
    [items addObject:item];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return items.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [items[section] rowCount];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    id<SectionModelItem> item = [items objectAtIndex:indexPath.section];
    TableViewRowItem *row = (TableViewRowItem *)[item.rows objectAtIndex:[indexPath row]];
    
    switch (item.type) {
        case FileSection:
        {
            switch (row.type) {
                case RowType_FileRow:
                {
                    DocumentTableViewCell *cell = (DocumentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:DocumentTableViewCell.identifier forIndexPath:indexPath];
                    File* file;
                    
                    file = ((File*)[_files objectAtIndex:indexPath.row]);
                    
                    cell.titleLabel.text = file.name;
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
                    
                    if (self.fileType == VIDEO_TYPE) {
                        [self setThumbToCell:cell byVideoPath:filePath];
                    } else if(self.fileType == MUSIC_TYPE) {
                        cell.thumbnailImageView.image = [Utilities getMusicCover:filePath];
                        if(cell.thumbnailImageView.image==nil)
                            cell.thumbnailImageView.image = [FileTypeUtility getImageWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
                    } else if(self.fileType == DOCUMENT_TYPE) {
                        cell.thumbnailImageView.image = [FileTypeUtility getImageWithType:@"DOCUMENT" ext:[cell.titleLabel.text pathExtension]];
                    } else if(self.fileType == PHOTO_TYPE) {
                        
                    } else if(self.fileType == ALL_TYPE) {
                        if ([file.type isEqualToString:@"VIDEO"]) {
                            [self setThumbToCell:cell byVideoPath:filePath];
                        } else if([file.type isEqualToString:@"MUSIC"]) {
                            if(cell.thumbnailImageView.image==nil)
                                cell.thumbnailImageView.image = [FileTypeUtility getImageWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
                        } else if([file.type isEqualToString:@"PICTURE"]) {
                            cell.thumbnailImageView.image = [UIImage imageNamed:@"img_photo.jpg"];
                            @autoreleasepool {
                                [cell.thumbnailImageView setImageWithURL:[NSURL fileURLWithPath:filePath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"]  options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                }];
                            }
                        } else {
                            cell.thumbnailImageView.image = [FileTypeUtility getImageWithType:file.type ext:[cell.titleLabel.text pathExtension]];
                        }
                    }
                    
                    cell.fileSizeLabel.text = [[NSString stringWithFormat:@"%lld", file.size] stringByAppendingString:@", "];
                    [cell.fileSizeLabel setNumberOfLines:1];
                    [cell.fileSizeLabel sizeToFit];
                    CGRect newFrame = cell.createDateLabel.frame;
                    newFrame.origin.x = cell.fileSizeLabel.frame.origin.x + cell.fileSizeLabel.frame.size.width;
                    cell.createDateLabel.frame = newFrame;
                    cell.createDateLabel.text = file.createTime.description;
                    [cell.createDateLabel setNumberOfLines:1];
                    [cell.createDateLabel sizeToFit];
                    
                    cell.delegate = self;
                    cell.file = file;
                    
                    return cell;
                }
            }
            break;
        }
        default:
            break;
    }
    return [[UITableViewCell alloc] init];
}

- (void)setThumbToCell:(DocumentTableViewCell*)cell byVideoPath:(NSString*)filePath {
    if(!cell.operation){
        [cell.operation cancel];
    }
    
    cell.thumbnailImageView.image = [FileTypeUtility getImageWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
    
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *image = [Utilities generateThumbImage:filePath];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            cell.thumbnailImageView.image = image;
            if(cell.thumbnailImageView.image==nil)
                cell.thumbnailImageView.image = [FileTypeUtility getImageWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
        }];
    }];
    
    cell.operation = operation;
    
    [queue addOperation:operation];
}

@end
