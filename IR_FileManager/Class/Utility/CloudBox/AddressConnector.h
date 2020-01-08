//
//  AddressConnector.h
//  EnShare
//
//  Created by sniApp on 2015/2/15.
//  Copyright (c) 2015年 Senao. All rights reserved.
//

#import "HttpAPICommander.h"
#import "StaticHttpRequest.h"

@interface AddressConnector : HttpAPICommander <StaticHttpRequestDelegate>

-(void) startLoginToDevice;

@end
