//
//  INTagsCollectionView.h
//  Interesting
//
//  Created by Jesse Hammons on 4/27/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INDataSource;

@interface INTagsCollectionView : UIView <UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) INDataSource *tagsDataSource;
@property (nonatomic, assign) BOOL isLoading;

- (void)loadNextSectionIfNecessary;

@end
