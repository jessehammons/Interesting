//
//  INObject.m
//  Interesting
//
//  Created by Jesse Hammons on 5/2/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INObject.h"

#import "INDispatch.h"
#include "INFlickrAPI.h"
#import "INThumbnailCache.h"

@implementation INObject

@end

@implementation INPriorityQueue

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        self.dictionary   = [NSMutableDictionary dictionary];
        self.keys = [NSMutableArray array];
    }
    return self;
}

- (void)promoteObject:(id)obj forKey:(id <NSCopying>)key
{
    ZG_ASSERT_IS_MAIN_THREAD();
    id existing = [self.dictionary objectForKey:key];
    if (existing != nil) {
        NSAssert(existing == obj, @"collision");
    }
    [self.dictionary setObject:obj forKey:key];
    [self.keys removeObject:key];
    [self.keys addObject:key];
}

- (id)removeLastObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    id lastKey = [self.keys lastObject];
    id lastObject = [self.dictionary objectForKey:lastKey];
    [self.dictionary removeObjectForKey:lastKey];
    [self.keys removeLastObject];
    return lastObject;
}

- (void)removeObjectForKey:(id)key
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [self.dictionary removeObjectForKey:key];
    [self.keys removeObject:key];
}

- (id)firstObject
{
    id result = nil;
    if (self.keys.count > 0) {
        id key = [self.keys objectAtIndex:0];
        result = [self.dictionary objectForKey:key];
    }
    return result;
}

- (NSUInteger)count
{
    ZG_ASSERT_IS_MAIN_THREAD();
    return self.keys.count;
}

- (id)objectForKey:(id)key
{
    ZG_ASSERT_IS_MAIN_THREAD();
    return [self.dictionary objectForKey:key];
}

- (id)objectAtIndex:(NSInteger)index
{
    ZG_ASSERT_IS_MAIN_THREAD();
    id key = [self.keys objectAtIndex:0];
    return [self.dictionary objectForKey:key];
}

- (NSEnumerator *)keyEnumerator
{
    ZG_ASSERT_IS_MAIN_THREAD();
    return [self.keys objectEnumerator];
}

@end

@implementation INTagHistory

- (id)init {
    self = [super init];
    if (self != nil) {
        self.sourcesStack = [NSMutableArray array];
        self.viewedTags = [NSMutableDictionary dictionary];
        [self pushStack];
    }
    return self;
}
+ (INTagHistory*)shared {
    static INTagHistory *singleton = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        singleton = [[[self class] alloc] init];
    });
    return singleton;
}

- (void)pushStack
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [self.sourcesStack addObject:[NSMutableArray array]];
}

- (void)popStack
{
    ZG_ASSERT_IS_MAIN_THREAD();
    NSArray *sources = [self.sourcesStack lastObject];
    for(INDataSource *dataSource in sources) {
        for(NSString *tag in dataSource.sourceTags) {
            [self.viewedTags removeObjectForKey:tag];
        };
    }
    [self.sourcesStack removeLastObject];
}

- (void)addDataSource:(INDataSource*)dataSource
{
    ZG_ASSERT_IS_MAIN_THREAD();
    for(NSString *tag in dataSource.sourceTags) {
        [self.viewedTags setObject:dataSource forKey:tag];
    };
}

- (BOOL)hasViewedTag:(NSString*)tag
{
    return [self.viewedTags objectForKey:tag] != nil;
}

@end

@implementation NSDictionary (INObject)

- (NSURL*)URLForKey:(id <NSCopying>)key
{
    NSURL *URL = nil;
    NSString *url = [self objectForKey:key];
    if (url != nil) {
        if ([url class] == [NSURL class]) {
            URL = (NSURL*)url;
        }
        else {
            URL = [NSURL URLWithString:url];
        }
    }
    return URL;
}

@end

@implementation INPhotoObject

- (id)initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    if (self != nil) {
        self.dictionary = dictionary;
        self.priority = INDispatchPriorityDefault;
        self.observers = [NSMutableArray array];
    }
    return self;
}

- (void)changePriority:(NSString *)priority
{
    self.priority = priority;
}

//- (void)addObserver:(id<INPhotoObserver>)observer
//{
//    ZG_ASSERT_IS_MAIN_THREAD();
//    [self.observers addObject:observer];
//    [[INBlockDispatch shared] dispatchBackground:^{
//        [observer photoObject:self didUpdateImage:self.image];
//    }];
//}
//
//- (void)removeObserver:(id<INPhotoObserver>)observer
//{
//    [self.observers removeObject:observer];
//    if (self.observers.count == 0) {
//    }
//}
//
//- (void)loadImageKey:(NSString*)key
//{
//    ZG_ASSERT_IS_MAIN_THREAD();
//    NSURL *thumbnailURL = [self.dictionary URLForKey:key];
//    if (thumbnailURL != nil && self.dispatchRecord == nil) {
//        __weak __typeof(&*self)weakSelf = self;
//        self.dispatchRecord = [[INThumbnailCache shared] decodeImageURL:thumbnailURL forSize:CGSizeMake(100, 100) priority:INDispatchPriorityHigh downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
//            ZG_ASSERT_IS_BACKGROUND_THREAD();
//            self.image = image;
//            for(id <INPhotoObserver> observer in self.observers) {
//                [observer photoObject:weakSelf didUpdateImage:image];
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.dispatchRecord = nil;
//            });
//        }];
//    }
//}
//
//- (void)loadThumbnail
//{
//    [self loadImageKey:@"url_t"];
//}
//
//- (void)loadImageForSize:(CGSize)imageSize
//{
//    CGFloat length = MAX(imageSize.width, imageSize.height);
//    NSString *key = @"url_t";
//    if (length*[UIScreen mainScreen].scale > 640) {
//        key = @"url_o";
//    }
//    else if (length*[UIScreen mainScreen].scale > 320) {
//        key = @"url_z";
//    }
//    else if (length > 100) {
//        key = @"url_n";
//    }
//    [self loadImageKey:key];
//}

@end

@implementation INSection

- (id)initWithPhotos:(NSArray*)photos
{
    self = [super init];
    if (self != nil) {
        NSMutableArray *tagsArray = [NSMutableArray array];
        NSMutableArray *photosArray = [NSMutableArray array];
        for(NSDictionary *photo in [photos reverseObjectEnumerator]) {
            NSString *photoID = [photo objectForKey:@"id"];
            if (photoID.length > 0) {
                INPhotoObject *photoObject = [[INPhotoObject alloc] initWithDictionary:photo];
                [photosArray addObject:photoObject];
            }
            NSArray *tags = [[photo objectForKey:@"tags"] componentsSeparatedByString:@" "];
            for(NSString *tag in tags) {
                if ([[INTagHistory shared] hasViewedTag:tag] == NO) {
                    INFlickrDataSource *src = [[INFlickrDataSource alloc] initWithSourceTags:@[tag]];
                    [tagsArray addObject:src];
                }
            }
        }
        self.tags = tagsArray;
        self.photos = photosArray;
    }
    return self;
}

@end

@implementation INDataSource

- (id)initWithSourceTags:(NSArray*)sourceTags
{
    self = [super init];
    if (self != nil) {
        NSAssert(sourceTags && sourceTags.count > 0, @"required");
        self.sourceTags = sourceTags;
        self.sections = [NSMutableArray array];
        self.photos = [NSMutableArray array];
        self.tags = [NSMutableArray array];
    }
    return self;
}

- (void)sectionForSectionIndex:(NSInteger)sectionIndex completion:(void (^)(INSection *section))completion
{

}

- (NSInteger)photosCount
{
    return self.photos.count;
}
- (INPhotoObject*)photoAtIndex:(NSInteger)index updateHighWatermark:(BOOL)updateHighWatermark
{
    INPhotoObject *result = nil;
    if (index < self.photos.count) {
        result = [self.photos objectAtIndex:index];
    }
    if (updateHighWatermark) {
        self.photosHighWaterMark = MAX(self.photosHighWaterMark, index);
    }
    return result;
}

- (NSInteger)tagsCount
{
    return self.tags.count;
}

- (INDataSource*)tagAtIndex:(NSInteger)index updateHighWatermark:(BOOL)updateHighWatermark
{
    INDataSource *result = nil;
    if (index < self.tags.count) {
        result = [self.tags objectAtIndex:index];
    }
    if (updateHighWatermark) {
        self.tagsHighWaterMark = MAX(self.tagsHighWaterMark, index);
    }
    return result;
}

- (BOOL)needsMoreTags
{
    return self.tagsHighWaterMark + 10 >= self.tags.count;
}

@end

@implementation INFlickrDataSource

- (id)initWithSourceTags:(NSArray*)sourceTags
{
    self = [super initWithSourceTags:sourceTags];
    if (self != nil) {
    }
    return self;
}

- (void)sectionForSectionIndex:(NSInteger)sectionIndex completion:(void (^)(INSection *section))completion
{
    [[INFlickrAPI shared] interestingPhotosForTags:self.sourceTags section:sectionIndex filterPredicate:nil completion:^(NSArray *photos, NSError *error)
    {
        ZG_ASSERT_IS_BACKGROUND_THREAD();
        if (error != nil) {
            NSLog(@"warning %@", error);
        }
        else {
            if (photos == nil) {
                photos = [NSArray array];
            }
        }
        INSection *section = [[INSection alloc] initWithPhotos:photos];
//        [self.sections insertObject:section atIndex:0];
        [self.sections addObject:section];
        [self.photos addObjectsFromArray:section.photos];
        [self.tags addObjectsFromArray:section.tags];
        completion(section);
    }];
}


@end
