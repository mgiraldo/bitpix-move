//
//  ViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"

@interface ViewController ()

@end

@implementation ViewController

static int _currentFrame = -1;
static const int _maxFrames = 100;
static const int _fps = 2;
static BOOL _isPreviewing = NO;

- (void)viewDidLoad {
	[super viewDidLoad];
    self.stopPreviewButton.hidden = YES;
	self.sketchView.backgroundColor = [UIColor whiteColor];
	self.framesArray = [[NSMutableArray alloc] initWithCapacity:1];
	[self addFrame];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)showPreview {
    _currentFrame = 0;
    _isPreviewing = YES;
    [self disableUI];
    self.previewButton.hidden = YES;
    self.stopPreviewButton.hidden = NO;
    self.previewTimer = [NSTimer scheduledTimerWithTimeInterval:1/_fps target:self selector:@selector(playPreview:) userInfo:nil repeats:YES];
}

- (void)stopPreview {
    [self.previewTimer invalidate];
    self.previewTimer = nil;
    self.stopPreviewButton.hidden = YES;
    self.previewButton.hidden = NO;
    _isPreviewing = NO;
    [self updateUI];
}

- (void)playPreview:(NSTimer *)timer {
    if (_currentFrame == 0) {
        [[self.sketchView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }

    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [self.sketchView addSubview:drawView];

    _currentFrame++;
    
    if (_currentFrame >= self.framesArray.count) {
        _currentFrame = 0;
    }
}

- (void)addFrame {
    _currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
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
    if (_currentFrame > self.framesArray.count) _currentFrame = self.framesArray.count - 1;
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
    
    self.frameLabel.text = [NSString stringWithFormat:@"%i/%i", _currentFrame+1, self.framesArray.count];
}

- (void)disableUI {
    self.previousButton.enabled = NO;
    self.nextButton.enabled = NO;
    self.addButton.enabled = NO;
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

- (IBAction)onPreviewTapped:(id)sender {
    [self showPreview];
}

- (IBAction)onExportTapped:(id)sender {
}

@end
