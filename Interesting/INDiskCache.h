//
//  INDiskCache.h
//  Interesting
//
//  Created by Jesse Hammons on 4/25/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DiskChunk;

@interface INDiskCache : NSObject


@property (nonatomic, strong) NSString *cacheBasePath;
@property (nonatomic, strong) NSString *chunksBasePath;
@property (nonatomic, strong) NSString *filesBasePath;
@property (nonatomic, strong) NSMutableArray *chunks;
@property (nonatomic, readonly) DiskChunk *currentChunk;


+ (INDiskCache*)shared;

- (void)setData:(NSData*)data forKey:(NSString *)aKey;
- (NSData*)dataForKey:(NSString*)key;
- (BOOL)hasDataForKey:(NSString*)key;

/* debug */
- (NSArray*)_allFiles;

@end
