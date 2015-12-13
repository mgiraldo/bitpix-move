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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateTheme];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *temp = [@[] mutableCopy];
    
    for (id obj in self.appDelegate.appData.userAnimations) {
        [temp addObject:[@{@"name":[obj valueForKey:@"name"], @"duplicating":@NO} mutableCopy]];
    }
    
    self.collectionData = [[[temp reverseObjectEnumerator] allObjects] mutableCopy];
    
    self.collectionView.scrollsToTop = YES;
    
    self.deletedParentAnimation = NO;
    self.currentDuplicates = 0;

    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    recognizer.minimumPressDuration = 0.5;
    recognizer.delaysTouchesBegan = YES;
    recognizer.delegate = self;
    [self.collectionView addGestureRecognizer:recognizer];
    
    // Register cell classes
    [self.collectionView registerClass:[ThumbnailCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    if (self.deletedParentAnimation) {
        [self.delegate gridViewControllerDidFinish:self withAnimationIndex:-1];
    } else {
        [self.delegate gridViewControllerDidFinish:self];
    }
}

- (void)updateTheme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isBlack = [[defaults valueForKey:@"blackTheme"] boolValue];
    UIColor *tintColor;
    UIColor *bgColor;
    
    if (isBlack) {
        tintColor = [UIColor whiteColor];
        bgColor = [UIColor blackColor];
    } else {
        tintColor = [UIColor blackColor];
        bgColor = [UIColor whiteColor];
    }
    
    [self.view setBackgroundColor:bgColor];
    [self.view setTintColor:tintColor];
    self.returnButton.backgroundColor = bgColor;
    self.returnButton.tintColor = tintColor;
    self.borderView.backgroundColor = tintColor;
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

    NSString *uuid = [[self.collectionData objectAtIndex:indexPath.row] valueForKey:@"name"];
    
    NSUInteger index = [self.appDelegate.appData.userAnimations indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *animation = (NSDictionary *)obj;
        BOOL found = [[animation objectForKey:@"name"] isEqualToString:uuid];
        return found;
    }];
    
    // update the cell
    cell.backgroundColor = [UIColor whiteColor];
    if (index != NSNotFound) {
        // Configure the cell
        NSArray * frames = [[self.appDelegate.appData.userAnimations objectAtIndex:index] objectForKey:@"frames"];
        cell.frameCount = frames.count;
        cell.duration = frames.count / _fps;
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
    if (self.currentDuplicates > 0) return;
    NSInteger realIndex = self.collectionData.count - (indexPath.row + 1);
    [self.delegate gridViewControllerDidFinish:self withAnimationIndex:realIndex];
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
    return UIEdgeInsetsMake(30, 5, 100, 5);
}

#pragma mark – Duplicate/delete stuff

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self removeAccessoryButtons];
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
//    DebugLog(@"long press");

    [self removeAccessoryButtons];

    CGPoint p = [recognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    
    if (indexPath == nil) {
        DebugLog(@"could not find index path");
    } else {
        BOOL duplicating = [[[self.collectionData objectAtIndex:indexPath.row] valueForKey:@"duplicating"] boolValue];
        if (duplicating) return;

        self.selectedRow = indexPath.row;

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
    self.selectedAction = kDeleteAction;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Delete animation" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              // check to see if it was the animation user was working on
                                                              NSInteger realIndex = self.collectionData.count - (self.selectedRow+1);
                                                              NSString *uuid = [[self.appDelegate.appData.userAnimations objectAtIndex:realIndex] objectForKey:@"name"];
                                                              MainViewController *vc = (MainViewController *)self.delegate;
                                                              if ([uuid isEqualToString:vc.uuid]) {
                                                                  self.deletedParentAnimation = YES;
                                                              }
                                                              [self deleteAnimation];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)duplicateTapped:(id)sender {
    self.selectedAction = kDuplicateAction;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Duplicate animation" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self duplicateAnimation];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)deleteAnimation {
    DebugLog(@"deleted: %ld", (long)self.selectedRow);
    [self removeAccessoryButtons];
    
    if (self.selectedRow == -1) return;

    NSInteger originalIndex = self.selectedRow;
    NSString *uuid = [[self.collectionData objectAtIndex:originalIndex] valueForKey:@"name"];
    [self.collectionData removeObjectAtIndex:originalIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:originalIndex inSection:0];
    NSArray *indexes = [NSArray arrayWithObject:indexPath];
    [self.collectionView deleteItemsAtIndexPaths:indexes];

    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(self.appDelegate.appData) {
            [self.appDelegate.appData deleteAnimationWithUUID:uuid];
        }
        [self.appDelegate.appData deleteFilesWithUUID:uuid];
    });

    self.selectedRow = -1;
}

- (void)checkForReturnShow {
    if (self.currentDuplicates <= 0) {
        self.returnButton.enabled = YES;
    }
}

- (void)duplicateAnimation {
    DebugLog(@"duplicated: %ld", (long)self.selectedRow);
    [self removeAccessoryButtons];

    if (self.selectedRow == -1) return;
    
    self.returnButton.enabled = NO;
    self.currentDuplicates++;

    NSInteger originalIndex = self.selectedRow;
    // put it "after" the current one (showing in reverse order so -1)
    NSInteger newIndex = self.selectedRow;
    __block NSString *olduuid = [[self.collectionData objectAtIndex:originalIndex] valueForKey:@"name"];
    __block NSString *uuid = [[NSUUID UUID] UUIDString];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];
    NSArray *indexes = [NSArray arrayWithObject:indexPath];
    [[self.collectionData objectAtIndex:originalIndex] setValue:@YES forKey:@"duplicating"];
    [self.collectionData insertObject:[@{@"name":uuid, @"duplicating":@YES} mutableCopy] atIndex:newIndex];
    [self.collectionView insertItemsAtIndexPaths:indexes];
    
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        __block NSDictionary *duplicationOutput;
        __block NSNumber *frameCount;
        @synchronized(self.appDelegate.appData) {
            duplicationOutput = [self.appDelegate.appData duplicateAnimationWithUUID:olduuid withUUID:uuid];
            frameCount = [duplicationOutput objectForKey:@"frameCount"];
        }
        [self.appDelegate.appData copyFilesFrom:olduuid to:uuid withCount:frameCount.integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentDuplicates--;
            [self checkForReturnShow];
            NSUInteger index = [self.appDelegate.appData.userAnimations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *animation = (NSDictionary *)obj;
                BOOL found = [[animation objectForKey:@"name"] isEqualToString:uuid];
                return found;
            }];

            NSUInteger indexParent = [self.appDelegate.appData.userAnimations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *animation = (NSDictionary *)obj;
                BOOL found = [[animation objectForKey:@"name"] isEqualToString:olduuid];
                return found;
            }];
            
            if (indexParent != NSNotFound) {
                NSInteger parentIndex = self.collectionData.count - (indexParent+1);
                [[self.collectionData objectAtIndex:parentIndex] setObject:@NO forKey:@"duplicating"];
            }

            if (index != NSNotFound) {
                NSInteger realIndex = self.collectionData.count - (index+1);
                [[self.collectionData objectAtIndex:realIndex] setObject:@NO forKey:@"duplicating"];
                NSIndexPath *iPath = [NSIndexPath indexPathForRow:realIndex inSection:0];
                ThumbnailCell *cell = (ThumbnailCell *)[self.collectionView cellForItemAtIndexPath:iPath];

                if (cell) {
                    NSArray *frames = [NSArray arrayWithArray:[[self.appDelegate.appData.userAnimations objectAtIndex:index] objectForKey:@"frames"]];
                    NSInteger frameCount = frames.count;
                    cell.duration = frameCount / _fps;
                    cell.frameCount = frameCount;
                    cell.filename = uuid;
                    [cell setNeedsLayout];
                }
            }
        });
    });

    self.selectedRow = -1;
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
