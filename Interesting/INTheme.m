//
//  INTheme.m
//  Interesting
//
//  Created by Jesse Hammons on 4/30/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INTheme.h"

@implementation INTheme

+ (INTheme*)shared {
    static INTheme *singleton = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        singleton = [[[self class] alloc] init];
    });
    return singleton;
}

- (UIBarButtonItem*)defaultRightBarButtonItem
{
    UIImage *barButtonImage = [UIImage imageNamed:@"blue_nyo_sm"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, barButtonImage.size.width, barButtonImage.size.height);
    [button setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    button.showsTouchWhenHighlighted = YES;
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}
@end
