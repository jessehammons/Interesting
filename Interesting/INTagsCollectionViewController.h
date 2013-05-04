//
//  INTagsCollectionViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 4/27/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INTagsCollectionView;
@class INFlickrDataSource;

@interface INTagsCollectionViewController : UIViewController <UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet INTagsCollectionView *collectionView;

@end
