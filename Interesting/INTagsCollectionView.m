//
//  INTagsCollectionView.m
//  Interesting
//
//  Created by Jesse Hammons on 4/27/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INTagsCollectionView.h"
//#import "INDispatch.h"
#import "INObject.h"
#import "INPipeline.h"

#import <QuartzCore/QuartzCore.h>

@interface INTagCell : UICollectionViewCell


@property (nonatomic, strong) UIImageView *stackImageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *lineImageView;
@property (nonatomic, strong) UIImageView *progressImageView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicatorView;
@property (nonatomic, strong) NSDictionary *photo;
@property (nonatomic, strong) INPipelineObject *imagePipelineObject;
@property (nonatomic, strong) INPipelineObject *previewPipelineObject;

- (void)updatePhoto:(NSDictionary*)dictionary;

@end

@implementation INTagCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.autoresizesSubviews = NO;
        self.contentView.autoresizesSubviews = NO;
        self.stackImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"stack_frame_sm"]];
        self.stackImageView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:self.stackImageView];

//        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"i_progress_bg_gray"]];

        self.lineImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blue_line"]];
//        self.lineImageView = (id)[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
        self.lineImageView.backgroundColor = [UIColor blueColor];
        [self.contentView addSubview:self.lineImageView];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
//        self.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.label.font = [UIFont fontWithName:@"Didot-Italic" size:14];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textAlignment = NSTextAlignmentCenter;//96 18 57
        self.label.textColor = [UIColor colorWithRed:0.96 green:0.18 blue:0.57 alpha:1];
        [self.contentView addSubview:self.label];

        self.progressImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.progressImageView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"i_progress_bg_gray"]];
//        self.progressImageView.backgroundColor = [UIColor redColor];
        self.progressImageView.clipsToBounds = YES;
        [self.contentView addSubview:self.progressImageView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];

        self.loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.loadingIndicatorView.hidesWhenStopped = YES;
        [self.contentView addSubview:self.loadingIndicatorView];
//        self.imageView.layer.borderWidth = 5;
//        self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
//        self.progressImageView.layer.borderWidth = self.imageView.layer.borderWidth;
//        self.progressImageView.layer.borderColor = self.imageView.layer.borderColor;
        
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 30)];
//        label.font = [UIFont systemFontOfSize:10];
//        label.tag = 99;
//        label.numberOfLines = 0;
//        [self.progressImageView addSubview:label];


    }
    return self;
}

- (void)layoutSubviews {
    //24, 18 for top left of stack
    //182x135@2x for image
    //226x168 for stack
//    self.contentView.backgroundColor = [UIColor brownColor];
    self.lineImageView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, 1);

    self.label.frame = CGRectMake(0, CGRectGetMaxY(self.lineImageView.frame), self.contentView.frame.size.width, 20);

    CGFloat width = self.contentView.frame.size.width - 20;
    CGFloat height = ceil(width*3/4);
    CGFloat y = self.contentView.frame.size.height - height;
    self.progressImageView.frame = CGRectMake(12, y, width, height);
    self.imageView.frame = CGRectMake(12, y, width, height);

    self.stackImageView.center = self.imageView.center;
    self.loadingIndicatorView.center = self.imageView.center;
}

- (void)updatePhoto:(NSDictionary*)dictionary {
    self.photo = dictionary;

    self.label.text = [[[self.photo objectForKey:@"tags"] componentsSeparatedByString:@" "] objectAtIndex:0];

    self.progressImageView.image = nil;
    self.progressImageView.alpha = 0.8;

    self.imageView.image = nil;
    self.imageView.alpha = 0.0;

    self.contentView.alpha = 0.8;

    NSString *url_t = [self.photo objectForKey:@"url_t"];
    NSURL *URLt = [NSURL URLWithString:url_t];
    if ([URLt isEqual:self.previewPipelineObject.dataURL]) {
        return;
    }
//    NSLog(@"tag=%@, url=%@", self.label.text, [url_t lastPathComponent]);

    [self.previewPipelineObject removeImageView:self.progressImageView];
    self.previewPipelineObject = [INPipeline promoteDispatchForDataURL:URLt priority:INPipelinePriorityHigh download:YES useCache:YES imageView:self.progressImageView decodeBlock:NULL];
    
    return;
//    NSString *urlN = [self.photo objectForKey:@"url_z"];
//    NSURL *URLN = [NSURL URLWithString:urlN];
//    if (urlN.length > 0) {
//        [[INThumbnailCache shared] cancelDispatch:self.imageRecord];
//        self.imageRecord = [[INThumbnailCache shared] decodeImageURL:URLN forSize:self.imageView.frame.size priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
//            ZG_ASSERT_IS_MAIN_THREAD();
//            [[INThumbnailCache shared] cancelDispatch:self.previewImageRecord];
//            self.previewImageRecord = nil;
//            self.imageView.image = image;
//            self.imageRecord = nil;
//            [UIView animateWithDuration:0.3 animations:^{
//                self.imageView.alpha = 1;
//                self.progressImageView.alpha = 0;
//                self.contentView.alpha = 1;
//            }];
//        }];
//    }
}

@end

@implementation INTagsCollectionView

- (void)viewDidInit
{
    self.backgroundColor = [UIColor clearColor];

    self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.flowLayout.itemSize = CGSizeMake(110, 120);
    self.flowLayout.minimumInteritemSpacing = 75;
    self.flowLayout.minimumLineSpacing = 100;
    self.flowLayout.sectionInset = UIEdgeInsetsMake(0, 60, 0, 60);
    self.flowLayout.headerReferenceSize = CGSizeMake(1024, 64);
    self.flowLayout.footerReferenceSize = CGSizeMake(1024, 64);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:self.flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[INTagCell class] forCellWithReuseIdentifier:NSStringFromClass([INTagCell class])];
    self.collectionView.dataSource = self;
    [self addSubview:self.collectionView];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self viewDidInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self viewDidInit];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)sectionIndex
{
    return [self.tagsDataSource tagsCount];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    INDataSource *tag = [self.tagsDataSource tagAtIndex:indexPath.item updateHighWatermark:YES];

    INTagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([INTagCell class]) forIndexPath:indexPath];
    
//    NSInteger prefetchSize = 6;
//    NSMutableArray *prefetch = [NSMutableArray array];
//    NSInteger indexBefore = MAX(0, indexPath.row - prefetchSize);
//    if (indexBefore < indexPath.row) {
//        NSArray *before = [self.photos subarrayWithRange:NSMakeRange(indexBefore, indexPath.row-indexBefore)];
//        [prefetch addObjectsFromArray:before];
//    }
//    NSInteger indexAfter = MIN(self.photos.count-1, indexPath.row + 1 + prefetchSize);
//    if (indexAfter > indexPath.row) {
//        NSArray *after = [self.photos subarrayWithRange:NSMakeRange(indexPath.row, indexAfter-indexPath.row)];
//        [prefetch addObjectsFromArray:after];
//    }
//    [[INThumbnailCache shared] preprocessPhotos:prefetch URLKeys:@[@"url_t"]];
//
//    [cell updatePhoto:photo.dictionary];
    if (tag.photos.count > 0) {
        INPhotoObject *photoObject = [tag.photos objectAtIndex:0];
        [cell updatePhoto:photoObject.dictionary];
    }
    cell.label.text = [tag.sourceTags objectAtIndex:0];
    if (indexPath.item == self.tagsDataSource.tags.count-1 && [self.tagsDataSource needsMoreTags]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(loadNextSectionIfNecessary) withObject:nil afterDelay:0.1];

        [cell.loadingIndicatorView startAnimating];
    }
    else {
        [cell.loadingIndicatorView stopAnimating];
    }

    return cell;
}

- (void)preloadSection:(INSection*)section
{
    for(INDataSource *source in section.tags) {
        [source sectionForSectionIndex:0 completion:NULL];
    }
}

- (void)loadNextSectionIfNecessary
{
    WEAKSELF();
    if (self.isLoading == NO && [self.tagsDataSource needsMoreTags]) {
        self.isLoading = YES;
        NSLog(@"sections=%d, tags=%d, highwater=%d", self.tagsDataSource.sections.count, self.tagsDataSource.tags.count, self.tagsDataSource.tagsHighWaterMark);
        [self.tagsDataSource sectionForSectionIndex:self.tagsDataSource.sections.count completion:^(INSection *section) {
            ZG_ASSERT_IS_MAIN_THREAD();
                [weakSelf.collectionView reloadData];
//            NSInteger itemCount = weakSelf.tagsDataSource.tags.count;
//            NSInteger previousCount = itemCount - section.tags.count;
//            NSMutableArray *indexPaths = [NSMutableArray array];
//            for(NSInteger i = previousCount; i < itemCount; i++) {
//                [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
//            }
//            [weakSelf.collectionView insertItemsAtIndexPaths:indexPaths];
            weakSelf.isLoading = NO;
//            [weakSelf performSelector:@selector(loadNextSectionIfNecessary) withObject:nil afterDelay:0.1];
//            [weakSelf preloadSection:section];
            for(INTagCell *cell in [self.collectionView visibleCells]) {
                [cell.loadingIndicatorView stopAnimating];
            }
        }];
    }
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//{
//    return [[UICollectionReusableView alloc] initWithFrame:CGRectZero];
//}

@end
