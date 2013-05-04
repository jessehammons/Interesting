//
//  INTestDispatchViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 5/2/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INFlickrDataSource;

@interface INTestDispatchViewController : UITableViewController

@property (nonatomic, strong) INFlickrDataSource *dataSource;

@end
