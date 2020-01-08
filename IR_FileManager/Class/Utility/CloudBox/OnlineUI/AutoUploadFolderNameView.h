//
//  SuccessView.h
//  EnShare
//
//  Created by ke on 6/27/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoUploadFolderNameView : UIView

@property (nonatomic, assign) id delegate;
@property (strong, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (strong, nonatomic) NSString *tagFrom;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)cancelClk:(id)sender;
- (IBAction)okClk:(id)sender;

@end
