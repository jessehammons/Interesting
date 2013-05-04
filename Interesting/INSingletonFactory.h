//
//  INSingleton.h
//  Interesting
//
//  Created by Jesse Hammons on 5/3/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INSingletonFactory : NSObject

@property (nonatomic, strong) NSMutableDictionary *singletons;

+ (INSingletonFactory*)shared;

- (id)singletonForClass:(Class)cls;

@end
