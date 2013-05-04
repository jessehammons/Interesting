//
//  INHorizontalViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iCarousel.h"

@class INPhotoGroup;

@interface INHorizontalViewController : UIViewController <UIActionSheetDelegate, iCarouselDataSource, iCarouselDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) iCarousel *carousel;

@property (nonatomic, strong) INPhotoGroup *photoGroup;
@property (nonatomic, assign) BOOL isScrolling;
@property (nonatomic, assign) NSInteger currentIndex;

- (void)updatePhotoGroup:(INPhotoGroup*)value;
- (void)loadPhoto:(NSDictionary*)photo;
- (void)loadTag:(NSString*)tag completion:(void (^)(void))completion;

@end
