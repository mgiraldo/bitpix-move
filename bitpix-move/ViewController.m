//
//  ViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "ViewController.h"
#import "UIImageXtras.h"
#import "Config.h"

@interface ViewController ()

@end

@implementation ViewController

static int _currentFrame = -1;
static BOOL _isPreviewing = NO;

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.appData = [[UserData alloc] initWithDefaultData];
    
    // the next id will be the count
    self.uuid = [[NSUUID UUID] UUIDString];
    
    self.exportButton.enabled = NO;
    self.stopPreviewButton.hidden = YES;
    self.previewView.hidden = YES;
    self.undoButton.hidden = YES;
	self.sketchView.backgroundColor = [UIColor whiteColor];
    self.sketchView.layer.borderColor = [UIColor blackColor].CGColor;
    self.sketchView.layer.borderWidth = _borderWidth;
	[self newAnimation];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Preview stuff

- (void)showPreview {
    _isPreviewing = YES;
    [self disableUI];
    self.previewButton.hidden = YES;
    self.stopPreviewButton.hidden = NO;
    self.previewView.hidden = NO;
    
    [self.previewView createFrames:self.framesArray];
    self.previewView.speed = _fps;
    [self.previewView animate];
}

- (void)stopPreview {
    self.previewView.image = nil;
    self.stopPreviewButton.hidden = YES;
    self.previewButton.hidden = NO;
    self.previewView.hidden = YES;
    _isPreviewing = NO;
    [self updateUI];
}

#pragma mark - Load/new/save stuff

- (void)newAnimation {
    // new name for animation
    self.uuid = [[NSUUID UUID] UUIDString];
    // cleanup
    [self removeFrames];
    _currentFrame = -1;
    [self addFrame];
}

- (void)loadAnimation:(int)index {
    DebugLog(@"load: %i", index);
    NSDictionary *animation = [self.appData.userAnimations objectAtIndex:index];
    // new name for animation
    self.uuid = [animation objectForKey:@"name"];
    // cleanup
    [self removeFrames];
    // add frames
    NSArray *frames = [NSArray arrayWithArray:[animation objectForKey:@"frames"]];
    for (int i=0; i<frames.count; i++) {
        NSArray *lines = [NSArray arrayWithArray:[frames objectAtIndex:i]];
        DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
        drawView.uuid = self.uuid;
        drawView.delegate = self;
        drawView.lineList = [lines mutableCopy];
        [self.framesArray addObject:drawView];
        if (i==0) {
            [drawView drawLines];
            [self.sketchView addSubview:drawView];
        }
    }
    _currentFrame = 0;
    [self updateUI];
}

- (void)saveToDisk {
    // update disk version of animation
    NSDate *today = [NSDate date];
    
    NSMutableArray *frames = [@[] mutableCopy];
    for (int i = 0; i < self.framesArray.count; i++) {
        DrawView *drawView = [self.framesArray objectAtIndex:i];
        [frames addObject:drawView.lineList];
    }
    
    NSDictionary *animationInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.uuid, today, frames, nil] forKeys:[NSArray arrayWithObjects:@"name", @"date", @"frames", nil]];
    
    int index = [self.appData.userAnimations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *animation = (NSDictionary *)obj;
        BOOL found = [[animation objectForKey:@"name"] isEqualToString:self.uuid];
        return found;
    }];
    
    if (index == NSNotFound) {
        // a new animation
        [self.appData.userAnimations addObject:animationInfo];
    } else {
        // old animation
        [self.appData.userAnimations replaceObjectAtIndex:index withObject:animationInfo];
    }
    
    [self.appData save];
    
    [self createThumbnail];
}

- (void)createThumbnail {
    DrawView *drawView = [self.framesArray objectAtIndex:0];
    [drawView createThumbnail];
}

#pragma mark - Frame stuff

- (void)removeFrames {
    [[self.sketchView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.framesArray = [@[] mutableCopy];
}

- (void)drawViewChanged:(DrawView *)drawView {
    [self updateUndoButtonForDrawView:drawView];
    [self performSelectorInBackground:@selector(saveToDisk) withObject:nil];
}

- (void)addFrame {
    _currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.uuid = self.uuid;
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

#pragma mark - UI/undo stuff

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
    if (_isPreviewing) {
        [self stopPreview];
    }
//    __block ViewController *weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        // in case we want to wait until finished
    }];
    [self loadAnimation:index];
}

#pragma mark - Button actions

- (IBAction)onMyAnimationsTapped:(id)sender {
    [self performSegueWithIdentifier:@"viewGrid" sender:self];
}

- (IBAction)onNewTapped:(id)sender {
    if (_isPreviewing) {
        [self stopPreview];
    }
    [self newAnimation];
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
