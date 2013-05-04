//
//  INThumbnailCache.m
//  Interesting
//
//  Created by Jesse Hammons on 4/22/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "INThumbnailCache.h"

#import "INDispatch.h"
#import "INDiskCache.h"
#import "AFHTTPRequestOperation.h"

@interface UIImage (Resize)

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end

@implementation INThumbnailCache

- (id)init {
    self = [super init];
    if (self != nil) {
        self.cache = [[NSCache alloc] init];
        self.cache.delegate = self;
//        [self.cache setTotalCostLimit:50*1024];
        [self.cache setTotalCostLimit:30*1024*1024];
    }
    return self;
}

+ (INThumbnailCache*)shared {
    static INThumbnailCache *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
    return singleton;
}

- (void)cancelDispatch:(INDispatchRecord*)record
{
    if ([record.inputObject class] == [AFHTTPRequestOperation class]) {
        [[INHTTPDispatch shared] cancelDispatch:record];
    }
    else {
        [[INCPUDispatch shared] cancelDispatch:record];
    }
}

- (UIImage*)synchronouslyDecodeImageData:(NSData*)imageData forSize:(CGSize)size
{
    ZG_ASSERT_IS_BACKGROUND_THREAD();
    UIImage *newImage = nil;
    if (CGSizeEqualToSize(size, CGSizeZero) == NO) {
        UIImage *image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        if (image.size.width < 200 || CGSizeEqualToSize(size, image.size)) {
            return image;
        }
        CGRect newRect = AVMakeRectWithAspectRatioInsideRect(image.size, size.width > size.height ? CGRectMake(0, 0, 20000, size.height) : CGRectMake(0, 0, size.width, 20000));
        newImage = [UIImage imageWithImage:image scaledToSize:newRect.size];
    }
    return newImage;
}

- (INDispatchRecord*)decodeImageData:(NSData*)imageData forSize:(CGSize)size prioritizsationKey:(id <NSCopying>)key completion:(void (^)(UIImage *image))completion
{
    INDispatchRecord *result = nil;
    ZG_ASSERT_IS_MAIN_THREAD();
//    if (completion != NULL) {
//        UIImage *image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
//        completion(image);
//    }
//    return;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return nil;
    }
    if (imageData != nil && completion != NULL) {
        __weak __typeof(&*self)weakSelf = self;
        result = [[INCPUDispatch shared] promoteDispatchForKey:key inputObject:imageData
        computation:^(id inputObject) {
            ZG_ASSERT_IS_BACKGROUND_THREAD();
            return [weakSelf synchronouslyDecodeImageData:imageData forSize:size];
        }
        completion:^(id result) {
            ZG_ASSERT_IS_MAIN_THREAD();
            UIImage *image = (UIImage*)result;
            completion(image);
        }];
    }
    return result;
}

- (INDispatchRecord*)decodeImageURL:(NSURL*)imageURL forSize:(CGSize)size priority:(NSString*)priority downloadIfNecessary:(BOOL)download cacheData:(BOOL)cacheData completion:(void (^)(UIImage *image))completion
{
    ZG_ASSERT_IS_MAIN_THREAD();
    __weak __typeof(&*self)weakSelf = self;
    INDispatchRecord *dispatchRecord = nil;
    if ([[INDiskCache shared] hasDataForKey:imageURL.absoluteString] && completion != NULL && cacheData == YES) {
//        NSLog(@"cached dispatch %@ %@", [imageURL lastPathComponent], priority);
        dispatchRecord = [[INCPUDispatch shared] promoteDispatchForKey:imageURL priority:priority inputObject:imageURL
           computation:^(id inputObject) {
               UIImage *image = nil;
               ZG_ASSERT_IS_BACKGROUND_THREAD();
               NSData *imageData = [[INDiskCache shared] dataForKey:imageURL.absoluteString];
               if (imageData != nil) {
                   image = [weakSelf synchronouslyDecodeImageData:imageData forSize:size];
               }
               if (image == nil) {
                   NSLog(@"blah");
               }
               return image;
           }
            completion:^(id result) {
                ZG_ASSERT_IS_MAIN_THREAD();
//                NSLog(@"cached decode %@ %@", [imageURL lastPathComponent], priority);
                UIImage *image = result;
                completion(image);
            }];
    }
    else if (download == YES) {

//        NSLog(@"download %@", [imageURL lastPathComponent]);
        dispatchRecord = [[INHTTPDispatch shared] promoteDownloadForURL:imageURL priority:priority completion:^(NSData *data, NSError *error) {
            ZG_ASSERT_IS_BACKGROUND_THREAD();
            if (error == nil && data.length > 0) {
                /* decode first, before caching to disk */
                if (completion != NULL) {
                    UIImage *image = [weakSelf synchronouslyDecodeImageData:data forSize:size];
//                    NSLog(@"web decode %@ %@", [imageURL lastPathComponent], priority);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(image);
                    });
                }
                if (cacheData == YES) {
//                    NSLog(@"web store cache %@ %@", [imageURL lastPathComponent], priority);
                    [[INDiskCache shared] setData:data forKey:imageURL.absoluteString];
                }
            }
            else {
//                NSLog(@"FAIL data=%d bytes %@, error=%d", data != nil, imageURL, error.code);
            }
        }];
    }
    return dispatchRecord;
}

- (void)preprocessPhotos:(NSArray *)photos URLKeys:(NSArray*)urlKeys
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [[INBlockDispatch shared] dispatchBackground:^{
        for(NSDictionary *photo in photos) {
            for(NSString *urlKey in urlKeys) {
                NSString *url = [photo objectForKey:urlKey];
                if (url != nil) {
                    NSURL *URL = [NSURL URLWithString:url];
                    BOOL hasData = [[INDiskCache shared] hasDataForKey:URL.absoluteString];
                    if (hasData == NO) {
                        [[INBlockDispatch shared] dispatchMain:^{
                            if ([[INCPUDispatch shared] dispatchRecordForKey:URL] == nil && [[INHTTPDispatch shared] dispatchRecordForKey:URL] == nil) {
                                [self decodeImageURL:URL forSize:CGSizeZero priority:INDispatchPriorityLow downloadIfNecessary:YES cacheData:YES completion:NULL];
                            }
                        }];
                    }
                }
            }
        }
    }];
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
//    NSData *data = obj;
//    NSLog(@"EVICTING DATA=%d bytes", data.length);
}

@end
