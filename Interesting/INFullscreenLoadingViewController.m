//
//  INFullscreenLoadingViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 4/30/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INFullscreenLoadingViewController.h"

@interface INFullscreenLoadingViewController ()

@end

@implementation INFullscreenLoadingViewController

+ (INFullscreenLoadingViewController*)shared {
    static INFullscreenLoadingViewController *singleton = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        singleton = [[[self class] alloc] init];
    });
    return singleton;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentLoadingFullscreen:(UIViewController*)controller completion:(void (^)(void))completion
{
    self.clientViewController = controller;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.clientViewController presentViewController:self animated:NO completion:completion];
}

- (void)dismissLoadingFullscreen:(void (^)(void))completion
{
    [self.clientViewController dismissViewControllerAnimated:YES completion:completion];
    self.clientViewController = nil;
}

@end
