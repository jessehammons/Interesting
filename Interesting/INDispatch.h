//
//  INDispatch.h
//  Interesting
//
//  Created by Jesse Hammons on 4/25/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INPriorityQueue;

@interface INDispatchRecord : NSObject

@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, strong) id <NSCopying> prioritizationKey;
@property (nonatomic, strong) id inputObject;
@property (nonatomic, copy) id (^computationBlock)(id inputObject);
@property (nonatomic, copy) void (^completionBlock)(id result);

@end

//@class INImageDispatch;
//
//@interface INImageLoader : NSObject
//
//@property (nonatomic, strong) NSURL *imageURL;
//@property (nonatomic, copy) UIImage *(^decodeBlock)(NSData *data);
//@property (nonatomic, copy) void (^completionBlock)(UIImage *image);
//
//@property (nonatomic, weak) INImageDispatch *dispatcher;
//@property (nonatomic, assign) BOOL isCancelled;
//
//- (void)cancelLoading;
//
//@end
//
//@interface INImageDispatch : NSObject
//
////@property (nonatomic, strong) INPriorityQueue *pendingTargets;
//@property (nonatomic, strong) NSDictionary *priorityQueues;
//@property (nonatomic, strong) NSArray *priorityKeys;
//@property (nonatomic, strong) NSMutableDictionary *activeTargets;
//@property (nonatomic, assign) NSInteger maxActiveTargets;
//
//+ (INImageDispatch*)shared;
//
//- (INImageLoader*)loadImageURL:(NSURL *)imageURL priority:(NSString*)priority decode:(UIImage * (^)(NSData *data))decode completion:(void (^)(UIImage *image))completion;
//
//- (INDispatchRecord*)dispatchRecordForKey:(id <NSCopying>)key;
//- (void)removeDispatchForKey:(id <NSCopying>)key;
//- (void)dispatchOneIfNecessary;
//- (void)cancelDispatch:(INDispatchRecord*)record;
//
//@end

@interface INDispatch : NSObject

//@property (nonatomic, strong) INPriorityQueue *pendingTargets;
@property (nonatomic, strong) NSDictionary *priorityQueues;
@property (nonatomic, strong) NSArray *priorityKeys;
@property (nonatomic, strong) NSMutableDictionary *activeTargets;
@property (nonatomic, assign) NSInteger maxActiveTargets;

+ (INDispatch*)shared;

- (INDispatchRecord*)promoteDispatchForKey:(id <NSCopying>)prioritizationKey inputObject:(id)inputObject computation:(id (^)(id inputObject))computation completion:(void (^)(id result))completion;
- (INDispatchRecord*)promoteDispatchForKey:(id <NSCopying>)prioritizationKey priority:(NSString*)priority inputObject:(id)inputObject computation:(id (^)(id inputObject))computation completion:(void (^)(id result))completion;
- (INDispatchRecord*)dispatchRecordForKey:(id <NSCopying>)key;
- (void)removeDispatchForKey:(id <NSCopying>)key;
- (void)dispatchOneIfNecessary;
- (void)cancelDispatch:(INDispatchRecord*)record;

@end

extern NSString *INDispatchPriorityHigh;
extern NSString *INDispatchPriorityDefault;
extern NSString *INDispatchPriorityLow;

@interface INCPUDispatch : INDispatch

+ (INCPUDispatch*)shared;

@end

@interface INHTTPDispatch : INDispatch

+ (INHTTPDispatch*)shared;

- (INDispatchRecord*)promoteDownloadForURL:(NSURL*)URL priority:(NSString*)priority completion:(void (^)(NSData *data, NSError *error))completion;

@end

@interface INBlockDispatch : NSObject

+ (INBlockDispatch*)shared;

- (void)dispatchMain:(void (^)())block;
- (void)dispatchBackground:(void (^)())block;

@end