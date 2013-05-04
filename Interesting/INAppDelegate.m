//
//  INAppDelegate.m
//  Interesting
//
//  Created by Jesse Hammons on 4/21/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INAppDelegate.h"

#import "INObject.h"
#import "INViewController.h"
#import "INHorizontalViewController.h"
#import "INTagsCollectionViewController.h"
#import "INFullscreenLoadingViewController.h"
#import "INTestTableViewController.h"
#import "INTestDispatchViewController.h"

@implementation INAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"initialized tag history %@", [INTagHistory shared]);
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[INViewController alloc] initWithNibName:@"INViewController" bundle:nil];
//    INTagsCollectionViewController *controller = [[INTagsCollectionViewController alloc] initWithNibName:@"INTagsCollectionViewController" bundle:nil];
//    INTestTableViewController *controller = [[INTestTableViewController alloc] initWithStyle:UITableViewStylePlain];
    INTestDispatchViewController *controller = [[INTestDispatchViewController alloc] initWithStyle:UITableViewStylePlain];
    
    
//    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.translucent = YES;
    self.navigationController.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
//    [self.navigationController setToolbarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.window.rootViewController = self.navigationController;
    self.window.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    [self.window makeKeyAndVisible]; 
//    [self.navigationController setNavigationBarHidden:YES animated:NO];

    // NavigationBar appearance
//    [[UINavigationBar appearance] setTintColor: [UIColor colorWithHexString:@"0xEBEBEB"]];
    // Nav title appearance
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigation_bar_bg"] forBarMetrics:UIBarMetricsDefault];
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIFont fontWithName:@"Didot-Italic" size:24.0], UITextAttributeFont,
                                               [UIColor colorWithRed:0.95 green:0.22 blue:0.60 alpha:0.8],UITextAttributeTextColor,
                                               [UIColor clearColor], UITextAttributeTextShadowColor,
                                               [NSValue valueWithUIOffset:UIOffsetMake(0, 4)], UITextAttributeTextShadowOffset, nil];
    
//    95 22 60
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:-5 forBarMetrics:UIBarMetricsDefault];

    self.viewController.navigationItem.title = @"interesting";

//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[INFullscreenLoadingViewController shared] presentLoadingFullscreen:controller completion:^{
//            [controller loadTag:@"interesting" completion:^{
//                [[INFullscreenLoadingViewController shared] dismissLoadingFullscreen:NULL];
//            }];
//        }];
//    });

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
