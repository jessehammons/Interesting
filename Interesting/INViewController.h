//
//  INViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 4/21/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface INViewController : UIViewController <UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *photos;

@end
