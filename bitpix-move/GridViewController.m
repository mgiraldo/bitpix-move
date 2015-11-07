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
#import "UserData.h"

@interface GridViewController ()

@end

@implementation GridViewController

static NSString * const reuseIdentifier = @"AnimationCell";
static NSInteger _selectedRow;
static int _selectedAction;
static BOOL _deletedParentAnimation = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusView.hidden = YES;

    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.collectionData = [@[] mutableCopy];
    
    for (id obj in self.appDelegate.appData.userAnimations) {
        [self.collectionData addObject:[obj valueForKey:@"name"]];
    }
    
    if (self.collectionData.count == 0) {
        self.refreshView.hidden = YES;
    } else {
        self.refreshView.hidden = NO;
    }

    _deletedParentAnimation = NO;

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

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [self.collectionView reloadData];
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

- (IBAction)onRefreshTapped:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Refresh thumbnails"
                                                                   message:@"Tap “Refresh” If the thumbnails you see do not match your animation. None of your animations will be modified. This may take a while depending on how many animations you have."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Refresh" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self refreshThumbnails];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - Status stuff

- (void)removeStatusLabel {
    self.statusLabel.text = @"";
    self.statusView.hidden = YES;
}

- (void)refreshThumbnails {
    NSArray *emojiArray = @[@"👯", @"💁", @"👻", @"🙃", @"😶", @"🤖", @"👾"];
    int emojiCount = (int)emojiArray.count;
    srand ((int)time(NULL));
    int index = rand()%emojiCount;
    NSString *emoji = [emojiArray objectAtIndex:index];
    self.statusLabel.text = [NSString stringWithFormat:@"Performing GIFness. This may take a while depending on how many animations you have. In the meantime, enjoy some emoji:\n\n%@", emoji];
    self.statusView.hidden = NO;
    
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        [self dispatchedRefresh];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeStatusLabel];
            [self.collectionView reloadData];
        });
    });
}

- (void)dispatchedRefresh {
    int i;
    NSDictionary *animation;
    NSArray *frames;
    NSMutableArray *drawViewArray;
    
    NSInteger animationCount = self.appDelegate.appData.userAnimations.count;
    
    [UserData emptyUserFolder];
    
    for (i=0; i<animationCount; i++) {
        animation = (NSDictionary *)[self.appDelegate.appData.userAnimations objectAtIndex:i];
        // check if thumbnail exists
        NSString *uuid = [animation objectForKey:@"name"];
        [self.appDelegate.appData removeThumbnailsForUUID:uuid];
        // get the frames
        frames = [NSArray arrayWithArray:[animation objectForKey:@"frames"]];
        
        drawViewArray = [@[] mutableCopy];
        for (int j=0; j<frames.count; j++) {
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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.collectionData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ThumbnailCell *cell = (ThumbnailCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    NSString *uuid = [self.collectionData objectAtIndex:indexPath.row];
    
    NSUInteger index = [self.appDelegate.appData.userAnimations indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *animation = (NSDictionary *)obj;
        BOOL found = [[animation objectForKey:@"name"] isEqualToString:uuid];
        return found;
    }];
    
    // update the cell
    cell.backgroundColor = [UIColor whiteColor];
    if (index != NSNotFound) {
        // Configure the cell
        cell.duration = [NSArray arrayWithArray:[[self.appDelegate.appData.userAnimations objectAtIndex:index] objectForKey:@"frames"]].count / _fps;
        cell.filename = uuid;
    } else {
        if (cell.thumbnailView != nil) {
            [cell.thumbnailView removeFromSuperview];
            cell.thumbnailView = nil;
        }
    }

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
    return UIEdgeInsetsMake(50, 10, 100, 10);
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
    }
}

- (void)deleteTapped:(id)sender {
    _selectedAction = kDeleteAction;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Delete animation" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              // check to see if it was the animation user was working on
                                                              NSString *uuid = [[self.appDelegate.appData.userAnimations objectAtIndex:_selectedRow] objectForKey:@"name"];
                                                              MainViewController *vc = (MainViewController *)self.delegate;
                                                              if ([uuid isEqualToString:vc.uuid]) {
                                                                  _deletedParentAnimation = YES;
                                                              }
                                                              [self deleteAnimation];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)duplicateTapped:(id)sender {
    _selectedAction = kDuplicateAction;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Duplicate animation" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self duplicateAnimation];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)deleteAnimation {
    DebugLog(@"deleted: %ld", (long)_selectedRow);
    [self removeAccessoryButtons];
    
    if (_selectedRow == -1) return;

    NSInteger originalIndex = _selectedRow;
    NSString *uuuid = [self.collectionData objectAtIndex:originalIndex];
    [self.collectionData removeObjectAtIndex:originalIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:originalIndex inSection:0];
    NSArray *indexes = [NSArray arrayWithObject:indexPath];
    [self.collectionView deleteItemsAtIndexPaths:indexes];
    [self.collectionView reloadData];

    if (self.collectionData.count == 0) {
        self.refreshView.hidden = YES;
    } else {
        self.refreshView.hidden = NO;
    }
    
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(indexPath) {
            [self.appDelegate.appData deleteAnimationAtIndex:originalIndex];
        }
        [self.appDelegate.appData deleteFilesWithUUID:uuuid];
    });

    _selectedRow = -1;
}

- (void)duplicateAnimation {
    DebugLog(@"duplicated: %ld", (long)_selectedRow);
    [self removeAccessoryButtons];

    if (_selectedRow == -1) return;

    NSInteger originalIndex = _selectedRow;
    NSInteger newIndex = self.collectionData.count;
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self.collectionData addObject:uuid];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
    NSArray *indexes = [NSArray arrayWithObject:indexPath];
    [self.collectionView insertItemsAtIndexPaths:indexes];
    [self.collectionView reloadData];
    
    
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        __block NSDictionary *duplicationOutput;
        __block NSString *olduuid;
        __block NSNumber *frameCount;
        @synchronized(indexPath) {
            duplicationOutput = [self.appDelegate.appData duplicateAnimationAtIndex:originalIndex withUUID:uuid];
            olduuid = [duplicationOutput objectForKey:@"olduuid"];
            frameCount = [duplicationOutput objectForKey:@"frameCount"];
        }
        [self.appDelegate.appData copyFilesFrom:olduuid to:uuid withCount:frameCount.integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{

            NSUInteger index = [self.appDelegate.appData.userAnimations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *animation = (NSDictionary *)obj;
                BOOL found = [[animation objectForKey:@"name"] isEqualToString:uuid];
                return found;
            }];
            
            if (index != NSNotFound) {
                NSIndexPath *iPath = [NSIndexPath indexPathForRow:index inSection:0];
                ThumbnailCell *cell = (ThumbnailCell *)[self.collectionView cellForItemAtIndexPath:iPath];
                if (cell) {
                    cell.duration = [NSArray arrayWithArray:[[self.appDelegate.appData.userAnimations objectAtIndex:index] objectForKey:@"frames"]].count / _fps;
                    cell.filename = uuid;
                    [cell setNeedsLayout];
                }
            }

            [self.collectionView reloadData];
        });
    });

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

@end
