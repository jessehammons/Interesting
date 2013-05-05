//
//  INTagsCollectionViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 4/27/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INTagsCollectionViewController.h"

#import "INTheme.h"
#import "INDispatch.h"
//#import "INFlickrAPI.h"
#import "INObject.h"
#import "INTagsCollectionView.h"
#import "INHorizontalViewController.h"
#import "INFullscreenLoadingViewController.h"

#import "INDiskCache.h"
#import "INThumbnailCache.h"

@interface INTagsCollectionViewController ()

@end

@implementation INTagsCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[INTheme shared] defaultRightBarButtonItem];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"interesting";
    self.collectionView.collectionView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.collectionView.collectionView.delegate = self;

//    [[INFullscreenLoadingViewController shared] presentLoadingFullscreen:self completion:NULL];
//    [[INFlickrAPI shared] interestingPhotosForTags:@[@"exotic"] section:0 filterPredicate:nil completion:^(NSArray *photos, NSError *error) {
//        [[INBlockDispatch shared] dispatchMain:^{
//            self.collectionView.photos = photos;
//            [self.collectionView.collectionView reloadData];
//            [[INFullscreenLoadingViewController shared] dismissLoadingFullscreen:NULL];
//        }];
//    }];
    self.collectionView.tagsDataSource = [[INFlickrDataSource alloc] initWithSourceTags:@[@"interesting"]];
    [self.collectionView.collectionView reloadData];
//    [self.collectionView performSelector:@selector(loadNextSectionIfNecessary) withObject:nil afterDelay:0];
    [self.collectionView loadNextSectionIfNecessary];
//    [self.collectionView loadNextSectionIfNecessary];

//    self.view.transform = CGAffineTransformMakeScale(0.8, 0.8);
//    
//    NSArray *allFiles = [[INDiskCache shared] _allFiles];
////    NSMutableArray *photos = [NSMutableArray array];
//    NSMutableArray *thumbs = [NSMutableArray array];
//    NSMutableArray *bigThumbs = [NSMutableArray array];
//    NSMutableArray *medium = [NSMutableArray array];
//    NSMutableArray *large = [NSMutableArray array];
//    for(NSString *path in allFiles) {
//        NSData *data = [NSData dataWithContentsOfFile:path];
//        UIImage *image = [UIImage imageWithData:data];
////        NSLog(@"size %@", NSStringFromCGSize(image.size));
//        if (image != nil) {
//            if (image.size.width <= 100) {
//                [thumbs addObject:path];
//            }
//            else if (image.size.width > 100 && image.size.width <= 320) {
//                [bigThumbs addObject:path];
//            }
//            else if (image.size.width > 320 && image.size.width <= 640) {
//                [medium addObject:path];
//            }
//            else if (image.size.width >= 2048) {
//                [large addObject:path];
//            }
//            if (thumbs.count > 500 && medium.count > 100 && large.count > 10) {
//                break;
//            }
//        }
//    }
//    [[INBlockDispatch shared] dispatchBackground:^{
//        CGSize small = CGSizeMake(150, 100);
//        CGSize mid = CGSizeMake(350, 200);
//        CGSize lrg = CGSizeMake(640, 480);
//        CGSize retina = CGSizeMake(2048, 1536);
//        for(NSValue *value in @[[NSValue valueWithCGSize:CGSizeZero],[NSValue valueWithCGSize:small], [NSValue valueWithCGSize:mid], [NSValue valueWithCGSize:lrg], [NSValue valueWithCGSize:retina] ]) {
//            for(NSArray *paths in @[thumbs, bigThumbs, medium, large]) {
//                NSDate *startDate = [NSDate date];
//                @autoreleasepool {
//
//                    for(NSInteger i = 0; i >= 0; i++) {
//                        NSInteger index = (i % paths.count);
//                        NSData *data = [NSData dataWithContentsOfFile:[paths objectAtIndex:index]];
//                        if (CGSizeEqualToSize(CGSizeZero, [value CGSizeValue]) == NO) {
//                            [[INThumbnailCache shared] synchronouslyDecodeImageData:data forSize:[value CGSizeValue]];
//                        }
//                        if ([[NSDate date] timeIntervalSinceDate:startDate] > 5) {
//                            NSLog(@"dest=%@, count=%d, decoded %.2f/sec", value, paths.count, (1.0/5*i));
//                            break;
//                        }
//                    }
//
//                }
//            }
//        }
//        NSLog(@"done");
//    }];
}



- (void)viewWillAppear:(BOOL)animated
{
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    INDataSource *dataSource = [self.collectionView.tagsDataSource tagAtIndex:indexPath.item updateHighWatermark:NO];
    INHorizontalViewController *controller = [[INHorizontalViewController alloc] initWithNibName:@"INHorizontalViewController" bundle:nil];
//    [[INFullscreenLoadingViewController shared] presentLoadingFullscreen:self completion:NULL];
//    [controller loadTag:[dataSource.sourceTags objectAtIndex:0] completion:^{
//        [[INFullscreenLoadingViewController shared] dismissLoadingFullscreen:NULL];
//    }];
    [controller updateDataSource:dataSource];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
