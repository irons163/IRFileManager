//
//  FirmwareDialogView.h
//  CloudBox
//
//  Created by Wowoya on 13/4/21.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirmwareDialogView : UIView

@property (nonatomic) id delegate;
@property (strong, nonatomic) IBOutlet UILabel *messageLbl;
@property (strong, nonatomic) IBOutlet UILabel *titleLbl;
@property (strong, nonatomic) IBOutlet UIButton *cancelBtn;
@property (strong, nonatomic) IBOutlet UIButton *detailBtn;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)cancelClk:(id)sender;
- (IBAction)detailClk:(id)sender;

-(void) changeToSingleBtn;

@end
