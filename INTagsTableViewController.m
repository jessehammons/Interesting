//
//  INTagsTableViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INTagsTableViewController.h"

#import "INThumbnailCache.h"
#import "INFlickrAPI.h"
#import "INDispatch.h"
#import "INPhotoView.h"

#import "INPhotoCarouselView.h"

@interface UITableView ()
- (void)handlePan:(UIPanGestureRecognizer*)recognizer;
@end

@interface INTagsTableViewController ()

@end

@interface INTagsTableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *blueLineView;
@property (nonatomic, strong) INPhotoView *photoView;
@property (nonatomic, strong) INPhotoCarouselView *photoCarousel;
@property (nonatomic, strong) NSDictionary *photo;

- (void)updatePhoto:(NSDictionary*)dictionary;

@end

@implementation INTagsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        ////    self.tableView.separatorColor = [UIColor colorWithRed:0.03 green:0.38 blue:0.89 alpha:0.9];
        self.blueLineView = [[UIView alloc] initWithFrame:CGRectZero];
        self.blueLineView.backgroundColor = [UIColor colorWithRed:0.03 green:0.38 blue:0.89 alpha:0.9];
        [self.contentView addSubview:self.blueLineView];

//        self.photoView = [[INPhotoView alloc] initWithFrame:CGRectZero];
//        [self.contentView addSubview:self.photoView];

        self.photoCarousel = [[INPhotoCarouselView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.photoCarousel];

    }
    return self;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    self.contentView.backgroundColor = [UIColor clearColor];

    self.blueLineView.frame = CGRectMake(110, 0, self.contentView.frame.size.width-220, 1);
    self.textLabel.frame = CGRectMake(self.blueLineView.frame.origin.x+2, CGRectGetMaxY(self.blueLineView.frame)+1, self.blueLineView.frame.size.width, 34);
    self.photoView.frame = CGRectMake(0, 0, 240, 180);
    self.photoView.center = self.contentView.center;

    self.photoCarousel.frame = CGRectInset(self.bounds, 20, 20);
}

- (void)updatePhoto:(NSDictionary*)dictionary
{
    self.photo = dictionary;

    [self.photoView updatePhoto:dictionary];
}

@end


@implementation INTagsTableView

//- (void)handlePan:(UIPanGestureRecognizer*)recognizer
//{
//    CGPoint velocity = [recognizer velocityInView:self];
//    if (fabs(velocity.x) > fabs(velocity.y)*2 ) {
//        NSIndexPath *indexPath = [self indexPathForRowAtPoint:[recognizer locationInView:self]];
//        UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
//        if ([cell respondsToSelector:@selector(photoCarousel)]) {
//            INPhotoCarouselView *photoCarousel = [cell performSelector:@selector(photoCarousel)];
//            [photoCarousel.carousel performSelector:@selector(didPan:) withObject:recognizer];
//        }
//    }
//    else {
//        NSLog(@"velocity=%@, translation=%@", NSStringFromCGPoint([recognizer velocityInView:self]), NSStringFromCGPoint([recognizer translationInView:self]));
//        [super handlePan:recognizer];
//    }
//}
//
@end

@implementation INTagsTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

//    self.tableView.pagingEnabled = YES;
    self.tableView.decelerationRate = UIScrollViewDecelerationRateNormal*8;

    self.tableView.allowsSelection = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 44, 0);
//    self.tableView.separatorColor = [UIColor colorWithRed:0.03 green:0.38 blue:0.89 alpha:0.9];
    self.tableView.separatorColor = [UIColor clearColor];
    
    [[INFlickrAPI shared] interestingPhotosForTags:@[@"green"] section:0 filterPredicate:nil completion:^(NSArray *photos, NSError *error) {
        [[INBlockDispatch shared] dispatchMain:^{
            self.photos = photos;
            [self.tableView reloadData];
            [self.carousel reloadData];
            //            [[INThumbnailCache shared] preprocessPhotos:self.photos URLKeys:@[@"url_t"]];
        }];
    }];

    self.tableView.transform = CGAffineTransformMakeScale(0.54, 0.54);
    
    self.carousel = [[iCarousel alloc] initWithFrame:self.view.frame];
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.backgroundColor = [UIColor clearColor];
    self.carousel.dataSource = self;
    self.carousel.delegate = self;
//    [self.view addSubview:self.carousel];
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing) {
        value = 2*value;
    }
    return value;
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    return self.photos.count;
}
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    INPhotoView *photoView = (id)view;
    if (view == nil) {
        view = photoView = [[INPhotoView alloc] initWithFrame:CGRectMake(0, 0, 240, 180)];
    }
    NSDictionary *photo = [self.photos objectAtIndex:index];
    [photoView updatePhoto:photo];
    
    return view;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    return 6;
}

- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    if (view == nil) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    }
    view.backgroundColor = [UIColor darkGrayColor];
    return view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    INTagsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[INTagsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSDictionary *photo = [self.photos objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor colorWithRed:0.96 green:0.18 blue:0.57 alpha:1];
    cell.textLabel.text = [[[photo objectForKey:@"tags"] componentsSeparatedByString:@" "] objectAtIndex:0];
 
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    [cell updatePhoto:photo];

    cell.photoCarousel.photos = self.photos;
    [cell.photoCarousel.carousel reloadData];

    NSInteger prefetchSize = 6;
    NSMutableArray *prefetch = [NSMutableArray array];
    NSInteger indexBefore = MAX(0, indexPath.row - prefetchSize);
    if (indexBefore < indexPath.row) {
        NSArray *before = [self.photos subarrayWithRange:NSMakeRange(indexBefore, indexPath.row-indexBefore)];
        [prefetch addObjectsFromArray:before];
    }
    NSInteger indexAfter = MIN(self.photos.count-1, indexPath.row + 1 + prefetchSize);
    if (indexAfter > indexPath.row) {
        NSArray *after = [self.photos subarrayWithRange:NSMakeRange(indexPath.row, indexAfter-indexPath.row)];
        [prefetch addObjectsFromArray:after];
    }
    [[INThumbnailCache shared] preprocessPhotos:prefetch URLKeys:@[@"url_t"]];

    return cell;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSInteger numRows = targetContentOffset->y / self.tableView.rowHeight;
    targetContentOffset->y = numRows*self.tableView.rowHeight;
}

@end
