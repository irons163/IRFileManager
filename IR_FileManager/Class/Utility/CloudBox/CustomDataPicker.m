//
//  CustomDataPicker.m
//  EnViewerSOHO
//
//  Created by WeiJun on 4/14/15.
//  Copyright (c) 2015 sniApp. All rights reserved.
//

#import "CustomDataPicker.h"
#import "dataDefine.h"
#import "ColorDefine.h"
#import "UIColor+Helper.h"

@interface CustomDataPicker ()

@end

@implementation CustomDataPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    pickArray = [NSArray arrayWithObjects:_(@"LANGUAGE_AUTO")
                 ,_(@"LANGUAGE_EN")
                 ,_(@"LANGUAGE_TC")
                 , nil];
    cancelItem.title = _(@"ButtonTextCancel");
    doneItem.title = _(@"ButtonTextDone");
    
    toolbar.barTintColor = [UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine];
}

-(void)viewDidAppear:(BOOL)animated{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)setCurrentLanguage:(NSString *)language caller:(id)caller{
    currentCaller = caller;
    if ([pickArray containsObject:language]) {
        currentRow = [pickArray indexOfObject:language];
    }else{
        currentRow = 0;
        NSLog(@"not found");
    }
    [dataPickView selectRow:currentRow inComponent:0 animated:YES];
}

- (IBAction)cancelClick:(id)sender {
    [self.delegate didDataPickerCancel];
}

- (IBAction)doneClick:(id)sender {
    NSInteger row = [dataPickView selectedRowInComponent:0];
    NSLog(@"%@",[pickArray objectAtIndex:row]);
    [self.delegate didDataPickerDoneWithLanguage:[pickArray objectAtIndex:row] caller:currentCaller];
}
- (void)dealloc {
    
}

#pragma mark UIPickerViewDataSource
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [pickArray count];
}

-(NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [pickArray objectAtIndex:row];
}

@end
