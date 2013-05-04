//
//  INThumbnailCache.h
//  Interesting
//
//  Created by Jesse Hammons on 4/22/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INDispatchRecord;

@interface INThumbnailCache : NSObject <NSCacheDelegate>

@property (nonatomic, strong) NSCache *cache;

+ (INThumbnailCache*)shared;

- (INDispatchRecord*)decodeImageURL:(NSURL*)imageURL forSize:(CGSize)size priority:(NSString*)priority downloadIfNecessary:(BOOL)download cacheData:(BOOL)cacheData completion:(void (^)(UIImage *image))completion;
- (void)preprocessPhotos:(NSArray *)photos URLKeys:(NSArray*)urlKeys;
- (void)cancelDispatch:(INDispatchRecord*)record;

- (UIImage*)synchronouslyDecodeImageData:(NSData*)imageData forSize:(CGSize)size;

@end