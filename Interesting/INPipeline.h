//
//  INPipeline.h
//  Interesting
//
//  Created by Jesse Hammons on 5/3/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INPriorityQueue;
@class AFHTTPRequestOperation;

typedef NS_ENUM(NSInteger, INPipelinePriority) {
    INPipelinePriorityInvalid = -1,
    INPipelinePriorityHigh,         // slow at beginning and end
    INPipelinePriorityDefault,            // slow at beginning
    INPipelinePriorityLow,           // slow at end
    INPipelinePriorityMAX
};

@interface INPipelineQueue : NSObject

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, readonly) NSInteger count;

- (void)removeObjectForKey:(id)aKey;
- (void)promoteObject:(id)obj forKey:(id <NSCopying>)key;
- (id)objectForKey:(id)aKey;
- (id)removeLastObject;

@end

@class INPipeline;

@interface INPipelineObject : NSObject

@property (nonatomic, weak) INPipeline *currentPipeline;
@property (nonatomic, assign) NSInteger promoteCount;
@property (nonatomic, strong) NSDate *datestamp;
@property (nonatomic, strong) NSURL *dataURL;  // dataURL -> data
@property (nonatomic, strong) NSDate *downloadBeginDate;
@property (nonatomic, strong) AFHTTPRequestOperation *httpRequest;
@property (nonatomic, strong) NSDate *downloadEndDate;
@property (nonatomic, strong) NSData *data;  // data -> UIImage (scaled) (write to disk)
@property (nonatomic, assign) BOOL isDataFromCache;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, assign) INPipelinePriority currentPriority;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL downloadIfNecessary;
@property (nonatomic, assign) BOOL useCache;

//- (void)cancelPipelineObject;
- (void)removeImageView:(UIImageView*)imageView;

@end

@interface INPipeline : NSObject

@property (nonatomic, strong) NSArray *queues;
@property (nonatomic, strong) NSMutableDictionary *activeTargets;
@property (nonatomic, assign) NSInteger maxActiveTargets;

+ (INPipelineObject*)promoteDispatchForDataURL:(NSURL *)dataURL priority:(INPipelinePriority)priority download:(BOOL)download useCache:(BOOL)useCache imageView:(UIImageView*)imageView;

- (INPipelineObject*)pipelineObjectForDataURL:(NSURL*)dataURL;
- (void)promotePiplineObject:(INPipelineObject*)pipelineObject priority:(INPipelinePriority)priority;
- (void)dispatchPipelineObject:(INPipelineObject*)pipelineObject;
- (void)cancelPipelineObject:(INPipelineObject*)pipelineObject;

@end

@interface INCPUPipeline : INPipeline

+ (INCPUPipeline*)shared;

@end

@interface INHTTPPipeline : INPipeline

@property (nonatomic, strong) NSArray *queues;

+ (INHTTPPipeline*)shared;

@end


