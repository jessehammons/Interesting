//
//  INDiskCache.m
//  Interesting
//
//  Created by Jesse Hammons on 4/25/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INDiskCache.h"

#define CHUNK_SIZE      200*1024*1024
#define CHUNK_COUNT     20

#import <CommonCrypto/CommonDigest.h>

@interface NSString(MD5)
- (NSString *)MD5Key;
@end

@interface DiskChunk : NSObject

@property (nonatomic, strong) NSString *chunkPath;
@property (nonatomic, assign) NSInteger chunkSize;

- (id)initWithPath:(NSString*)path;
- (void)addData:(NSData*)data destinationPath:(NSString*)destinationPath dataKey:(NSString*)dataKey;

@end

@implementation DiskChunk

- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (self != nil) {
        self.chunkPath = path;
    }
    return self;
}

- (void)addData:(NSData*)data destinationPath:(NSString*)destinationPath dataKey:(NSString*)dataKey
{
    NSString *linkPath = [self.chunkPath stringByAppendingPathComponent:dataKey];
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:linkPath withDestinationPath:destinationPath error:nil];
//    NSLog(@"data=%d, size=%d, new size %d, link %@ to %@", data.length, self.chunkSize, self.chunkSize+data.length, linkPath, destinationPath);
    self.chunkSize += data.length;
}

- (void)remove
{
    for(NSString *link in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.chunkPath error:nil]) {
        NSString *linkPath = [self.chunkPath stringByAppendingPathComponent:link];
        NSString *destinationPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:linkPath error:nil];
        if (destinationPath != nil) {
            [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
        }
    }
    NSLog(@"remove %@", [self.chunkPath lastPathComponent]);
    [[NSFileManager defaultManager] removeItemAtPath:self.chunkPath error:nil];
}

- (void)calculateSize
{
    NSInteger totalBytes = 0;
    for(NSString *link in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.chunkPath error:nil]) {
        NSString *linkPath = [self.chunkPath stringByAppendingPathComponent:link];
        NSString *destinationPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:linkPath error:nil];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:destinationPath error:nil];
        totalBytes += attributes.fileSize;
    }
    self.chunkSize = totalBytes;
}

- (NSArray*)allFilePaths
{
    NSMutableArray *paths = [NSMutableArray array];
    for(NSString *link in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.chunkPath error:nil]) {
        NSString *linkPath = [self.chunkPath stringByAppendingPathComponent:link];
        NSString *destinationPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:linkPath error:nil];
        [paths addObject:destinationPath];
    }
    return paths;
}

@end




@implementation INDiskCache

+ (INDiskCache*)shared {
    static INDiskCache *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
    return singleton;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        NSURL *base = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        self.cacheBasePath = [[base path] stringByAppendingPathComponent:@"disk_cache"];
        self.chunksBasePath = [self.cacheBasePath stringByAppendingPathComponent:@"chunks"];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.chunksBasePath withIntermediateDirectories:YES attributes:nil error:nil];
        self.filesBasePath = [self.cacheBasePath stringByAppendingPathComponent:@"files"];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.filesBasePath withIntermediateDirectories:YES attributes:nil error:nil];
        [self readChunks];
    }
    return self;
}

- (void)readChunks
{
    self.chunks = [NSMutableArray array];
    for(NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.chunksBasePath error:nil]) {
        DiskChunk *chunk = [[DiskChunk alloc] initWithPath:[self.chunksBasePath stringByAppendingPathComponent:path]];
        [self.chunks addObject:chunk];
    }
    if (self.chunks.count == 0) {
        [self addChunk];
    }
    [self.currentChunk calculateSize];
}

- (NSArray*)_allFiles
{
    NSMutableArray *files = [NSMutableArray array];
    for(DiskChunk *chunk in self.chunks) {
        [files addObjectsFromArray:[chunk allFilePaths]];
    }
    return files;
}

- (void)addChunk
{
    long long millis = 1000.0*[NSDate timeIntervalSinceReferenceDate];
    NSString *chunkName = [NSString stringWithFormat:@"%qd", millis];
    chunkName = [[chunkName componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    NSString *chunkPath = [self.chunksBasePath stringByAppendingPathComponent:chunkName];
    [[NSFileManager defaultManager] createDirectoryAtPath:chunkPath withIntermediateDirectories:YES attributes:nil error:nil];
    DiskChunk *chunk = [[DiskChunk alloc] initWithPath:chunkPath];
    [self.chunks addObject:chunk];
    while(self.chunks.count > CHUNK_COUNT) {
        DiskChunk *chunk = [self.chunks objectAtIndex:0];
//        NSLog(@"remove chunk %@", chunk.chunkPath);
        [chunk remove];
        [self.chunks removeObjectAtIndex:0];
    }
}

- (DiskChunk*)currentChunk
{
    return [self.chunks lastObject];
}

- (NSString*)filePathForKey:(NSString*)key
{
    NSString *dataKey = [key MD5Key];
    NSString *destinationPath = [[self.filesBasePath stringByAppendingPathComponent:dataKey] stringByAppendingPathExtension:@"jpg"];
    return destinationPath;
}

- (void)setData:(NSData*)data forKey:(NSString *)key
{
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *dataKey = [key MD5Key];
        NSString *destinationPath = [self filePathForKey:key];
//        NSLog(@"set %@ for %@", [key lastPathComponent], [destinationPath lastPathComponent]);
        [data writeToFile:destinationPath atomically:NO];
        [weakSelf.currentChunk addData:data destinationPath:destinationPath dataKey:dataKey];
        if (weakSelf.currentChunk.chunkSize > CHUNK_SIZE) {
            NSLog(@"new chunk size=%d", weakSelf.currentChunk.chunkSize);
            [weakSelf addChunk];
        }
    });
}

- (NSData*)dataForKey:(NSString*)key
{
    NSData *result = nil;
    NSString *destinationPath = [self filePathForKey:key];
    result = [NSData dataWithContentsOfFile:destinationPath];
//    NSLog(@"%@ cache %@ = %d bytes", [key lastPathComponent], [destinationPath lastPathComponent], result.length);
    return result;
}

- (BOOL)hasDataForKey:(NSString*)key
{
    NSString *destinationPath = [self filePathForKey:key];
    return [[NSFileManager defaultManager] fileExistsAtPath:destinationPath];
}

@end


@implementation NSString(MD5)

- (NSString*)MD5Key
{
    // Create pointer to the string as UTF8
    const char *ptr = [self UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    return output;
}

@end

