//
//  DialogView.h
//  CloudBox
//
//  Created by Wowoya on 13/4/21.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DialogView : UIView 

@property (nonatomic) id delegate;
@property (strong, nonatomic) IBOutlet UILabel *titleNameLbl;
@property (strong, nonatomic) IBOutlet UILabel *titleLbl;
@property (strong, nonatomic) IBOutlet UIButton *helpBtn;
@property (strong, nonatomic) IBOutlet UIButton *okBtn;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)okClk:(id)sender;
- (IBAction)helpClk:(id)sender;

@end
