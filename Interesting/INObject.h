//
//  INObject.h
//  Interesting
//
//  Created by Jesse Hammons on 5/2/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INDispatchRecord;
@class INPriorityQueue;
@class INDataSource;

@interface INPriorityQueue : NSObject

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSMutableArray *keys;

- (NSEnumerator *)keyEnumerator;
- (void)removeObjectForKey:(id)aKey;
- (void)promoteObject:(id)obj forKey:(id <NSCopying>)key;
- (id)objectForKey:(id)aKey;
- (id)objectAtIndex:(NSInteger)index;
- (id)firstObject;
- (id)removeLastObject;
- (NSUInteger)count;

@end

@interface INTagHistory : NSObject

@property (nonatomic, strong) NSMutableArray *sourcesStack;
@property (nonatomic, strong) NSMutableDictionary *viewedTags;

+ (INTagHistory*)shared;

- (void)pushStack;
- (void)popStack;
- (void)addDataSource:(INDataSource*)dataSource;
- (BOOL)hasViewedTag:(NSString*)tag;

@end

@interface INObject : NSObject

@end

@class INPhotoObject;

@protocol INPhotoObserver <NSObject>

- (void)photoObject:(INPhotoObject*)photoObject didUpdateImage:(UIImage*)image;

@end

@interface INPhotoObject : INObject

@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) NSString *priority;
@property (nonatomic, strong) INDataSource *tags;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) INDispatchRecord *dispatchRecord;
@property (nonatomic, strong) UIImage *image;

- (id)initWithDictionary:(NSDictionary*)dictionary;
- (void)changePriority:(NSString*)priority;

//- (void)addObserver:(id <INPhotoObserver>)observer;
//- (void)removeObserver:(id <INPhotoObserver>)observer;
//
////- (INDispatchRecord*)loadThumbnailCompletion:(void (^)(UIImage *))completion;
////- (INDispatchRecord*)loadImageForSize:(CGSize)imageViewSize completion:(void (^)(UIImage *))completion;
//
//- (void)loadThumbnail;
//- (void)loadImageForSize:(CGSize)imageSize;

@end

@interface INSection : NSObject

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) NSArray *tags;

- (id)initWithPhotos:(NSArray*)photos;

@end

@class INFlickrDataSource;

@interface INDataSource : NSObject

@property (nonatomic, strong) NSArray *sourceTags;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *tags;

@property (nonatomic, assign) NSInteger tagsHighWaterMark;
@property (nonatomic, assign) NSInteger photosHighWaterMark;

- (id)initWithSourceTags:(NSArray*)sourceTags;

- (void)sectionForSectionIndex:(NSInteger)sectionIndex completion:(void (^)(INSection *section))completion;

- (NSInteger)photosCount;
- (INPhotoObject*)photoAtIndex:(NSInteger)index updateHighWatermark:(BOOL)updateHighWatermark;

- (NSInteger)tagsCount;;
- (INDataSource*)tagAtIndex:(NSInteger)index updateHighWatermark:(BOOL)updateHighWatermark;
- (BOOL)needsMoreTags;

@end

@interface INFlickrDataSource : INDataSource
@end

@interface INStackObject : INObject

@property (nonatomic, strong) INDataSource *tags;
@property (nonatomic, strong) INDataSource *photos;

@end

@interface NSDictionary (INObject)

- (NSURL*)URLForKey:(id <NSCopying>)key;

@end