//
//  INPhotoCarouselView.m
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INPhotoCarouselView.h"

#import "INPhotoView.h"

@implementation INPhotoCarouselView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.carousel = [[iCarousel alloc] initWithFrame:CGRectZero];
        self.carousel.dataSource = self;
        self.carousel.delegate = self;
        self.carousel.type = iCarouselTypeCoverFlow2;
        [self addSubview:self.carousel];
    }
    return self;
}

- (void)layoutSubviews
{
    self.carousel.frame = self.bounds;
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return self.photos.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    INPhotoView *photoView = (id)view;
    if (photoView == nil) {
        CGFloat height = self.frame.size.height - 180;
        CGFloat width = ceil(4.0*height/3.0);
        photoView = [[INPhotoView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    }
    NSDictionary *photo = [self.photos objectAtIndex:index];
    [photoView updatePhoto:photo];

    return photoView;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing) {
        value = 2.5*value;
    }
    else if (option == iCarouselOptionTilt) {
        value = 0.4;
    }
    if (option == iCarouselOptionWrap) {
        value = 1;
    }
    return value;
}

- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //only for custom?
    return CATransform3DIdentity;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
//    [UIView animateWithDuration:0.1 animations:^{
//        [self.carousel itemViewAtIndex:self.currentIndex].transform = CGAffineTransformIdentity;
//    }];
//    self.currentIndex = carousel.currentItemIndex;
//    [UIView animateWithDuration:0.3 animations:^{
//        [self.carousel itemViewAtIndex:self.currentIndex].transform = CGAffineTransformMakeScale(1.4, 1.4);
//    }];
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    return 6;
}

- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    if (view == nil) {
        view = [[INPhotoView alloc] initWithFrame:CGRectMake(0, 0, 240, 180)];
    }
    return view;
}

@end
