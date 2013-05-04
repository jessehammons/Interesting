//
//  INTagsTableViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iCarousel.h"

@interface INTagsTableView : UITableView
@end

@interface INTagsTableViewController : UIViewController <iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet iCarousel *carousel;

@property (nonatomic, strong) NSArray *photos;

@end
