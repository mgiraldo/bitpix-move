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
#import "InfoViewController.h"
#import "UserData.h"
#import "AppDelegate.h"

@interface MainViewController : UIViewController <DrawViewDelegate, GridViewControllerDelegate, InfoViewControllerDelegate>

@property (atomic) BOOL isRestoring;
@property (atomic) int currentFrame;
@property (atomic) BOOL isPreviewing;
@property (atomic) BOOL isClean;
@property (atomic) BOOL firstLoad;
@property (atomic) BOOL tappedAdd;
@property (atomic) BOOL tappedPreview;
@property (atomic) BOOL tappedStop;
@property (atomic) BOOL isVertical;
@property (atomic) NSInteger frameBuffer;

@property (nonatomic) AppDelegate *appDelegate;
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
@property (weak, nonatomic) IBOutlet UIView *mainActionsView;
@property (weak, nonatomic) IBOutlet UIView *mainActionsViewH;
@property (weak, nonatomic) IBOutlet UIView *frameActionsView;
@property (weak, nonatomic) IBOutlet UIView *frameActionsViewH;
@property (weak, nonatomic) IBOutlet UILabel *drawLabel;
@property (weak, nonatomic) IBOutlet UIButton *myAnimationsButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *addAnimationButton;

// horizontal ui
@property (weak, nonatomic) IBOutlet UIButton *myAnimationsButtonH;
@property (weak, nonatomic) IBOutlet UIButton *settingsButtonH;
@property (weak, nonatomic) IBOutlet UIButton *addAnimationButtonH;
@property (weak, nonatomic) IBOutlet UILabel *frameLabelH;
@property (weak, nonatomic) IBOutlet UIButton *deleteButtonH;
@property (weak, nonatomic) IBOutlet UIButton *undoButtonH;
@property (weak, nonatomic) IBOutlet UIButton *previewButtonH;
@property (weak, nonatomic) IBOutlet UIButton *stopPreviewButtonH;
@property (weak, nonatomic) IBOutlet UIButton *exportButtonH;
@property (weak, nonatomic) IBOutlet UIButton *previousButtonH;
@property (weak, nonatomic) IBOutlet UIButton *nextButtonH;
@property (weak, nonatomic) IBOutlet UIButton *addButtonH;

// IB contraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDistanceConstraint;

@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;


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

