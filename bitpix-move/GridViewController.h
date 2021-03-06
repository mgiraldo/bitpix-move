//
//  GridViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class GridViewController;

@protocol GridViewControllerDelegate
- (void)gridViewControllerDidFinish:(GridViewController *)controller;
- (void)gridViewControllerDidFinish:(GridViewController *)controller withAnimationIndex:(NSInteger)index;
@end


@interface GridViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (atomic) NSInteger selectedRow;
@property (atomic) int selectedAction;
@property (atomic) BOOL deletedParentAnimation;
@property (atomic) int currentDuplicates;

@property (atomic) AppDelegate *appDelegate;
@property (nonatomic) NSMutableArray *collectionData;
@property (nonatomic) UIButton *deleteButton;
@property (nonatomic) UIButton *duplicateButton;
@property (weak, nonatomic) IBOutlet UIView *borderView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property (nonatomic, weak) id <GridViewControllerDelegate> delegate;

- (IBAction)onReturnTapped:(id)sender;
- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer;

@end
