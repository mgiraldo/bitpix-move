//
//  MainViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"
#import "DrawViewAnimator.h"
#import "GridViewController.h"
#import "UserData.h"

@interface MainViewController : UIViewController <DrawViewDelegate, GridViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic) UserData *appData;
@property (nonatomic) NSMutableArray *framesArray;
@property (nonatomic) NSString  *uuid;
@property (weak, nonatomic) IBOutlet UIView *sketchView;
@property (weak, nonatomic) IBOutlet DrawViewAnimator *previewView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UILabel *frameLabel;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *stopPreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIButton *myAnimationsButton;

- (IBAction)onNextTapped:(id)sender;
- (IBAction)onAddTapped:(id)sender;
- (IBAction)onPreviousTapped:(id)sender;
- (IBAction)onPreviewTapped:(id)sender;
- (IBAction)onExportTapped:(id)sender;
- (IBAction)onDeleteTapped:(id)sender;
- (IBAction)onStopPreviewTapped:(id)sender;
- (IBAction)onUndoTapped:(id)sender;
- (IBAction)onMyAnimationsTapped:(id)sender;
- (IBAction)onNewTapped:(id)sender;

@end

