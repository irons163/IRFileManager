//
//  LoadDocument.m
//  Map
//
//  Created by WeiJun on 2014/3/13.
//  Copyright (c) 2014年 WeiJun. All rights reserved.
//

#import "LoadDocument.h"

@implementation LoadDocument
-(void)loadDocument:(NSString*)documentName inView:(UIWebView*)documentWebView
{
    NSString *path = [[NSBundle mainBundle] pathForResource:documentName ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [documentWebView loadRequest:request];
}
@end
