//
//  MainViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "MainViewController.h"
#import "UIImageXtras.h"
#import "Config.h"

@interface MainViewController ()

@end

@implementation MainViewController

static int _currentFrame = -1;
static BOOL _isPreviewing = NO;
static BOOL _isClean = YES;

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.appData = [[UserData alloc] initWithDefaultData];
    
    // the next id will be the count
    self.uuid = [[NSUUID UUID] UUIDString];
    self.previewView.uuid = self.uuid;
    
    self.stopPreviewButton.hidden = YES;
    self.previewView.hidden = YES;
    self.undoButton.hidden = YES;
    self.deleteButton.hidden = YES;
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

    [self clean];
    [self.previewView animate];
    [self performSelectorInBackground:@selector(saveToDisk) withObject:nil];
}

- (void)stopPreview {
    [self.previewView stop];
    self.stopPreviewButton.hidden = YES;
    self.previewButton.hidden = NO;
    self.previewView.hidden = YES;
    _isPreviewing = NO;
    [self updateUI];
}

#pragma mark - Load/new/save stuff

- (void)newAnimation {
    if (_isPreviewing) {
        [self stopPreview];
    }
    // new name for animation
    self.uuid = [[NSUUID UUID] UUIDString];
    [self.previewView resetWithNewUUID:self.uuid];
    // cleanup
    [self removeFrames];
    _currentFrame = -1;
    [self addFrame];
}

- (void)loadAnimation:(NSInteger)index {
    DebugLog(@"load: %li", (long)index);
    NSDictionary *animation = [self.appData.userAnimations objectAtIndex:index];
    // new name for animation
    self.uuid = [animation objectForKey:@"name"];
    [self.previewView resetWithNewUUID:self.uuid];
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
    [self.previewView createFrames:self.framesArray withSpeed:_fps];
    _isClean = YES;
    _currentFrame = 0;
    [self updateUI];
    [self showPreview];
}

- (void)saveToDisk {
    // ignore if empty
    if (self.framesArray.count == 0) return;
    DrawView *drawView = [self.framesArray objectAtIndex:0];
    // do not save if only one frame that is clean
    if (self.framesArray.count == 1 && [drawView isClean]) return;

    // update disk version of animation
    NSDate *today = [NSDate date];
    
    NSMutableArray *frames = [@[] mutableCopy];
    for (int i = 0; i < self.framesArray.count; i++) {
        DrawView *drawView = [self.framesArray objectAtIndex:i];
        [frames addObject:drawView.lineList];
    }
    
    NSDictionary *animationInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.uuid, today, frames, nil] forKeys:[NSArray arrayWithObjects:@"name", @"date", @"frames", nil]];
    
    NSUInteger index = [self.appData.userAnimations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
}

- (void)clean {
    if (!_isClean) {
        _isClean = YES;
        [self.previewView createFrames:self.framesArray withSpeed:_fps];
        [self.previewView createAllGIFs];
        [self saveToDisk];
    }
}

- (void)export {
    [self clean];

    NSString *textToShare = @"Check out this GIF I created with MovePix!";
    
    NSArray *objectsToShare;
    
    NSString *filename = [NSString stringWithFormat:@"%@.gif", self.uuid];
    NSString *path = [UserData dataFilePath:filename];
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    
    objectsToShare = @[textToShare, fileData];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                      applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypePrint,
                                   UIActivityTypeCopyToPasteboard, // TODO: maybe fix this exclusion in the future
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToTencentWeibo];
    
    activityViewController.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityViewController
                       animated:YES
                     completion:^{}];
}

#pragma mark - Frame stuff

- (void)removeFrames {
    [[self.sketchView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.framesArray = [@[] mutableCopy];
}

- (void)drawViewChanged:(DrawView *)drawView {
    _isClean = NO;
    [self updateUndoButtonForDrawView:drawView];
    [self.framesArray replaceObjectAtIndex:_currentFrame withObject:drawView];
    [self performSelectorInBackground:@selector(saveToDisk) withObject:nil];
}

- (void)addFrame {
    _isClean = NO;
    _currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.uuid = self.uuid;
    drawView.delegate = self;
    [self.framesArray insertObject:drawView atIndex:_currentFrame];
    [self.sketchView addSubview:drawView];
    [self saveToDisk];
    [self updateUI];
}

- (void)deleteCurrentFrame {
    _isClean = NO;
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

    [self saveToDisk];
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
        self.deleteButton.hidden = NO;
    } else {
        self.deleteButton.hidden = YES;
    }
    
    if (self.framesArray.count > 1) {
        self.exportButton.enabled = YES;
        self.previewButton.enabled = YES;
    } else {
        self.exportButton.enabled = NO;
        self.previewButton.enabled = NO;
    }

    self.frameLabel.text = [NSString stringWithFormat:@"Frame: %i/%i", _currentFrame+1, (int)self.framesArray.count];
}

- (void)disableUI {
    // things to disable
    self.previousButton.enabled = NO;
    self.nextButton.enabled = NO;
    self.addButton.enabled = NO;
    self.exportButton.enabled = NO;
    // things to hide
    self.deleteButton.hidden = YES;
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
    [self saveToDisk];
    [self updateUI];
}

#pragma mark - Grid view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //	NSLog(@"prepare for segue: [%@] sender: [%@]", [segue identifier], sender);
    if ([[segue identifier] isEqualToString:@"viewGrid"]) {
        [self clean];
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller {
    self.appData = [[UserData alloc] initWithDefaultData];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller withAnimationIndex:(NSInteger)index {
    self.appData = [[UserData alloc] initWithDefaultData];

    if (_isPreviewing) {
        [self stopPreview];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        // in case we want to wait until finished
    }];
    
    if (index != -1) {
        [self loadAnimation:index];
    } else {
        [self newAnimation];
    }
}

#pragma mark - Button actions

- (IBAction)onMyAnimationsTapped:(id)sender {
    [self performSegueWithIdentifier:@"viewGrid" sender:self];
}

- (IBAction)onNewTapped:(id)sender {
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
    UIActionSheet *as = [[UIActionSheet alloc]
                         initWithTitle:nil
                         delegate:self
                         cancelButtonTitle:@"Cancel"
                         destructiveButtonTitle:[NSString stringWithFormat:@"Delete frame"]
                         otherButtonTitles:nil];
    [as showInView:self.view.superview];
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
    [self export];
}

#pragma mark - Actionsheet stuff

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteCurrentFrame];
    }
}

@end
