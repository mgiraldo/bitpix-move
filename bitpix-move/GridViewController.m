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
static NSInteger _deletedRow;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appData = [[UserData alloc] initWithDefaultData];

    [self buildThumbnails];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    recognizer.minimumPressDuration = 0.5;
    recognizer.delaysTouchesBegan = YES;
    recognizer.delegate = self;
    [self.collectionView addGestureRecognizer:recognizer];
    
    // Register cell classes
    [self.collectionView registerClass:[ThumbnailCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.collectionView reloadData];
}

- (void)buildThumbnails {
    int i, j;
    NSDictionary *animation;
    NSArray *frames;
    NSMutableArray *drawViewArray;
    
    NSFileManager *fm = [[NSFileManager alloc] init];

    for (i=0; i<self.appData.userAnimations.count; i++) {
        animation = (NSDictionary *)[self.appData.userAnimations objectAtIndex:i];
        // check if thumbnail exists
        NSString *uuid = [animation objectForKey:@"name"];

        NSString *filename = [NSString stringWithFormat:@"%@/%@_t0.png", uuid, uuid];
        NSString *filePath = [UserData dataFilePath:filename];
        BOOL dataExists = [fm fileExistsAtPath:filePath];
        if (dataExists) continue;
        DebugLog(@"no frames: %@", filePath);

        // get the frames
        frames = [NSArray arrayWithArray:[animation objectForKey:@"frames"]];
        drawViewArray = [@[] mutableCopy];
        for (j=0; j<frames.count; j++) {
            NSArray *lines = [NSArray arrayWithArray:[frames objectAtIndex:j]];
            DrawView *drawView = [[DrawView alloc] initWithFrame:CGRectMake(0, 0, _animationSize, _animationSize)];
            drawView.uuid = uuid;
            drawView.lineList = [lines mutableCopy];
            [drawViewArray addObject:drawView];
        }
        DrawViewAnimator *animator = [[DrawViewAnimator alloc] initWithFrame:CGRectMake(0, 0, _animationSize, _animationSize)];
        animator.uuid = uuid;
        [animator createFrames:drawViewArray withSpeed:_fps];
        [animator createAllGIFs];
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
    NSDictionary *uuid = [animation objectForKey:@"name"];
    NSString *filename = [NSString stringWithFormat:@"%@/%@_t", uuid, uuid];
    NSString *filePath = [UserData dataFilePath:filename];
    
    // Configure the cell
    cell.duration = [NSArray arrayWithArray:[animation objectForKey:@"frames"]].count / _fps;
    cell.filename = filePath;

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
    return UIEdgeInsetsMake(20, 10, 50, 10);
}

#pragma mark – Long press stuff

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    DebugLog(@"scroll");
    if (self.deleteButton != nil) {
        [self.deleteButton removeFromSuperview];
        self.deleteButton = nil;
    }
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    DebugLog(@"long press");
    if (recognizer.state != UIGestureRecognizerStateEnded) return;

    if (self.deleteButton != nil) {
        [self.deleteButton removeFromSuperview];
        self.deleteButton = nil;
    }
    
    CGPoint p = [recognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    
    if (indexPath == nil) {
        DebugLog(@"could not find index path");
    } else {
        ThumbnailCell *cell = (ThumbnailCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        UIImage *deleteImage = [UIImage imageNamed:@"delete"];
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deletedRow = indexPath.row;
        CGFloat w = deleteImage.size.width;
        CGFloat h = deleteImage.size.height;
        self.deleteButton.frame = CGRectMake(cell.frame.origin.x - w*.5, cell.frame.origin.y - h*.25, w, h);
        [self.deleteButton setBackgroundImage:deleteImage forState:UIControlStateNormal];
        [self.collectionView addSubview:self.deleteButton];
        [self.collectionView bringSubviewToFront:self.deleteButton];
        [self.deleteButton addTarget:self action:@selector(deleteAnimation:) forControlEvents:UIControlEventTouchUpInside];
        DebugLog(@"added: %@", cell);
    }
}

- (void)deleteAnimation:(id)sender {
    DebugLog(@"deleted: %d", _deletedRow);
    [self.deleteButton removeFromSuperview];
    self.deleteButton = nil;
    if (_deletedRow == -1) return;
    [self.appData deleteAnimationAtIndex:_deletedRow];
    [self.collectionView reloadData];
    _deletedRow = -1;
}

@end
