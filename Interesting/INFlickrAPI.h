//
//  INFlickrAPI.h
//  Interesting
//
//  Created by Jesse Hammons on 4/21/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INFlickrAPI : NSObject

@property (nonatomic, strong) NSString *API_KEY;
@property (nonatomic, strong) NSString *API_SECRET;

+ (instancetype)shared;

- (void)flickrAPICallMethod:(NSString*)method arguments:(NSDictionary*)arguments completion:(void (^)(id JSON, NSError *error))completion;
- (void)interestingPhotosForTags:(NSArray*)tags section:(NSInteger)section filterPredicate:(NSPredicate *)filterPredicate completion:(void (^)(NSArray *photos, NSError *error))completion;

@end
