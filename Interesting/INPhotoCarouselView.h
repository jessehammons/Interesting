//
//  INPhotoCarouselView.h
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iCarousel.h"

@interface INPhotoCarouselView : UIView <iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) iCarousel *carousel;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) NSArray *photos;

@end
