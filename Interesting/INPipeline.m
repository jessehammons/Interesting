//
//  INPipeline.m
//  Interesting
//
//  Created by Jesse Hammons on 5/3/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INPipeline.h"

#import "INDispatch.h"
#import "INDiskCache.h"
#import "INSingletonFactory.h"

#import "AFHTTPRequestOperation.h"

#import <AVFoundation/AVFoundation.h>

@implementation INPipelineQueue

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)removeObjectForKey:(id)aKey {
    [self.dictionary removeObjectForKey:aKey];
}

- (void)promoteObject:(id)obj forKey:(id <NSCopying>)key
{
    INPipelineObject *existing = [self.dictionary objectForKey:key];
    if (existing != nil) {
        NSAssert(existing == obj, @"these should be the same");
    }
    INPipelineObject *pipelineObject = obj;
    NSAssert(pipelineObject.datestamp != nil, @"datestamp should already be set");
    [self.dictionary setObject:pipelineObject forKey:key];
}

- (id)objectForKey:(id)aKey
{
    return [self.dictionary objectForKey:aKey];
}

- (id)removeLastObject
{
    __weak __typeof(&*self)weakSelf = self;
    NSArray *sortedKeys = [[self.dictionary allKeys] sortedArrayUsingComparator:^(id obj1, id obj2) {
        id <NSCopying> key1 = obj1;
        id <NSCopying> key2 = obj2;
        INPipelineObject *pipelineObject1 = [weakSelf.dictionary objectForKey:key1];
        INPipelineObject *pipelineObject2 = [weakSelf.dictionary objectForKey:key2];
        NSAssert(pipelineObject1.datestamp != nil && pipelineObject2.datestamp != nil, @"need both of these");
        return [pipelineObject1.datestamp compare:pipelineObject2.datestamp];
    }];
    id <NSCopying> lastKey = [sortedKeys lastObject];
    id result = [self.dictionary objectForKey:lastKey];
    [self.dictionary removeObjectForKey:lastKey];
    return result;
}

- (NSInteger)count
{
    return self.dictionary.count;
}

@end

@implementation INPipelineObject

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.currentPriority = INPipelinePriorityInvalid;
        self.imageViews = [NSMutableArray array];
    }
    return self;
}

- (void)_cancelPipelineObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    self.isCancelled = YES;
    NSAssert(self.currentPipeline != nil, @"this should not be nil");
    [self.currentPipeline cancelPipelineObject:self];
}

- (void)removeImageView:(UIImageView*)imageView
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [self.imageViews removeObject:imageView];
    if (self.imageViews.count == 0) {
        [self _cancelPipelineObject];
    }
}

@end

@implementation INPipeline

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.queues = [NSArray arrayWithObjects:
                       [[INPipelineQueue alloc] init],
                       [[INPipelineQueue alloc] init],
                       [[INPipelineQueue alloc] init],
                       nil];
        self.activeTargets = [NSMutableDictionary dictionary];
        self.maxActiveTargets = 1;
    }
    return self;
}

+ (INPipelineObject*)promoteDispatchForDataURL:(NSURL *)dataURL priority:(INPipelinePriority)priority download:(BOOL)download useCache:(BOOL)useCache imageView:(UIImageView*)imageView
{
    static NSInteger _promoteCount = 0;
    ZG_ASSERT_IS_MAIN_THREAD();

    INPipelineObject *cpuPipelineObject = [[INCPUPipeline shared] pipelineObjectForDataURL:dataURL];
    INPipelineObject *httpPipelineObject = [[INHTTPPipeline shared] pipelineObjectForDataURL:dataURL];
    NSAssert(cpuPipelineObject == nil || httpPipelineObject == nil, @"we should have only one");
    INPipelineObject *result = nil;
    if (cpuPipelineObject != nil) {
        result = cpuPipelineObject;
    }
    else if (httpPipelineObject != nil) {
        result = httpPipelineObject;
    }
    if (result == nil) {
        result = [[INPipelineObject alloc] init];
        result.dataURL = dataURL;
        result.downloadIfNecessary = download;
        result.useCache = useCache;
    }
    else {
        NSAssert(result.currentPriority != INPipelinePriorityInvalid, @"this should be valid");
    }
    if (imageView != nil) {
        [result.imageViews addObject:imageView];
    }
    result.datestamp = [NSDate date];
    result.promoteCount = _promoteCount++;
    if (result.currentPipeline == nil) {
        if ([[INDiskCache shared] hasDataForKey:dataURL.absoluteString] && imageView != nil && result.useCache) {
            [[INCPUPipeline shared] promotePiplineObject:result priority:priority];
        }
        else if (download) {
            [[INHTTPPipeline shared] promotePiplineObject:result priority:priority];
        }
    }
    else {
        [result.currentPipeline promotePiplineObject:result priority:priority];
    }
    return result;
}

- (void)promotePiplineObject:(INPipelineObject*)pipelineObject priority:(INPipelinePriority)priority
{
    ZG_ASSERT_IS_MAIN_THREAD();
    INPipelineObject *existing = nil;
    for(NSInteger i = 0; i < INPipelinePriorityMAX; i++) {
        INPipelineQueue *queue = [self.queues objectAtIndex:i];
        INPipelineObject *obj = [queue objectForKey:pipelineObject.dataURL];
        if (obj != nil) {
            NSAssert(existing == nil, @"should have only one");
            existing = obj;
            NSAssert(existing == pipelineObject, @"should be the same object");
            NSAssert(existing.currentPriority == i, @"this should match");
            NSAssert(existing.currentPipeline == self, @"this should be us");
            if (priority < existing.currentPriority) {
                existing.currentPriority = priority;
                [queue removeObjectForKey:pipelineObject.dataURL];
                INPipelineQueue *newQueue = [self.queues objectAtIndex:priority];
                [newQueue promoteObject:pipelineObject forKey:pipelineObject.dataURL];
            }
        }
    }
    if (existing == nil && [self.activeTargets objectForKey:pipelineObject.dataURL] == nil) {
        NSAssert(pipelineObject.currentPriority == INPipelinePriorityInvalid, @"should be invalid");
        NSAssert(pipelineObject.currentPipeline == nil, @"should be nil");
        pipelineObject.currentPipeline = self;
        pipelineObject.currentPriority = priority;
        INPipelineQueue *newQueue = [self.queues objectAtIndex:priority];
        [newQueue promoteObject:pipelineObject forKey:pipelineObject.dataURL];
    }
    [self dispatchOneIfNecessary];
}

// return if we have pipeline object at any priority

- (INPipelineObject*)pipelineObjectForDataURL:(NSURL*)dataURL
{
    ZG_ASSERT_IS_MAIN_THREAD();
    INPipelineObject *result = nil;
    for(INPipelineQueue *queue in self.queues) {
        INPipelineObject *obj = [queue objectForKey:dataURL];
        if (obj != nil) {
            NSAssert(result == nil, @"we should have only one");
            result = obj;
        }
    }
    INPipelineObject *obj = [self.activeTargets objectForKey:dataURL];
    if (obj != nil) {
        NSAssert(result == nil, @"this should be nil");
        result = obj;
    }
    return result;
}

- (void)dispatchOneIfNecessary
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_dispatchOneIfNecessary) withObject:nil afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

- (void)_dispatchOneIfNecessary
{
    ZG_ASSERT_IS_MAIN_THREAD();
    if (self.activeTargets.count < self.maxActiveTargets) {
        for(NSInteger i = 0; i < INPipelinePriorityMAX; i++) {
            INPipelineQueue *queue = [self.queues objectAtIndex:i];
            if (queue.count > 0) {
                INPipelineObject *pipelineObject = [queue removeLastObject];
                [self.activeTargets setObject:pipelineObject forKey:pipelineObject.dataURL];
                [self dispatchPipelineObject:pipelineObject];
                break;
            }
        }
    }
}

- (void)dispatchPipelineObject:(INPipelineObject*)pipelineObject
{
    NSAssert(NO, @"subclasses must override");
}

/* to be used by subclasses */
- (void)_cancelPipelineObject:(INPipelineObject*)pipelineObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    for(INPipelineQueue *queue in self.queues) {
        [queue removeObjectForKey:pipelineObject.dataURL];
    }
    [self.activeTargets removeObjectForKey:pipelineObject.dataURL];
    [self dispatchOneIfNecessary];
}

- (void)cancelPipelineObject:(INPipelineObject*)pipelineObject
{
    NSAssert(NO, @"subclasses must override");
}

@end

@implementation INCPUPipeline

+ (INCPUPipeline*)shared
{
    return [[INSingletonFactory shared] singletonForClass:[self class]];
}

- (void)cancelPipelineObject:(INPipelineObject*)pipelineObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    /* nothing to do, release on isCancelled property at end of execution */
    [super _cancelPipelineObject:pipelineObject];
}

- (void)dispatchPipelineObject:(INPipelineObject*)pipelineObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    if (pipelineObject.isCancelled) {
        [self dispatchOneIfNecessary];
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    [[INBlockDispatch shared] dispatchBackground:^{
        if (pipelineObject.isCancelled == NO) {
            NSAssert(pipelineObject.currentPipeline == self, @"this should be us");
            NSAssert(pipelineObject.datestamp != nil, @"should not be nil");
            NSAssert(pipelineObject.dataURL != nil, @"we need this");
            NSAssert(pipelineObject.httpRequest == nil, @"this should be nil");
            NSAssert(pipelineObject.image == nil, @"this should be nil");
            NSAssert(pipelineObject.imageViews.count > 0, @"we should have observers");

            if (pipelineObject.data == nil && pipelineObject.useCache) {
                pipelineObject.data = [[INDiskCache shared] dataForKey:pipelineObject.dataURL.absoluteString];
                pipelineObject.isDataFromCache = YES;
            }
            UIImage *image = [UIImage imageWithData:pipelineObject.data scale:[UIScreen mainScreen].scale];
            // to avoid enumerating .imageViews while it is modified on another thread */
            [[INBlockDispatch shared] dispatchMain:^{
                for(UIImageView *imageView in pipelineObject.imageViews) {
                    [[INBlockDispatch shared] dispatchBackground:^{
                        NSAssert(CGSizeEqualToSize(imageView.frame.size, CGSizeZero) == NO, @"size must be non-zero");
                        imageView.backgroundColor = [UIColor lightGrayColor];
                        CGSize size = imageView.frame.size;
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
                            if (pipelineObject.isCancelled == NO) {
                                NSDate *start = [NSDate date];
                                imageView.image = newImage;
                                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
                                if (duration > 1.0/30) {
                                    NSLog(@"way too long %@, %@", imageView, pipelineObject.dataURL);
                                }
                                UILabel *label = (id)[imageView viewWithTag:99];
                                NSInteger milliseconds = duration*1000;
                                NSInteger downloadMilliseconds = 0;
                                if (pipelineObject.downloadBeginDate != nil && pipelineObject.downloadEndDate) {
                                    downloadMilliseconds = [pipelineObject.downloadEndDate timeIntervalSinceDate:pipelineObject.downloadBeginDate]*1000;
                                }
                                label.text = [NSString stringWithFormat:@"uc=%d, dl=%d, d=%dms, ch=%d, #=%d, w=%d", pipelineObject.useCache, downloadMilliseconds, milliseconds, pipelineObject.isDataFromCache, pipelineObject.promoteCount, (int)image.size.width];
                                if (newImage == nil) {
                                    imageView.backgroundColor = [UIColor purpleColor];
                                }
                            }
                            [weakSelf.activeTargets removeObjectForKey:pipelineObject.dataURL];
                            [self dispatchOneIfNecessary];
                        }];
                    }];
                }
            }];
        }
        else {
            [[INBlockDispatch shared] dispatchMain:^{
                [self dispatchOneIfNecessary];
            }];
        }
    }];
}

@end

@implementation INHTTPPipeline

+ (INHTTPPipeline*)shared
{
    return [[INSingletonFactory shared] singletonForClass:[self class]];
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.maxActiveTargets = 3;
    }
    return self;
}


- (void)cancelPipelineObject:(INPipelineObject*)pipelineObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [super _cancelPipelineObject:pipelineObject];
    [pipelineObject.httpRequest cancel];
}

- (void)_finishDispatch:(INPipelineObject*)pipelineObject
{
    ZG_ASSERT_IS_BACKGROUND_THREAD();
//    NSLog(@"FINISH bytes=%d, %@", pipelineObject.data.length, [pipelineObject.httpRequest.request.URL lastPathComponent]);

    [[INBlockDispatch shared] dispatchMain:^{
        if (pipelineObject.isCancelled == NO) {
            pipelineObject.downloadEndDate = [NSDate date];
            pipelineObject.httpRequest = nil;
            /* transfer ownership */
            pipelineObject.currentPipeline = nil;
            INPipelinePriority currentPriority = pipelineObject.currentPriority;
            pipelineObject.currentPriority = INPipelinePriorityInvalid;
            [[INCPUPipeline shared] promotePiplineObject:pipelineObject priority:currentPriority];
            [self.activeTargets removeObjectForKey:pipelineObject.dataURL];
        }
        [self dispatchOneIfNecessary];
    }];
    if (pipelineObject.useCache && pipelineObject.data.length > 0) {
        [[INDiskCache shared] setData:pipelineObject.data forKey:pipelineObject.dataURL.absoluteString];
    }
}

- (void)dispatchPipelineObject:(INPipelineObject*)pipelineObject
{
    ZG_ASSERT_IS_MAIN_THREAD();
    [[INBlockDispatch shared] dispatchBackground:^{
        if (pipelineObject.isCancelled == NO) {
            NSAssert(pipelineObject.currentPipeline == self, @"this should be us");
            NSAssert(pipelineObject.datestamp != nil, @"should not be nil");
            NSAssert(pipelineObject.dataURL != nil, @"we need this");
            NSAssert(pipelineObject.httpRequest == nil, @"this should be nil");
            NSAssert(pipelineObject.data == nil, @"this should be nil");
            NSAssert(pipelineObject.image == nil, @"this should be nil");
            NSAssert(pipelineObject.imageViews.count > 0, @"we should have observers");
            __weak __typeof(&*self)weakSelf = self;
            //    NSLog(@"promote URL: %@", [URL lastPathComponent]);
            // NSURLCache is janky http://stackoverflow.com/questions/7166422/nsurlconnection-on-ios-doesnt-try-to-cache-objects-larger-than-50kb
    //        NSURLRequest *request = [NSURLRequest requestWithURL:pipelineObject.dataURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
            //2013-05-04 00:15:41.792 Interesting[14349:4107] ADDRESPONSE - ADDING TO MEMORY ONLY: http://farm3.staticflickr.com/2476/3578775702_9e179bee58_t.jpg
            NSURLRequest *request = [NSURLRequest requestWithURL:pipelineObject.dataURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];        
            AFHTTPRequestOperation *httpRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            [httpRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                ZG_ASSERT_IS_BACKGROUND_THREAD();
                pipelineObject.data = (NSData*)responseObject;
                [weakSelf _finishDispatch:pipelineObject];
            }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                ZG_ASSERT_IS_BACKGROUND_THREAD();
               NSAssert(pipelineObject.data == nil, @"this should be nil");
                [weakSelf _finishDispatch:pipelineObject];
            }];
            pipelineObject.httpRequest = httpRequest;
            httpRequest.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            httpRequest.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            pipelineObject.downloadBeginDate = [NSDate date];
            [httpRequest start];
    //        NSLog(@"START %@", [httpRequest.request.URL lastPathComponent]);
        }
        else {
            [[INBlockDispatch shared] dispatchMain:^{
                [self dispatchOneIfNecessary];
            }];
        }
    }];
}

@end