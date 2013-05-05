//
//  INPhotoView.m
//  Interesting
//
//  Created by Jesse Hammons on 4/28/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "INPhotoView.h"

#import "INObject.h"
#import "INDispatch.h"
#import "INThumbnailCache.h"
#import "INPipeline.h"

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
//        NSLog(@"url is %@", url);
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
//        self.backgroundColor = [UIColor colorWithPatternImage:[[UIImage imageNamed:@"i_progress_bg_gray"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch]];
        self.backgroundColor = [UIColor clearColor];
        
        self.visibleImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.visibleImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.visibleImageView.clipsToBounds = YES;
        [self addSubview:self.visibleImageView];
        
        self.fadingImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.fadingImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.fadingImageView.clipsToBounds = YES;
        [self addSubview:self.fadingImageView];
    }
    return self;
}


- (void)loadMediaWithPriority:(NSInteger)priority
{
}


- (void)updatePhotoObject:(INPhotoObject*)photoObject loadImageURLKeys:(NSArray*)imageURLKeys
{
    self.photoObject = photoObject;
    self.imageURLKeys = imageURLKeys;
    
    for(INPipelineObject *pipelineObject in self.pipelineObjects) {
        [pipelineObject cancelPipelineObject];
    }
    self.visibleImageView.alpha = 1;
    self.visibleImageView.image = [UIImage imageNamed:@"i_progress_bg_gray"];
    self.fadingImageView.alpha = 0;
    self.fadingImageView.image = nil;
    __weak __typeof(&*self)weakSelf = self;

    NSMutableArray *pipelines = [NSMutableArray array];
    for(NSString *key in self.imageURLKeys) {
        NSURL *URL = [self.photoObject.dictionary URLForKey:key];
        if (URL != nil) {
            INPipelinePriority priority = INPipelinePriorityDefault;
            if ([key isEqualToString:@"url_n"]) {
                priority = INPipelinePriorityHigh;
            }
            INPipelineObject *pipelineObject = [INPipeline promoteDispatchForDataURL:URL priority:priority download:YES useCache:YES imageView:nil decodeBlock:^(INPipelineObject *pipelineObject) {
                if (pipelineObject.isCancelled) {
                    return;
                }
                UIImage *image = [UIImage imageWithData:pipelineObject.data scale:[UIScreen mainScreen].scale];
                NSAssert(CGSizeEqualToSize(weakSelf.fadingImageView.frame.size, CGSizeZero) == NO, @"size must be non-zero");
                CGSize size = weakSelf.fadingImageView.frame.size;
                UIImage *newImage = image;
                if (image.size.width > 200 || CGSizeEqualToSize(size, image.size) == NO) {
                    CGRect newRect = AVMakeRectWithAspectRatioInsideRect(image.size, size.width > size.height ? CGRectMake(0, 0, 20000, size.height) : CGRectMake(0, 0, size.width, 20000));
                    CGSize newSize = newRect.size;
                    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
                    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
                    newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                [[INBlockDispatch shared] dispatchMain:^{
                    if (pipelineObject.isCancelled) {
                        return;
                    }
                    weakSelf.fadingImageView.image = newImage;
                    [UIView animateWithDuration:0.3 animations:^{
                        weakSelf.fadingImageView.alpha = 1;
                    }completion:^(BOOL finished) {
                        if (finished) {
                            weakSelf.visibleImageView.image = newImage;
                            weakSelf.fadingImageView.alpha = 0;
                        }
                    }];
                    NSInteger index = [weakSelf.pipelineObjects indexOfObject:pipelineObject];
                    NSAssert(index != NSNotFound, @"should be found");
                    for(NSInteger i = 0; i < index; i++) {
//                        NSLog(@"%@ loaded %d, cancel %d", [weakSelf class], index, i);
                        [[weakSelf.pipelineObjects objectAtIndex:i] cancelPipelineObject];
                    }
                }];
            }];
            [pipelines addObject:pipelineObject];
        }
    }
    self.pipelineObjects = pipelines;
}

- (void)layoutSubviews
{
    self.visibleImageView.frame = self.bounds;
    self.fadingImageView.frame = self.bounds;
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
        [photoObjectView updatePhotoObject:photoObject loadImageURLKeys:@[@"url_t"]];
        [weakSelf.photoViews addObject:photoObjectView];
        [weakSelf addSubview:photoObjectView];
        [weakSelf setNeedsLayout];
    }];
}

@end