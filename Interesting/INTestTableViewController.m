//
//  INTestTableViewController.m
//  Interesting
//
//  Created by Jesse Hammons on 5/2/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INTestTableViewController.h"

#import "INObject.h"
#import "INDispatch.h"
#import "INPhotoView.h"
#import "INThumbnailCache.h"

@interface INTestTableViewController ()

@end

@implementation INTestTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.flickrDataSource = [[INFlickrDataSource alloc] initWithSourceTags:@[@"green"]];
    [self loadNextSectionIfNecessary];
}

- (NSInteger)totalRowCount
{
    NSInteger result = 0;
    for(INSection *section in self.flickrDataSource.sections) {
        result += section.photos.count;
    }
    return result;
}

- (void)loadNextSectionIfNecessary
{
    if (self.isLoading == NO) {
        self.isLoading = YES;
        [self.flickrDataSource sectionForSectionIndex:self.flickrDataSource.sections.count completion:^(INSection *section) {
            [[INBlockDispatch shared] dispatchMain:^{
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:self.flickrDataSource.sections.count-1] withRowAnimation:UITableViewRowAnimationAutomatic];
                if ([self totalRowCount] < self.maxRowSoFar + 50) {
                    [self performSelector:@selector(loadNextSectionIfNecessary) withObject:nil afterDelay:0];
                }
                self.isLoading = NO;
            }];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.flickrDataSource.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    INSection *section = nil;
    if (self.flickrDataSource.sections.count > 0) {
        section = [self.flickrDataSource.sections objectAtIndex:sectionIndex];
    }
    return section.photos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    INSection *section = [self.flickrDataSource.sections objectAtIndex:indexPath.section];
    INPhotoObject *photoObject = [section.photos objectAtIndex:indexPath.row];

    NSInteger rowCount = 0;
    for(NSInteger s = 0; s < indexPath.section; s++) {
        INSection *s2 = [self.flickrDataSource.sections objectAtIndex:s];
        rowCount += s2.photos.count;
    }
    self.maxRowSoFar = MAX(self.maxRowSoFar, rowCount + indexPath.row);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(loadNextSectionIfNecessary) withObject:0 afterDelay:0.1];

    NSURL *URL = [photoObject.dictionary URLForKey:@"url_t"];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = URL.absoluteString;
    if (URL != nil) {
        [[INThumbnailCache shared] decodeImageURL:URL forSize:CGSizeMake(100, 100) priority:nil downloadIfNecessary:YES cacheData:YES completion:^(UIImage *image)
         {
             ZG_ASSERT_IS_MAIN_THREAD();
             cell.imageView.image = image;
             [cell setNeedsLayout];
         }];
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
