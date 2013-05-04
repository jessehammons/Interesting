//
//  INTestDispatchViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 5/2/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INTestDispatchViewController.h"

#import "INObject.h"
#import "INPipeline.h"

@interface INPipelineImageView : UIImageView

@property (nonatomic, strong) INPipelineObject *pipelineObject;

- (void)cancelLoading;

@end

@implementation INPipelineImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 30)];
        label.font = [UIFont systemFontOfSize:10];
        label.tag = 99;
        label.numberOfLines = 0;
        [self addSubview:label];
    }
    return self;
}

- (void)cancelLoading
{
    [self.pipelineObject removeImageView:self];
    self.pipelineObject = nil;
}

@end

@interface INTestDispatchViewController ()

@end

@interface TestDispatchCell : UITableViewCell

@property (nonatomic, strong) NSArray *imageViews;

- (void)updatePhotoObject:(INPhotoObject*)photoObject;

@end

@implementation TestDispatchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        NSMutableArray *imageViews = [NSMutableArray array];
        for(NSInteger i = 0; i < 6; i++) {
            INPipelineImageView *imageView = [[INPipelineImageView alloc] initWithFrame:CGRectMake(i*140, 0, 120, 80)];
            [self.contentView addSubview:imageView];
            [imageViews addObject:imageView];
        }
        self.imageViews = imageViews;
    }
    return self;
}
- (void)updatePhotoObject:(INPhotoObject*)photoObject
{
    NSInteger count = 0;
    for(NSInteger i = 0; i < self.imageViews.count; i++) {
        INPipelineImageView *imageView = [self.imageViews objectAtIndex:count];
        [imageView cancelLoading];
        imageView.image = nil;
        imageView.backgroundColor = [UIColor darkGrayColor];
        NSString *url = [photoObject.dictionary objectForKey:@"url_o"];
        url = [NSString stringWithFormat:@"http://www.zaggle.org/pdx/image/resize?width=2048&quality=50&image_url=%@", [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *URL = [NSURL URLWithString:url];
        NSMutableArray *URLS = [NSMutableArray arrayWithObject:URL];
        URL = [photoObject.dictionary URLForKey:@"url_z"];
        if (URL != nil) {
            [URLS addObject:URL];
        }
        URL = [photoObject.dictionary URLForKey:@"url_t"];
        if (URL != nil) {
            [URLS addObject:URL];
        }
        URL = [photoObject.dictionary URLForKey:@"url_n"];
        if (URL != nil) {
            [URLS addObject:URL];
        }
        URL = [URLS objectAtIndex:arc4random() % URLS.count];
        BOOL useCache = arc4random() % 2;
        NSInteger priority = arc4random() % 3;
//        if (i == INPipelinePriorityDefault) {
//            URL = [photoObject.dictionary URLForKey:@"url_z"];
//        }
//        else if (i == INPipelinePriorityLow) {
//            URL = [photoObject.dictionary URLForKey:@"url_t"];
//        }
//        BOOL useCache = NO;
////        if (i == INPipelinePriorityHigh) {
////            useCache = NO;
////        }
        imageView.pipelineObject = [INPipeline promoteDispatchForDataURL:URL priority:priority download:YES useCache:useCache imageView:imageView];
        count++;
    }
}

@end

@implementation INTestDispatchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.rowHeight = 80;
    self.tableView.allowsSelection = NO;

    self.dataSource = [[INFlickrDataSource alloc] initWithSourceTags:@[@"interesting"]];
    [self.dataSource sectionForSectionIndex:0 completion:^(INSection *section){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource photosCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TestDispatchCell *cell = (id)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TestDispatchCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    INPhotoObject *photoObject = [self.dataSource photoAtIndex:indexPath.row updateHighWatermark:NO];
//    cell.textLabel.text = [photoObject.dictionary objectForKey:@"tags"];
    [cell updatePhotoObject:photoObject];
    
    return cell;
}

@end