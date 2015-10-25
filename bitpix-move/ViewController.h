//
//  ViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"

@interface ViewController : UIViewController <DrawViewDelegate>

@property (nonatomic) NSMutableArray *framesArray;
@property (weak, nonatomic) IBOutlet UIView *sketchView;
@property (weak, nonatomic) IBOutlet UIImageView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UILabel *frameLabel;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *stopPreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;

- (IBAction)onNextTapped:(id)sender;
- (IBAction)onAddTapped:(id)sender;
- (IBAction)onPreviousTapped:(id)sender;
- (IBAction)onPreviewTapped:(id)sender;
- (IBAction)onExportTapped:(id)sender;
- (IBAction)onDeleteTapped:(id)sender;
- (IBAction)onStopPreviewTapped:(id)sender;
- (IBAction)onUndoTapped:(id)sender;
@end

