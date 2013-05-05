//
//  INHorizontalViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INHorizontalViewController.h"

#import "INTheme.h"
#import "INDispatch.h"
#import "INObject.h"
#import "INPhotoView.h"
#import "INFlickrAPI.h"
#import "INThumbnailCache.h"
#import "INPipeline.h"

@interface INHorizontalViewController ()

@end

@implementation INHorizontalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[INTheme shared] defaultRightBarButtonItem];
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didTouchRightButtonItem:)];
        
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:NULL];
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"follow" style:UIBarButtonItemStylePlain target:self action:NULL];
    }
    return self;
}

- (void)didTouchRightButtonItem:(id)sender
{
//    - (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated NS_AVAILABLE_IOS(3_2);
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Options" delegate:self cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:@"follow averylongtagwithnospacesaverylongtagwithnospacesaverylongtagwithnospaces", @"bloop", nil];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
//    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    [sheet showInView:self.view];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
//    [actionSheet insertSubview:bg atIndex:0];
    actionSheet.layer.contents = (id)bg.image.CGImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.carousel = [[iCarousel alloc] initWithFrame:self.view.frame];
    self.carousel.dataSource = self;
    self.carousel.delegate = self;
    self.carousel.type = iCarouselTypeCoverFlow ;
    [self.view addSubview:self.carousel];
    self.carousel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    
//    [[INFlickrAPI shared] interestingPhotosForTags:@[@"green"] section:0 filterPredicate:nil completion:^(NSArray *photos, NSError *error) {
//        [[INBlockDispatch shared] dispatchMain:^{
//            INPhotoGroup *group = [INPhotoGroup photoGroupWithPhotosArray:photos];
//            [self updatePhotoGroup:group];
//        }];
//    }];

    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap2:)];
    tap2.delegate = self;
    tap2.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tap2];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap1:)];
    [self.view addGestureRecognizer:tap1];
    [tap1 requireGestureRecognizerToFail:tap2];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)hideNavigationBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)toggleNavigationBar {
    BOOL hidden = self.navigationController.isNavigationBarHidden;
    hidden = !hidden;
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
    if (self.navigationController.isNavigationBarHidden == NO) {
        [self performSelector:@selector(hideNavigationBar) withObject:nil afterDelay:5];
    }
}

- (void)didTap1:(UIGestureRecognizer*)recognizer
{
    [self toggleNavigationBar];
}

- (void)didTap2:(UIGestureRecognizer*)recognizer
{
    if (CGAffineTransformIsIdentity(self.carousel.transform)) {
        [self __zoomUp];
    }
    else {
        [UIView animateWithDuration:0.3 animations:^{
            self.carousel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [self.dataSource photosCount];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    INPhotoObjectView *photoView = (id)view;
    if (photoView == nil) {
//        CGFloat scale = 0.5;
//        photoView = [[INPhotoView alloc] initWithFrame:CGRectMake(0, 0, scale*320, scale*240)];
        photoView = [[INPhotoObjectView alloc] initWithFrame:CGRectMake(0, 0, 640, 480)];
    }
    INPhotoObject *photoObject = [self.dataSource photoAtIndex:index updateHighWatermark:YES];
    [photoView updatePhotoObject:photoObject loadImageURLKeys:@[@"url_n", @"url_o"]];

    return photoView;
}


//@optional
//
//- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;
//- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view;

- (void)updateDataSource:(INDataSource*)dataSource
{
    self.dataSource = dataSource;
    [self.carousel reloadData];
    self.carousel.transform = CGAffineTransformIdentity;
    self.carousel.center = CGPointMake(self.view.frame.size.width/2, 0);
    self.carousel.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor clearColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController.isNavigationBarHidden == YES) {
            [self toggleNavigationBar];
        }
        [UIView animateWithDuration:0.5 animations:^{
            self.carousel.center = self.view.center;
        } completion:^(BOOL finished){
        }];
        [self performSelector:@selector(loadNextSectionIfNecessary) withObject:nil afterDelay:0];
    });

//    [self _zoomUp];
}

- (void)carouselWillBeginDragging:(iCarousel *)carousel
{
    self.isScrolling = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__zoomUp) object:nil];
    [self hideNavigationBar];
    if (CGAffineTransformIsIdentity(self.carousel.transform) == NO) {
        [UIView animateWithDuration:0.3 animations:^{
            self.carousel.transform = CGAffineTransformIdentity;
        }];
    }
//    else {
//    }
}

- (void)__zoomUp {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__zoomUp) object:nil];
    self.isScrolling = NO;
    CGFloat w =  640;
    CGFloat scale = self.view.frame.size.width/w;
    [UIView animateWithDuration:0.3 animations:^{
        self.carousel.transform = CGAffineTransformMakeScale(scale, scale);
    }];
}

- (void)_zoomUp {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__zoomUp) object:nil];
    [self performSelector:@selector(__zoomUp) withObject:nil afterDelay:0.7];
}

- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate
{
    if (decelerate == NO) {
        [self _zoomUp];
    }
}
- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
//    if (CGAffineTransformIsIdentity(self.carousel.transform) == NO) {
        INPhotoObjectView *photoView = (id)[carousel itemViewAtIndex:carousel.currentItemIndex];
        [photoView loadMediaWithPriority:INPipelinePriorityHigh];
//    }
}

- (void)carouselDidEndDecelerating:(iCarousel *)carousel
{
//    [self _zoomUp];
}

- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index
{
    if (carousel.currentItemIndex != index) {
//        [self performSelector:@selector(__zoomUp) withObject:nil afterDelay:0.4];
        return YES;
    }
    return NO;
}

//- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index
//{
////    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__zoomUp) object:nil];
////    if (self.isScrolling == YES) {
////        if (self.carousel.dragging == NO && self.carousel.scrolling == NO) {
////            [self performSelector:@selector(__zoomUp) withObject:nil afterDelay:0.1];
////        }
////    }
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
//    if (index == self.carousel.currentItemIndex) {
//        if (CGAffineTransformIsIdentity(self.carousel.transform)) {
//            [self performSelector:@selector(__zoomUp) withObject:nil afterDelay:0.1];
//        }
////        else {
////            [UIView animateWithDuration:0.3 animations:^{
////                self.carousel.transform = CGAffineTransformIdentity;
////            }];
////        }
//    }
//    return YES;
//}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing) {
        value = 0.8;
    }
    else if (option == iCarouselOptionTilt) {
        value = 0.7;
    }
    else if (option == iCarouselOptionWrap) {
        value = 1;
    }
    return value;
}

- (void)loadPhoto:(NSDictionary*)photo
{
    NSArray *tags = [[photo objectForKey:@"tags"] componentsSeparatedByString:@" "];
    if (tags.count > 0) {
        NSString *tag = [tags objectAtIndex:0];
        [self loadTag:tag completion:NULL];
    }
}

- (void)loadTag:(NSString*)tag completion:(void (^)(void))completion;
{
//
//    self.navigationItem.title = tag;
//    [[INFlickrAPI shared] interestingPhotosForTags:@[tag] section:0 filterPredicate:nil completion:^(NSArray *photos, NSError *error) {
//        [[INBlockDispatch shared] dispatchMain:^{
//            INPhotoGroup *group = [INPhotoGroup photoGroupWithPhotosArray:photos];
//            [self updatePhotoGroup:group];
//            if (completion != NULL) {
//                completion();
//            }
//        }];
//    }];
}

- (void)loadNextSectionIfNecessary
{
    WEAKSELF();
    if (self.isLoading == NO && [self.dataSource needsMoreTags]) {
        self.isLoading = YES;
        NSLog(@"HORIZ sections=%d, tags=%d, highwater=%d", self.dataSource.sections.count, self.dataSource.tags.count, self.dataSource.tagsHighWaterMark);
        [self.dataSource sectionForSectionIndex:self.dataSource.sections.count completion:^(INSection *section) {
            ZG_ASSERT_IS_MAIN_THREAD();
            [weakSelf.carousel reloadData];
            weakSelf.isLoading = NO;
            [weakSelf performSelector:@selector(loadNextSectionIfNecessary) withObject:nil afterDelay:0.1];
//            [weakSelf preloadSection:section];
//            for(INTagCell *cell in [self.collectionView visibleCells]) {
//                [cell.loadingIndicatorView stopAnimating];
//            }
        }];
    }
}

@end

