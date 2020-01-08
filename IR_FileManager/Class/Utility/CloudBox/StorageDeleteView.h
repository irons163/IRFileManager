//
//  StorageDeleteView.h
//  CloudBox
//
//  Created by Wowoya on 13/3/19.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StorageDeleteView : UIView

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) NSArray *files;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)cancelClk:(id)sender;
- (IBAction)okClk:(id)sender;

@end
