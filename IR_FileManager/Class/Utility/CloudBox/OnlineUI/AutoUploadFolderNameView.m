//
//  SuccessView.m
//  EnShare
//
//  Created by ke on 6/27/13.
//  Copyright (c) 2013 林永承. All rights reserved.
//

#import "AutoUploadFolderNameView.h"
#import "KGModal.h"
#import "dataDefine.h"

@implementation AutoUploadFolderNameView

-(void)awakeFromNib{
    [super awakeFromNib];
    self.imageView.layer.cornerRadius = 10;
    self.imageView.clipsToBounds = YES;
}


- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (IBAction)cancelClk:(id)sender {
    [[KGModal sharedInstance] hideAnimated:YES];
    if ([[NSUserDefaults standardUserDefaults] stringForKey:AUTO_UPLOAD_FOLDER_NAME_KEY] == nil) {//從UISwitch按下
        if ([self.delegate respondsToSelector:@selector(cancelClk)]){
            [self.delegate performSelector:@selector(cancelClk) withObject:nil];
        }
    }else{//從編輯扭按下
        
    }
}

- (IBAction)okClk:(id)sender {
    if ([self.delegate respondsToSelector:@selector(doAutoUpload:)]){
        [self.delegate performSelector:@selector(doAutoUpload:) withObject:self.folderNameTextField.text];
    }
}

@end
