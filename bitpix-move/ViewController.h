//
//  ViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic) NSMutableArray *framesArray;
@property (weak, nonatomic) IBOutlet UIView *sketchView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;

- (IBAction)onNextTapped:(id)sender;
- (IBAction)onAddTapped:(id)sender;
- (IBAction)onPreviousTapped:(id)sender;
@end

