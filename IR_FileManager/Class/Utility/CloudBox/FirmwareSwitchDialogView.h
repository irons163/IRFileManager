//
//  FirmwareDialogView.h
//  CloudBox
//
//  Created by Wowoya on 13/4/21.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirmwareSwitchDialogView : UIView

@property (nonatomic) id delegate;
@property (strong, nonatomic) IBOutlet UILabel *messageLbl;
@property (strong, nonatomic) IBOutlet UILabel *titleLbl;
@property (strong, nonatomic) IBOutlet UIButton *noBtn;
@property (strong, nonatomic) IBOutlet UIButton *yesBtn;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)noClk:(id)sender;
- (IBAction)yesClk:(id)sender;

-(void) changeToSingleBtn;

@end
