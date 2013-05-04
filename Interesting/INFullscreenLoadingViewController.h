//
//  INFullscreenLoadingViewController.h
//  Interesting
//
//  Created by Jesse Hammons on 4/30/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface INFullscreenLoadingViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIViewController *clientViewController;

+ (INFullscreenLoadingViewController*)shared;

- (void)presentLoadingFullscreen:(UIViewController*)controller completion:(void (^)(void))completion;
- (void)dismissLoadingFullscreen:(void (^)(void))completion;

@end
