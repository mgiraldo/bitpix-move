//
//  GridViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UserData.h"

@class GridViewController;

@protocol GridViewControllerDelegate
- (void)gridViewControllerDidFinish:(GridViewController *)controller;
- (void)gridViewControllerDidFinish:(GridViewController *)controller withAnimationIndex:(int)index;
@end


@interface GridViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) id <GridViewControllerDelegate> delegate;
@property (nonatomic) UserData *appData;

- (IBAction)onReturnTapped:(id)sender;

@end
