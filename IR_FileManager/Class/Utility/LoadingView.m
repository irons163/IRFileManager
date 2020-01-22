//
//  LoadingView.m
//
//  Created by ke on 6/28/13.
//

#import "LoadingView.h"
#import "KGModal.h"

@implementation LoadingView

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

@end
