//
//  INTestTableViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 5/2/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INFlickrDataSource;

@interface INTestTableViewController : UITableViewController

@property (nonatomic, strong) INFlickrDataSource *flickrDataSource;
@property (nonatomic, assign) NSInteger maxRowSoFar;
@property (nonatomic, assign) BOOL isLoading;

@end
