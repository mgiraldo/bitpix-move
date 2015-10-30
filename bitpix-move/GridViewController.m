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
#import "MainViewController.h"

@interface GridViewController ()

@end

@implementation GridViewController

static NSString * const reuseIdentifier = @"AnimationCell";
static NSInteger _selectedRow;
static int _selectedAction;
static BOOL _deletedParentAnimation = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _deletedParentAnimation = NO;

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
    DebugLog(@"buildThumbnails");
    int i, j;
    NSDictionary *animation;
    NSArray *frames;
    NSMutableArray *drawViewArray;
    
    NSFileManager *fm = [[NSFileManager alloc] init];

    for (i=0; i<self.appData.userAnimations.count; i++) {
        animation = (NSDictionary *)[self.appData.userAnimations objectAtIndex:i];
        // check if thumbnail exists
        NSString *uuid = [animation objectForKey:@"name"];
        // get the frames
        frames = [NSArray arrayWithArray:[animation objectForKey:@"frames"]];

        NSArray *filelist= [fm contentsOfDirectoryAtPath:[UserData dataFilePath:uuid] error:nil];
        int count = [filelist count];

        if (count == frames.count) continue;
        DebugLog(@"frame difference");

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
    if (_deletedParentAnimation) {
        [self.delegate gridViewControllerDidFinish:self withAnimationIndex:-1];
    } else {
        [self.delegate gridViewControllerDidFinish:self];
    }
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
    NSString *uuid = [animation objectForKey:@"name"];
    
    // Configure the cell
    cell.duration = [NSArray arrayWithArray:[animation objectForKey:@"frames"]].count / _fps;
    cell.filename = uuid;

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

#pragma mark – Duplicate/delete stuff

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self removeAccessoryButtons];
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    DebugLog(@"long press");

    [self removeAccessoryButtons];

    CGPoint p = [recognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    
    if (indexPath == nil) {
        DebugLog(@"could not find index path");
    } else {
        _selectedRow = indexPath.row;

        ThumbnailCell *cell = (ThumbnailCell *)[self.collectionView cellForItemAtIndexPath:indexPath];

        UIImage *deleteImage = [UIImage imageNamed:@"delete"];
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat w = deleteImage.size.width;
        CGFloat h = deleteImage.size.height;
        self.deleteButton.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, w, h);
        [self.deleteButton setBackgroundImage:deleteImage forState:UIControlStateNormal];
        [self.collectionView addSubview:self.deleteButton];
        [self.collectionView bringSubviewToFront:self.deleteButton];
        [self.deleteButton addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];

        UIImage *duplicateImage = [UIImage imageNamed:@"duplicate"];
        self.duplicateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        w = duplicateImage.size.width;
        h = duplicateImage.size.height;
        self.duplicateButton.frame = CGRectMake(cell.frame.origin.x + cell.frame.size.width - w, cell.frame.origin.y, w, h);
        [self.duplicateButton setBackgroundImage:duplicateImage forState:UIControlStateNormal];
        [self.collectionView addSubview:self.duplicateButton];
        [self.collectionView bringSubviewToFront:self.duplicateButton];
        [self.duplicateButton addTarget:self action:@selector(duplicateTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        DebugLog(@"added: %@", cell);
    }
}

- (void)deleteTapped:(id)sender {
    _selectedAction = kDeleteAction;

    UIActionSheet *as = [[UIActionSheet alloc]
                         initWithTitle:nil
                         delegate:self
                         cancelButtonTitle:@"Cancel"
                         destructiveButtonTitle:[NSString stringWithFormat:@"Delete animation"]
                         otherButtonTitles:nil];
    [as showInView:self.view.superview];
}

- (void)duplicateTapped:(id)sender {
    _selectedAction = kDuplicateAction;
    
    UIActionSheet *as = [[UIActionSheet alloc]
                         initWithTitle:nil
                         delegate:self
                         cancelButtonTitle:@"Cancel"
                         destructiveButtonTitle:nil
                         otherButtonTitles:[NSString stringWithFormat:@"Duplicate animation"], nil];
    [as showInView:self.view.superview];
}

- (void)deleteAnimation {
    DebugLog(@"deleted: %d", _selectedRow);
    [self removeAccessoryButtons];
    if (_selectedRow == -1) return;
    [self.appData deleteAnimationAtIndex:_selectedRow];
    [self.collectionView reloadData];
    _selectedRow = -1;
}

- (void)duplicateAnimation {
    DebugLog(@"duplicated: %d", _selectedRow);
    [self removeAccessoryButtons];
    if (_selectedRow == -1) return;
    [self.appData duplicateAnimationAtIndex:_selectedRow];
    [self.collectionView reloadData];
    _selectedRow = -1;
}

- (void)removeAccessoryButtons {
    if (self.deleteButton != nil) {
        [self.deleteButton removeFromSuperview];
        self.deleteButton = nil;
    }
    
    if (self.duplicateButton != nil) {
        [self.duplicateButton removeFromSuperview];
        self.duplicateButton = nil;
    }
}

#pragma mark - Actionsheet stuff

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_selectedAction == kDeleteAction && buttonIndex == 0) {
        // check to see if it was the animation user was working on
        NSString *uuid = [[self.appData.userAnimations objectAtIndex:_selectedRow] objectForKey:@"name"];
        MainViewController *vc = (MainViewController *)self.delegate;
        if ([uuid isEqualToString:vc.uuid]) {
            _deletedParentAnimation = YES;
        }
        [self deleteAnimation];
    }

    if (_selectedAction == kDuplicateAction && buttonIndex == 0) {
        [self duplicateAnimation];
    }
}

@end
