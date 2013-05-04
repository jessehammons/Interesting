//
//  INDispatch.m
//  Interesting
//
//  Created by Jesse Hammons on 4/25/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INDispatch.h"

#import "INObject.h"

#import "AFHTTPRequestOperation.h"

 //red flash bg timer
#import "INAppDelegate.h"
#import "INViewController.h"


@interface INPrioritizedActiveSet : NSObject

@property (nonatomic, strong) INPriorityQueue *queue;
@property (nonatomic, strong) NSMutableArray *active;
@property (nonatomic, assign) NSInteger maxActive;

/*
- (BOOL)isActive {
    return self.active.count > 0;
}
- (BOOL)populateActive {
    NSMutableArray *result = [NSMutableArray array];
    while(active.count < self.maxActive && self.queue.count > 0) {
        id obj = [self.queue removeLastObject];
        [active addObject:obj];
        [obj startDispatchOperation];
    }
}
- (void)deactivateObjects {
 while(active.count > 0) {
    id obj = [self.active lastObject];
    [obj cancelDispatchOperation];
    [self.queue promoteObject:obj forKey:obj.prioritizationKey];
 }
}
*/
@end

@protocol INDispatchQueueObject <NSObject>

@property (nonatomic, readonly) id <NSCopying> prioritizationKey;
- (void)cancelDispatchOperation;

@end

@interface INDispatchQueue : NSObject

@property (nonatomic, strong) NSArray *priorityKeys;
@property (nonatomic, strong) NSDictionary *pendingQueues;
@property (nonatomic, strong) NSDictionary *activeRecords;
@property (nonatomic, assign) NSInteger maxActivePerQueue; 
/*
 max active, but if object comes in at INDispatchPriorityHigh, any active at lower priority are cancelled 
 */
- (void)promoteObject:(id <INDispatchQueueObject>)value forKey:(id <NSCopying>)key priority:(NSString*)priority;
- (id <INDispatchQueueObject>)objectForKey:(id <NSCopying>)key priority:(NSString**)priority;
- (id <INDispatchQueueObject>)activateNextObject;

/*
 id <INDispatchQueueObject> nextActiveObject = nil;
 NSInteger pendingIndex = NSNotFound;
 for(NSInteger i = 0; i < self.priorityKeys; i++) {
    INPriorityQueue *queue = [self.pendingQueues objectForKey:[self.priorityKeys objectAtIndex:i]]
    if (queue.count > 0) {
        pendingIndex = i;
        break;
    }
 }
 NSInteger maxActiveIndex = NSNotFound;
 for(NSInteger i = 0; i < self.priorityKeys; i++) {
    NSMutableArray *active = [self.activeRecords objectForKey:[self.priorityKeys objectAtIndex:i]];
    if (active.count > 0) {
        maxActiveIndex = i;
        break;
    }
 }
 if (pendingIndex != NSNotFound) {
    if (pendingIndex < maxActiveIndex) {
        for(NSInteger i = pendingIndex+1; i < self.priorityKeys.count; i++) {
            NSString *key = [self.priorityKeys objectAtIndex:i];
            NSMutableArray *active = [self.activeRecords objectForKey:key];
            INPriorityQueue *queue = [self.priorityQueues objectForKey:key];
            while(active.count > 0) {
                id <INDispatchQueueObject> active = [active objectAtIndex:0];
                [active cancelOperation];
                [queue promoteObject:active forKey:active.priorizationKey];
                [active removeObjectAtIndex:0];
            }
        }
    }
    NSMutableArray *active = [self.activeRecords objectForKey:[self.priorityKeys objectAtIndex:pendingIndex];
    if (active.count < self.maxActivePerLevel) {
        NSString *key = [self.priorityKeys objectAtIndex:i];
        INPriorityQueue *queue = [self.priorityQueues objectForKey:key];
        NSMutableArray *active = [self.activeRecords objectForKey:key];
        nextActiveObject = [queue removeLastObject];
        [active addObject:nextActiveObject];
    }
    return nextActiveObject;
 }
 */
@end



@implementation INDispatchRecord
@end

@interface INTimer : NSObject

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *lastFireDate;

@end

@implementation INTimer

- (id)init {
    self = [super init];
    if (self != nil) {
////        self.timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0/200 target:self selector:@selector(_timerFired:) userInfo:nil repeats:YES];
//        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

+ (INTimer*)shared {
    ZG_ASSERT_IS_MAIN_THREAD();
    static INTimer *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
    return singleton;
}

- (void)_timerFired:(NSTimer *)timer
{
    INViewController *viewController = [((INAppDelegate*)[[UIApplication sharedApplication] delegate]) viewController];
    NSDate *now = [NSDate date];
    NSTimeInterval delta = [now timeIntervalSinceDate:self.lastFireDate];
    NSTimeInterval goal = 1.0/60;
    if (delta > goal) {
        NSLog(@" ** 60HZ FAIL!! ** delta = %dms", (int)(delta*1000.0));
        viewController.collectionView.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    }
    else {
        viewController.collectionView.backgroundColor = [UIColor blackColor];
    }
    self.lastFireDate = now;
}

@end

@implementation INDispatch

- (id)init {
    self = [super init];
    if (self != nil) {
        self.priorityKeys = [NSArray arrayWithObjects:INDispatchPriorityHigh, INDispatchPriorityDefault, INDispatchPriorityLow, nil];
        NSMutableDictionary *queues = [NSMutableDictionary dictionary];
        for(NSString *key in self.priorityKeys) {
            [queues setObject:[[INPriorityQueue alloc] init] forKey:key];
        }
        self.priorityQueues = queues;
        self.activeTargets = [NSMutableDictionary dictionary];
        self.maxActiveTargets = 1;
    }
    return self;
}

+ (INDispatch*)shared {
    ZG_ASSERT_IS_MAIN_THREAD();
    static INDispatch *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
    return nil;
    return singleton;
}

+ (Class)dispatchRecordClass
{
    return [INDispatchRecord class];
}

- (INDispatchRecord*)dispatchRecordForKey:(id <NSCopying>)key
{
    INDispatchRecord *record = nil;
    for (INPriorityQueue *queue in [self.priorityQueues allValues]) {
        record = [queue objectForKey:key];
        if (record != nil) {
            break;
        }
    }
    return record;
}

- (INDispatchRecord*)promoteDispatchForKey:(id <NSCopying>)prioritizationKey priority:(NSString*)priority inputObject:(id)inputObject computation:(id (^)(id inputObject))computation completion:(void (^)(id result))completion
{
    ZG_ASSERT_IS_MAIN_THREAD();
    if (priority == nil) {
        priority = INDispatchPriorityDefault;
    }
//    NSLog(@"%X promote %@, %@, object %@", (int)self, [(NSString*)prioritizationKey lastPathComponent], priority, NSStringFromClass([inputObject class]));
//    NSLog(@"existing record %@", [self dispatchRecordForKey:prioritizationKey]);
    if (priority == INDispatchPriorityHigh || priority == INDispatchPriorityDefault) {
        INDispatchRecord *record = [[self.priorityQueues objectForKey:INDispatchPriorityLow] objectForKey:prioritizationKey];
        if (record != nil) {
            NSLog(@"to priority %@ %@", priority, [(NSString*)prioritizationKey lastPathComponent]);
        }
        [[self.priorityQueues objectForKey:INDispatchPriorityLow] removeObjectForKey:prioritizationKey];
        if (priority == INDispatchPriorityHigh) {
            record = [[self.priorityQueues objectForKey:INDispatchPriorityDefault] objectForKey:prioritizationKey];
            if (record != nil) {
                NSLog(@"to priority %@ %@", priority, [(NSString*)prioritizationKey lastPathComponent]);
            }
            [[self.priorityQueues objectForKey:INDispatchPriorityDefault] removeObjectForKey:prioritizationKey];
        }
    }
    INPriorityQueue *queue = [self.priorityQueues objectForKey:priority];
    INDispatchRecord *record = [queue objectForKey:prioritizationKey];
    if (record == nil) {
        record = [[[[self class] dispatchRecordClass] alloc] init];
        record.prioritizationKey = prioritizationKey;
    }
    record.inputObject = inputObject;
    record.computationBlock = computation;
    record.completionBlock = completion;

    [queue promoteObject:record forKey:record.prioritizationKey];
    [self dispatchOneIfNecessary];
    return record;
}

- (INDispatchRecord*)promoteDispatchForKey:(id <NSCopying>)prioritizationKey inputObject:(id)inputObject computation:(id (^)(id inputObject))computation completion:(void (^)(id result))completion
{
    return [self promoteDispatchForKey:prioritizationKey priority:INDispatchPriorityDefault inputObject:inputObject computation:computation completion:completion];
}

- (void)removeDispatchForKey:(id <NSCopying>)key
{
    ZG_ASSERT_IS_MAIN_THREAD();
    for (INPriorityQueue *queue in [self.priorityQueues allValues]) {
        [queue removeObjectForKey:key];
    }
    [self.activeTargets removeObjectForKey:key];
}

- (void)dispatchOneIfNecessary
{
    ZG_ASSERT_IS_MAIN_THREAD();
//    NSLog(@"canceling and reset");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_dispatchOneIfNecessary) withObject:nil afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

- (void)_dispatchOneIfNecessary
{
    ZG_ASSERT_IS_MAIN_THREAD();
    if (self.activeTargets.count < self.maxActiveTargets) {
        for(NSString *priority in self.priorityKeys) {
            INPriorityQueue *queue = [self.priorityQueues objectForKey:priority];
            if (queue.count > 0) {
                INDispatchRecord *record = [queue removeLastObject];
                [self.activeTargets setObject:record forKey:record.prioritizationKey];
                [self dispatchRecord:record];
                break;
            }
        }
    }
}

- (void)dispatchRecord:(INDispatchRecord*)record
{
    NSLog(@"warning, subclasses must override dispatch %@", record);
    NSAssert(NO, @"no");
}

- (void)cancelDispatch:(INDispatchRecord*)record
{
    ZG_ASSERT_IS_MAIN_THREAD();
    if (record != nil) {
        record.isCancelled = YES;
        [self removeDispatchForKey:record.prioritizationKey];
    }
}

@end

@implementation INCPUDispatch

+ (INCPUDispatch*)shared {
    ZG_ASSERT_IS_MAIN_THREAD();
    static INCPUDispatch *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
    return singleton;
}

- (void)dispatchRecord:(INDispatchRecord*)record
{
    ZG_ASSERT_IS_MAIN_THREAD();
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        /* default to "identity" computation */
        id computationResult = record.inputObject;
        if (record.computationBlock != NULL) {
            computationResult = record.computationBlock(record.inputObject);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (record.isCancelled == NO) {
                record.completionBlock(computationResult);
            }
            [weakSelf.activeTargets removeObjectForKey:record.prioritizationKey];
            [self performSelectorOnMainThread:@selector(dispatchOneIfNecessary) withObject:nil waitUntilDone:NO];
        });
    });
}

@end

@implementation INHTTPDispatch

+ (INHTTPDispatch*)shared {
    ZG_ASSERT_IS_MAIN_THREAD();
    static INHTTPDispatch *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
    return singleton;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        self.maxActiveTargets = 3;
    }
    return self;
}

- (INDispatchRecord*)promoteDownloadForURL:(NSURL*)URL priority:(NSString*)priority completion:(void (^)(NSData *data, NSError *error))completion
{
    ZG_ASSERT_IS_MAIN_THREAD();
    __weak __typeof(&*self)weakSelf = self;
//    NSLog(@"promote URL: %@", [URL lastPathComponent]);
    // NSURLCache is janky http://stackoverflow.com/questions/7166422/nsurlconnection-on-ios-doesnt-try-to-cache-objects-larger-than-50kb
    NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
    AFHTTPRequestOperation *httpRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [httpRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSData *data = (NSData*)responseObject;
            completion(data, nil);
            [weakSelf.activeTargets removeObjectForKey:URL];
            [weakSelf performSelectorOnMainThread:@selector(dispatchOneIfNecessary) withObject:nil waitUntilDone:NO];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             completion(nil, error);
            [weakSelf.activeTargets removeObjectForKey:URL];
            [weakSelf performSelectorOnMainThread:@selector(dispatchOneIfNecessary) withObject:nil waitUntilDone:NO];
         }];
    httpRequest.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    httpRequest.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
//    INDispatchRecord *record = [[INCPUDispatch shared] promoteDispatchForKey:URL inputObject:httpRequest computation:NULL completion:^(id result) {
    INDispatchRecord *record = [self promoteDispatchForKey:URL priority:priority inputObject:httpRequest computation:NULL completion:^(id result) {
        ZG_ASSERT_IS_MAIN_THREAD();
//        NSLog(@"web start %@ %@", [URL lastPathComponent], priority);
        [httpRequest start];
    }];
    return record;
}

- (void)dispatchRecord:(INDispatchRecord*)record
{
    ZG_ASSERT_IS_MAIN_THREAD();
    /* AFHTTPRequestOperation will run on background queue */
    record.completionBlock(record.inputObject);
    [self performSelectorOnMainThread:@selector(dispatchOneIfNecessary) withObject:nil waitUntilDone:NO];
}

- (void)cancelDispatch:(INDispatchRecord*)record
{
    [super cancelDispatch:record];
    if (record != nil) {
        AFHTTPRequestOperation *operation = record.inputObject;
        [operation cancel];
        [self.activeTargets removeObjectForKey:record.prioritizationKey];
    }
}

@end


@implementation INBlockDispatch

+ (INBlockDispatch*)shared {
    static INBlockDispatch *singleton = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        singleton = [[[self class] alloc] init];
    });
    return singleton;
}

- (void)dispatchMain:(void (^)())block
{
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)dispatchBackground:(void (^)())block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

@end

NSString *INDispatchPriorityHigh = @"INDispatchPriorityHigh";
NSString *INDispatchPriorityDefault = @"INDispatchPriorityDefault";
NSString *INDispatchPriorityLow = @"INDispatchPriorityLow";
