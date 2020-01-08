//
//  CustomDataPicker.h
//  EnViewerSOHO
//
//  Created by WeiJun on 4/14/15.
//  Copyright (c) 2015 sniApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomDataPickerDelegate <NSObject>
-(void) didDataPickerCancel;
-(void) didDataPickerDoneWithLanguage:(NSString*)Language caller:(id) caller;
@end

@interface CustomDataPicker : UIViewController<UIPickerViewDataSource,UIPickerViewDelegate>
{
    id currentCaller;
    NSArray *pickArray;
    NSUInteger currentRow;
    IBOutlet UIPickerView *dataPickView;
    IBOutlet UIBarButtonItem *cancelItem;
    IBOutlet UIBarButtonItem *doneItem;
    IBOutlet UIToolbar *toolbar;
}

@property (nonatomic, strong) id<CustomDataPickerDelegate> delegate;

-(void)setCurrentLanguage:(NSString*)language caller:(id)caller;

- (IBAction)cancelClick:(id)sender;
- (IBAction)doneClick:(id)sender;
@end
