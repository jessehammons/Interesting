//
//  INTheme.h
//  Interesting
//
//  Created by Jesse Hammons on 4/30/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INTheme : NSObject

+ (INTheme*)shared;

- (UIBarButtonItem*)defaultRightBarButtonItem;

@end
