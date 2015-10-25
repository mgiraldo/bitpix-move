//
//  ViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

static const float _borderWidth = 5.0f;
static int _currentFrame = -1;
static const int _maxFrames = 100;
static float _fps = 2.0f;
static BOOL _isPreviewing = NO;

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.uuid = [[NSUUID UUID] UUIDString];

    self.appData = [[UserData alloc] initWithDefaultData];
    
    self.stopPreviewButton.hidden = YES;
    self.previewView.hidden = YES;
    self.undoButton.hidden = YES;
	self.sketchView.backgroundColor = [UIColor whiteColor];
    self.sketchView.layer.borderColor = [UIColor blackColor].CGColor;
    self.sketchView.layer.borderWidth = _borderWidth;
	self.framesArray = [[NSMutableArray alloc] initWithCapacity:1];
	[self addFrame];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)showPreview {
    _isPreviewing = YES;
    [self disableUI];
    self.previewButton.hidden = YES;
    self.stopPreviewButton.hidden = NO;
    self.previewView.hidden = NO;

    [self.previewView animateWithFrames:self.framesArray andSpeed:_fps];
}

- (void)stopPreview {
    self.previewView.image = nil;
    self.stopPreviewButton.hidden = YES;
    self.previewButton.hidden = NO;
    self.previewView.hidden = YES;
    _isPreviewing = NO;
    [self updateUI];
}

- (void)drawViewChanged:(DrawView *)drawView {
    [self updateUndoButtonForDrawView:drawView];
    [self saveToDisk];
}

- (void)saveToDisk {
    // update disk version of animation
    NSDate *today = [NSDate date];

    NSMutableArray *frames = [@[] mutableCopy];
    for (int i = 0; i < self.framesArray.count; i++) {
        DrawView *drawView = [self.framesArray objectAtIndex:i];
        [frames addObject:drawView.lineList];
    }

    NSDictionary *animationInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:today, frames, nil] forKeys:[NSArray arrayWithObjects:@"date", @"frames", nil]];
    [self.appData.userAnimations setObject:animationInfo forKey:self.uuid];
    [self.appData save];
}

- (void)addFrame {
    _currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.delegate = self;
    [self.framesArray insertObject:drawView atIndex:_currentFrame];
    [self.sketchView addSubview:drawView];
    [self updateUI];
}

- (void)deleteCurrentFrame {
    // dispose of view
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [drawView removeFromSuperview];

    // dispose of object in array
    [self.framesArray removeObjectAtIndex:_currentFrame];

    if (_currentFrame == 0) {
        // we removed the first frame
        drawView = [self.framesArray objectAtIndex:_currentFrame];
        [self.sketchView addSubview:drawView];
    } else {
        _currentFrame--;
    }

    [self updateUI];
}

- (void)nextFrame {
    _currentFrame++;
    if (_currentFrame > self.framesArray.count) _currentFrame = (int)self.framesArray.count - 1;
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [self.sketchView addSubview:drawView];
    [self updateUI];
}

- (void)prevFrame {
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [drawView removeFromSuperview];
    _currentFrame--;
    if (_currentFrame < 0) _currentFrame = 0;
    [self updateUI];
}

- (void)updateUI {
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [self updateUndoButtonForDrawView:drawView];

    if (_currentFrame <= 0) {
        self.previousButton.enabled = NO;
    } else {
        self.previousButton.enabled = YES;
    }

    if (_currentFrame >= self.framesArray.count-1) {
        self.nextButton.enabled = NO;
    } else {
        self.nextButton.enabled = YES;
    }
    
    if (self.framesArray.count > _maxFrames) {
        self.addButton.enabled = NO;
    } else {
        self.addButton.enabled = YES;
    }

    if (self.framesArray.count > 1) {
        self.deleteButton.enabled = YES;
    } else {
        self.deleteButton.enabled = NO;
    }

    self.frameLabel.text = [NSString stringWithFormat:@"Frame: %i/%i", _currentFrame+1, (int)self.framesArray.count];
}

- (void)disableUI {
    self.previousButton.enabled = NO;
    self.nextButton.enabled = NO;
    self.addButton.enabled = NO;
    self.undoButton.hidden = YES;
}

- (void)updateUndoButtonForDrawView:(DrawView *)drawView {
    if ([drawView hasLines]) {
        self.undoButton.hidden = NO;
    } else {
        self.undoButton.hidden = YES;
    }
}

- (void)undo {
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [drawView undo];
    [self updateUI];
}

#pragma mark - Grid view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //	NSLog(@"prepare for segue: [%@] sender: [%@]", [segue identifier], sender);
    if ([[segue identifier] isEqualToString:@"viewGrid"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller withAnimationIndex:(int)index {
    [self dismissViewControllerAnimated:YES completion:^{
        // TODO: draw the selected animation
    }];
}

#pragma mark - Button actions

- (IBAction)onMyAnimationsTapped:(id)sender {
    [self performSegueWithIdentifier:@"viewGrid" sender:self];
}

- (IBAction)onNextTapped:(id)sender {
    [self nextFrame];
}

- (IBAction)onPreviousTapped:(id)sender {
    [self prevFrame];
}

- (IBAction)onAddTapped:(id)sender {
	[self addFrame];
}

- (IBAction)onDeleteTapped:(id)sender {
    [self deleteCurrentFrame];
}

- (IBAction)onStopPreviewTapped:(id)sender {
    [self stopPreview];
}

- (IBAction)onUndoTapped:(id)sender {
    [self undo];
}

- (IBAction)onPreviewTapped:(id)sender {
    [self showPreview];
}

- (IBAction)onExportTapped:(id)sender {
}

@end
