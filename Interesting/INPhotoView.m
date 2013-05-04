//
//  INPhotoView.m
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INPhotoView.h"

#import "INObject.h"
#import "INDispatch.h"
#import "INThumbnailCache.h"

@implementation INPhotoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = NO;
        self.backgroundColor = [UIColor blackColor];
        
        self.progressImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.progressImageView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"i_progress_bg_gray"]];
        [self addSubview:self.progressImageView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.imageView];

        self.progressImageView.contentMode = self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.progressImageView.clipsToBounds = self.imageView.clipsToBounds = YES;

        self.photoFrameView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"photo_frame_m"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)]];
//        [self addSubview:self.photoFrameView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.progressImageView.frame = self.bounds;
    self.imageView.frame = self.bounds;

    self.photoFrameView.frame = CGRectInset(self.bounds, -8, -8);
}

- (void)updatePhoto:(NSDictionary*)dictionary {
    if (dictionary == self.photo) {
        return;
    }
    self.photo = dictionary;

    self.progressImageView.image = nil;
    self.progressImageView.alpha = 1;
    
    self.imageView.image = nil;
    self.imageView.alpha = 0.0;
    
    NSString *url_t = [self.photo objectForKey:@"url_n"];
    NSURL *URLt = [NSURL URLWithString:url_t];
    
    [[INThumbnailCache shared] cancelDispatch:self.previewImageRecord];
    self.previewImageRecord = [[INThumbnailCache shared] decodeImageURL:URLt forSize:self.progressImageView.frame.size priority:INDispatchPriorityHigh downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
        ZG_ASSERT_IS_MAIN_THREAD();
        self.progressImageView.image = image;
        if (image == nil) {
            NSLog(@"blah");
        }
        self.previewImageRecord = nil;
    }];
    //    return;
    NSString *urlN = [self.photo objectForKey:@"url_o"];
    NSString *url2 = [NSString stringWithFormat:@"http://www.zaggle.org/pdx/image/resize?width=2048&quality=50&image_url=%@", [urlN stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *URLN = [NSURL URLWithString:url2];
    if (urlN.length > 0) {
        [[INThumbnailCache shared] cancelDispatch:self.imageRecord];
//        self.imageRecord = [[INThumbnailCache shared] decodeImageURL:URLN forSize:self.imageView.frame.size priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
        self.imageRecord = [[INThumbnailCache shared] decodeImageURL:URLN forSize:CGSizeMake(1024, 768) priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
            ZG_ASSERT_IS_MAIN_THREAD();
            [[INThumbnailCache shared] cancelDispatch:self.previewImageRecord];
            self.previewImageRecord = nil;
            self.imageView.image = image;
            self.imageRecord = nil;
            [UIView animateWithDuration:0.3 animations:^{
                self.imageView.alpha = 1;
            }
            completion:^(BOOL finished) {
                self.progressImageView.alpha = 0;
            }];
        }];
    }
}

- (void)loadPhotoURLKey:(NSString*)key
{
    NSString *url = [self.photo objectForKey:key];
    if (url.length > 0) {
        url = [NSString stringWithFormat:@"http://www.zaggle.org/pdx/image/resize?width=2048&quality=50&image_url=%@", [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//        url = [NSString stringWithFormat:@"http://localhost:8089/pdx/image/resize?width=2048&quality=50&image_url=%@", [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@"url is %@", url);
        NSURL *URL = [NSURL URLWithString:url];
        [[INThumbnailCache shared] cancelDispatch:self.imageRecord];
        self.imageRecord = [[INThumbnailCache shared] decodeImageURL:URL forSize:CGSizeMake(800, 600) priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
            ZG_ASSERT_IS_MAIN_THREAD();
//            NSLog(@"got image %@ for URL %@", image, URL);
            [[INThumbnailCache shared] cancelDispatch:self.previewImageRecord];
            self.previewImageRecord = nil;
            self.imageRecord = nil;
            self.progressImageView.image = self.imageView.image;
            self.progressImageView.alpha = 1;
            self.imageView.alpha = 0;
            self.imageView.image = image;
            [UIView animateWithDuration:0.3 animations:^{
                self.imageView.alpha = 1;
            }
         completion:^(BOOL finished) {
             self.progressImageView.alpha = 0;
         }];
        }];
    }
    else {
        NSLog(@"nil url for key %@, id=%@", key, [self.photo objectForKey:@"id"]);
    }
}

/*
 MVP
 - retina images cached on GAE
 - scroll through retina images
 - surf through flickr tags
 - save tags JSON to disk
 - save images to disk
 - 60fps
 
 -- home screen, coverflow latest interesting and ?
 -- table-oriented search results
 -- save to "my interesting"
 -- follow a tag?
 */
@end

@implementation INPhotoGroup

+ (INPhotoGroup*)photoGroupWithPhotosArray:(NSArray*)photos
{
    return [[INPhotoGroup alloc] initWithDictionary:@{@"photos":photos}];
}

- (id)initWithDictionary:(NSDictionary*)value
{
    self = [super init];
    if (self != nil) {
        self.dictionary = value;
    }
    return self;
}

- (NSArray*)photos {
    return [self.dictionary objectForKey:@"photos"];
}

- (NSDictionary*)photoAtIndex:(NSInteger)index
{
    return [self.photos objectAtIndex:index];
}

- (NSDictionary*)selectedPhoto
{
    return [self photoAtIndex:self.selectedIndex];
}

@end

@implementation INPhotoObjectView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = NO;
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"i_progress_bg_gray"]];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)updatePhotoObject:(INPhotoObject*)photoObject
{
    self.photoObject = photoObject;
    [[INThumbnailCache shared] cancelDispatch:self.dispatchRecordThumbnail];
    [[INThumbnailCache shared] cancelDispatch:self.dispatchRecordImage];
    self.thumbnail = nil;
    self.image = nil;
    self.imageView.image = nil;
    __weak __typeof(&*self)weakSelf = self;
    NSURL *thumbnailURL = [self.photoObject.dictionary URLForKey:@"url_t"];
    self.dispatchRecordThumbnail = [[INThumbnailCache shared] decodeImageURL:thumbnailURL forSize:CGSizeMake(100,100) priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
        weakSelf.imageView.image = image;
        weakSelf.dispatchRecordThumbnail = nil;
    }];
}

- (void)layoutSubviews
{
    self.imageView.frame = self.bounds;
    if (self.image == nil && self.dispatchRecordImage == nil) {
        CGFloat length = MAX(self.frame.size.width, self.frame.size.height);
        if (length*[UIScreen mainScreen].scale > 100) {
            NSString *urlKey = @"url_n";
            if (length*[UIScreen mainScreen].scale > 640) {
                urlKey = @"url_o";
            }
            else if (length*[UIScreen mainScreen].scale > 320) {
                urlKey = @"url_z";
            }
            NSURL *URL = [self.photoObject.dictionary URLForKey:urlKey];
            __weak __typeof(&*self)weakSelf = self;
            self.dispatchRecordImage = [[INThumbnailCache shared] decodeImageURL:URL forSize:self.imageView.frame.size priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
                weakSelf.image = image;
                weakSelf.imageView.image = image;
                weakSelf.dispatchRecordImage = nil;
            }];
        }
    }
}

@end

@implementation INStackView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.stackBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"stack_frame_sm"]];
        self.stackBackgroundView.contentMode = UIViewContentModeCenter;
    }
    return self;
}

- (void)layoutSubviews
{
    if (self.photoViews.count > 0) {
        INPhotoView *photoView = [self.photoViews objectAtIndex:0];
        photoView.frame = CGRectInset(self.stackBackgroundView.frame, 12, 9);
    }
}

- (void)updateStackObject:(INStackObject*)stackObject
{
    self.stackObject = stackObject;
    self.photoViews = [NSMutableArray array];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    __weak __typeof(&*self)weakSelf = self;
    [self.stackObject.tags sectionForSectionIndex:0 completion:^(INSection *section) {
        INPhotoObject *photoObject = [section.photos objectAtIndex:0];
        INPhotoObjectView *photoObjectView = [[INPhotoObjectView alloc] initWithFrame:CGRectZero];
        [photoObjectView updatePhotoObject:photoObject];
        [weakSelf.photoViews addObject:photoObjectView];
        [weakSelf addSubview:photoObjectView];
        [weakSelf setNeedsLayout];
    }];
}

@end