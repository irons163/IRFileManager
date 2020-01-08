//
//  AboutViewController.m
//  CloudBox
//
//  Created by Wowoya on 13/4/19.
//  Copyright (c) 2013年 Wowoya. All rights reserved.
//
#import "AboutViewController.h"
#import "AboutViewTableViewCell.h"
#import "AboutDetailViewController.h"
#import "UIColor+Helper.h"
#import "ColorDefine.h"

@implementation AboutViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithColorCodeString:NavigationBarBGColor_OnLine]];
    self.navigationItem.title = _(@"ABOUT_TITLE");
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    [tableView registerNib:[UINib nibWithNibName:@"AboutViewTableViewCell" bundle:nil] forCellReuseIdentifier:@"AboutViewTableViewCell"];
    
    tableView.tableFooterView = [[UIView alloc] init];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AboutViewTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"AboutViewTableViewCell" forIndexPath:indexPath];
    
    if(indexPath.row == 0){
        cell.textLabel.text = _(@"GENERAL");
    }else if(indexPath.row == 1){
        cell.textLabel.text = _(@"LEGAL_INFO");
    }else if(indexPath.row == 2){
        cell.textLabel.text = _(@"FAQ");
    }
#ifdef MESSHUDrive
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
#endif
    
    return cell;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    AboutDetailViewController* aboutDetailViewController = [[AboutDetailViewController alloc] initWithNibName:@"AboutDetailViewController" bundle:nil];
    
    if(indexPath.row == 0){
        aboutDetailViewController.aboutType = GENERAL_TYPE;
    }else if(indexPath.row == 1){
        aboutDetailViewController.aboutType = LEGAL_INFO_TYPE;
    }else if(indexPath.row == 2){
        aboutDetailViewController.aboutType = FAQ_TYPE;
    }
    
    [self.navigationController pushViewController:aboutDetailViewController animated:YES];
    
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#ifdef MESSHUDrive
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1) {
        return 0;
    }
    return 44;
}
#endif

@end
