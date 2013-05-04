//
//  INSingleton.m
//  Interesting
//
//  Created by Jesse Hammons on 5/3/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INSingletonFactory.h"

@interface INSingletonRecord : NSObject
{
    @public
    dispatch_once_t predicate;
}

@property (nonatomic, strong) Class singletonClass;
@property (nonatomic, strong) id singletonObject;

@end

@implementation INSingletonRecord
@end

@implementation INSingletonFactory

+ (INSingletonFactory*)shared {
    ZG_ASSERT_IS_MAIN_THREAD();
    static INSingletonFactory *singleton = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        singleton = [[[self class] alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.singletons = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)singletonForClass:(Class)cls
{
    ZG_ASSERT_IS_MAIN_THREAD();
    NSString *classKey = NSStringFromClass(cls);
    INSingletonRecord *record = [self.singletons objectForKey:classKey];
    if (record == nil) {
        record = [[INSingletonRecord alloc] init];
        record.singletonClass = cls;
        dispatch_once(&record->predicate, ^{
            record.singletonObject = [[cls alloc] init];
        });
        [self.singletons setObject:record forKey:classKey];
    }
    return record.singletonObject;
}

@end
