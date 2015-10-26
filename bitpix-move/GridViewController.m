//
//  GridViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "GridViewController.h"
#import "ThumbnailCell.h"
#import "DrawView.h"
#import "DrawViewAnimator.h"
#import "Config.h"

@interface GridViewController ()

@end

@implementation GridViewController

static NSString * const reuseIdentifier = @"AnimationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appData = [[UserData alloc] initWithDefaultData];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[ThumbnailCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    [self buildThumbnails];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.collectionView reloadData];
}

- (void)buildThumbnails {
    int i;
    NSDictionary *animation;
    NSArray *frames;
    NSArray *lines;
    DrawView *drawView;

    NSFileManager *fm = [[NSFileManager alloc] init];

    for (i=0; i<self.appData.userAnimations.count; i++) {
        animation = (NSDictionary *)[self.appData.userAnimations objectAtIndex:i];
        // check if thumbnail exists
        BOOL dataExists = [fm fileExistsAtPath:[NSString stringWithFormat:@"%@_t.png",[animation objectForKey:@"name"]]];
        if (dataExists) continue;
        // get the frames
        frames = [NSArray arrayWithArray:[animation objectForKey:@"frames"]];
        // get the lines in the frame
        // only need the first to build the drawview
        lines = [NSArray arrayWithArray:[frames objectAtIndex:0]];
        // build the drawview
        drawView = [[DrawView alloc] initWithFrame:CGRectMake(0, 0, _animationSize, _animationSize)];
        drawView.lineList = [lines mutableCopy];
        drawView.uuid = [animation objectForKey:@"name"];
        [drawView createThumbnail];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    self.collectionView = nil;
    [super viewDidUnload];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onReturnTapped:(id)sender {
    [self.delegate gridViewControllerDidFinish:self];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.appData.userAnimations.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ThumbnailCell *cell = (ThumbnailCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    NSDictionary *animation = [self.appData.userAnimations objectAtIndex:indexPath.row];
    NSString *filename = [NSString stringWithFormat:@"%@_t.png", [animation objectForKey:@"name"]];

    // Configure the cell
    cell.filename = filename;

    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate gridViewControllerDidFinish:self withAnimationIndex:indexPath.row];
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval = CGSizeMake(_thumbSize, _thumbSize);
    return retval;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 0, 0, 0);
}

@end
