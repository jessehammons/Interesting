//
//  INViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 4/21/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INViewController.h"

#import "INFlickrAPI.h"
#import "UIImageView+AFNetworking.h"
#import "INThumbnailCache.h"
#import "INDispatch.h"
#import "INDiskCache.h"

#import <AVFoundation/AVFoundation.h>

@interface UIImage (Resize)

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;

@end

@implementation UIImage (Resize)

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end

//#import "AFJSONRequestOperation.h"
//#import <CommonCrypto/CommonDigest.h>
//
//NSString *OFMD5HexStringFromNSString(NSString *inStr)
//{
//    const char *data = [inStr UTF8String];
//    CC_LONG length = (CC_LONG) strlen(data);
//    
//    unsigned char *md5buf = (unsigned char*)calloc(1, CC_MD5_DIGEST_LENGTH);
//    
//    CC_MD5_CTX md5ctx;
//    CC_MD5_Init(&md5ctx);
//    CC_MD5_Update(&md5ctx, data, length);
//    CC_MD5_Final(md5buf, &md5ctx);
//    
//    NSMutableString *md5hex = [NSMutableString string];
//	size_t i;
//    for (i = 0 ; i < CC_MD5_DIGEST_LENGTH ; i++) {
//        [md5hex appendFormat:@"%02x", md5buf[i]];
//    }
//    free(md5buf);
//    return md5hex;
//}

@interface INViewController ()

@end

@interface INCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *progressImageView;
@property (nonatomic, strong) NSDictionary *photo;
@property (nonatomic, strong) INDispatchRecord *imageRecord;
@property (nonatomic, strong) INDispatchRecord *previewImageRecord;
@property (nonatomic, strong) NSString *currentURLt;

- (void)updatePhoto:(NSDictionary*)dictionary;

@end

@interface TestTarget : NSObject

@property (nonatomic, strong) NSNumber *key;
- (void)testExecute;
@end

@implementation TestTarget
- (void)_delayed
{
    ZG_ASSERT_IS_MAIN_THREAD();
    NSLog(@"key is %@", self.key);
}
- (void)_testExecute
{
    [self performSelector:@selector(_delayed) withObject:nil afterDelay:0];
}
- (void)testExecute
{
    ZG_ASSERT_IS_BACKGROUND_THREAD();
    [self performSelectorOnMainThread:@selector(_testExecute) withObject:nil waitUntilDone:NO];
}
@end

@implementation INCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"i_progress_bg_gray"]];
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.label.alpha = 0.1;
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.imageView];
        self.progressImageView = [[UIImageView alloc] initWithFrame:self.imageView.frame];
        self.progressImageView.image = [UIImage imageNamed:@"i_progress_bg_gray"];
        self.progressImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.progressImageView.clipsToBounds = YES;
        [self.contentView addSubview:self.progressImageView];
    }
    return self;
}
- (void)updatePhoto:(NSDictionary*)dictionary
{
    self.progressImageView.image = [UIImage imageNamed:@"i_progress_bg_gray"];
//    self.progressImageView.frame = CGRectMake(0, self.frame.size.height-1, self.frame.size.width, 1);
    self.progressImageView.frame = self.imageView.frame;
    self.progressImageView.alpha = 0.4;
    self.imageView.alpha = 0.0;
    self.contentView.alpha = 0.8;
    self.photo = dictionary;
//    self.label.text = [self.photo objectForKey:@"title"];
    NSString *url_t = [self.photo objectForKey:@"url_t"];
//    if ([url_t isEqualToString:self.currentURLt]) {
//        return;
//    }
//    self.currentURLt = url_t;
    NSURL *URLt = [NSURL URLWithString:url_t];
    self.imageView.image = nil;
    [[INThumbnailCache shared] cancelDispatch:self.previewImageRecord];
    self.previewImageRecord = [[INThumbnailCache shared] decodeImageURL:URLt forSize:self.progressImageView.frame.size priority:INDispatchPriorityHigh downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
        ZG_ASSERT_IS_MAIN_THREAD();
        self.progressImageView.image = image;
        self.previewImageRecord = nil;
    }];
//    return;
    NSString *urlN = [self.photo objectForKey:@"url_z"];
    NSURL *URLN = [NSURL URLWithString:urlN];
    if (urlN.length > 0) {
        [[INThumbnailCache shared] cancelDispatch:self.imageRecord];
        self.imageRecord = [[INThumbnailCache shared] decodeImageURL:URLN forSize:self.imageView.frame.size priority:INDispatchPriorityDefault downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image) {
            ZG_ASSERT_IS_MAIN_THREAD();
            [[INThumbnailCache shared] cancelDispatch:self.previewImageRecord];
            self.previewImageRecord = nil;
//            image = [UIImage imageNamed:@"i_progress_bg_color"];
            self.imageView.image = image;
            self.imageRecord = nil;
            [UIView animateWithDuration:0.3 animations:^{
               self.imageView.alpha = 1;
               self.progressImageView.alpha = 0;
            }];
         }];
//        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpected){
//            CGFloat progress = 1.0*totalBytesRead/totalBytesExpected;
//            [UIView animateWithDuration:0.5 animations:^{
////                CGFloat height = progress*self.frame.size.height;
////                self.progressImageView.frame = CGRectMake(0, self.frame.size.height-height, self.frame.size.width, height);
////                NSLog(@"progress=%f", progress);
//                self.progressImageView.alpha = MIN(progress, 0.4);
//            }];
//        }];
//        operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
//        operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
//        [operation start];
//        self.imageOperation = operation;
    }
    
}

@end

@implementation INViewController



- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo1"]];
    imageView.frame = CGRectMake(0, 0, imageView.frame.size.width, 54);
    imageView.contentMode = UIViewContentModeBottom;
    self.navigationItem.titleView = imageView;

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(200, 150);
    flowLayout.minimumInteritemSpacing = 80;
    flowLayout.minimumLineSpacing = 120;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 80, 0, 80);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:flowLayout];
    [self.collectionView registerClass:[INCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass([INCollectionCell class])];
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
//    NSString *HOST = @"http://api.flickr.com";
//    NSString *API = @"/services/rest";
//    NSString *API_KEY = @"435c14c7bdc0148def43bf41534e81c7";
////    NSString *API_SECRET = @"000e2bd4a3d4ae32";
//    NSString *method = @"flickr.photos.search";
//    NSDictionary *arguments = @{
//                                @"tags" : @"exotic",
//                                @"sort" : @"interestingness-desc@",
//                                @"content_type" : @"1", //photos only
//                                @"format" : @"json",
//                                @"page" : @"1",
//                                @"nojsoncallback" : @"1",
//                                @"extras" : @"tags,o_dims,url_z,url_n",
//                                };
//    NSString *argStr = [[self class] addQueryStringToUrlString:@"" withDictionary:arguments];
//    NSString *url = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@&%@%@'% (HOST, API, API_KEY, method, urllib.urlencode(params), _get_auth_url_suffix(method, auth, params))
//    NSString *authSuffix = @"";
//    NSString *url = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@&%@%@", HOST, API, API_KEY, method, argStr, authSuffix];
//    NSString *p1 = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@", HOST, API, API_KEY, method];
//    NSString *url = [[self class] addQueryStringToUrlString:p1 withDictionary:arguments];
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
//    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
//    {
//        NSLog(@"success %@", JSON);
//    }
//    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
//    {
//        NSLog(@"FAIL %@, %@", error, JSON);
//    }];
//    [operation start];
//    NSString *method = @"flickr.photos.search";
//    NSDictionary *arguments = @{
//                                @"tags" : @"exotic",
//                                @"sort" : @"interestingness-desc",
//                                @"content_type" : @"1", //photos only
//                                @"page" : @"1",
//                                @"per_page" : @"100",
//                                @"extras" : @"original_format,tags,o_dims,url_z,url_n,url_c,url_o,url_b,url_t",
////                                @"extras" : @"tags,o_dims,url_a,url_b,url_c,url_d,url_e,url_f,url_g,url_h,url_i, url_j,url_k,url_m,url_n,url_o,url_p,url_q,url_r,url_s,url_t,url_u,url_v,url_w,url_x,url_y,url_z,url_A,url_B,url_C,url_D,url_E,url_F,url_G,url_H,url_I, url_J,url_K,url_M,url_N,url_O,url_P,url_Q,url_R,url_S,url_T,url_U,url_V,url_W,url_X,url_Y,url_Z",
//                                };
////- (void)interestingPhotosForTags:(NSArray*)tags section:(NSInteger)section  filterPredicate:(NSPredicate *)filterPredicate completion:(void (^)(NSArray *photos, NSError *error))completion
//    [[INFlickrAPI shared] flickrAPICallMethod:method arguments:arguments completion:^(id JSON, NSError *error)
//    {
//        self.photos = [[JSON objectForKey:@"photos"] objectForKey:@"photo"];
//        self.photos = [self.photos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id obj, NSDictionary *bindings){
//            return (BOOL)([obj objectForKey:@"url_z"] != nil);
//        }]];
//        NSLog(@"result %@, error=%@", self.photos, error);
//        [[INThumbnailCache shared] preprocessPhotos:self.photos];
//        [self.collectionView reloadData];
//    }];
    [[INFlickrAPI shared] interestingPhotosForTags:@[@"green"] section:0 filterPredicate:nil completion:^(NSArray *photos, NSError *error) {
        self.photos = photos;
        [[INBlockDispatch shared] dispatchMain:^{
            [self.collectionView reloadData];
//            [[INThumbnailCache shared] preprocessPhotos:self.photos URLKeys:@[@"url_t"]];
        }];
    }];
    
//    NSMutableArray *targets = [NSMutableArray array];
//    for(NSInteger i = 0; i < 10; i++) {
//        TestTarget *target = [[TestTarget alloc] init];
//        target.key = [NSNumber numberWithInteger:i];
//        [[INCPUDispatch shared] promoteDispatchForPrioritizationKey:target.key completion:^{
//            ZG_ASSERT_IS_BACKGROUND_THREAD();
//            [target testExecute];
//            [self performSelectorOnMainThread:@selector(print) withObject:nil waitUntilDone:NO];
//        }];
//        [targets addObject:target];
//        NSString *s = [NSString stringWithFormat:@"http://www.google.com/search?q=%d", i];
//        NSURL *URL = [NSURL URLWithString:s];
//        [[INHTTPDispatch shared] promoteDownloadForURL:URL completion:^(NSData *data, NSError *error) {
//            ZG_ASSERT_IS_BACKGROUND_THREAD();
//            NSLog(@"bytes=%d for %@", data.length, URL);
//        }];
//    }
//    NSURL *URL = [NSURL URLWithString:@"http://www.google.com/search?q=3"];
//    [[INHTTPDispatch shared] promoteDownloadForURL:URL completion:^(NSData *data, NSError *error) {
//        ZG_ASSERT_IS_BACKGROUND_THREAD();
//        NSLog(@"OTHER=%d for %@", data.length, URL);
//    }];
//    URL = [NSURL URLWithString:@"http://www.google.com/search?q=6"];
//    [[INHTTPDispatch shared] promoteDownloadForURL:URL completion:^(NSData *data, NSError *error) {
//        ZG_ASSERT_IS_BACKGROUND_THREAD();
//        NSLog(@"OTHER=%d for %@", data.length, URL);
//    }];
//
//    TestTarget *test = [targets objectAtIndex:3];
//    [[INCPUDispatch shared] promoteDispatchForPrioritizationKey:test.key completion:^{
//        ZG_ASSERT_IS_BACKGROUND_THREAD();
//        [test testExecute];
//    }];
//    test = [targets objectAtIndex:6];
//    [[INCPUDispatch shared] promoteDispatchForPrioritizationKey:test.key completion:^{
//        ZG_ASSERT_IS_BACKGROUND_THREAD();
//        [test testExecute];
//    }];
}

- (void)print
{
    NSLog(@"blah");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
//    return 3;
    return self.photos.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *photo = [self.photos objectAtIndex:indexPath.item];
    INCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([INCollectionCell class]) forIndexPath:indexPath];

    NSInteger prefetchSize = 6;
    NSMutableArray *prefetch = [NSMutableArray array];
    NSInteger indexBefore = MAX(0, indexPath.row - prefetchSize);
    if (indexBefore < indexPath.row) {
        NSArray *before = [self.photos subarrayWithRange:NSMakeRange(indexBefore, indexPath.row-indexBefore)];
        [prefetch addObjectsFromArray:before];
    }
    NSInteger indexAfter = MIN(self.photos.count-1, indexPath.row + 1 + prefetchSize);
    if (indexAfter > indexPath.row) {
        NSArray *after = [self.photos subarrayWithRange:NSMakeRange(indexPath.row, indexAfter-indexPath.row)];
        [prefetch addObjectsFromArray:after];
    }
    [[INThumbnailCache shared] preprocessPhotos:prefetch URLKeys:@[@"url_t"]];

    [cell updatePhoto:photo];
    return cell;
}

@end
