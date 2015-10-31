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
static dispatch_queue_t backgroundSaveQueue;

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    backgroundSaveQueue = dispatch_queue_create("com.pingpongestudio.bitpix-move.bgqueue", NULL);
    
    // the next id will be the count
    self.uuid = [[NSUUID UUID] UUIDString];
    self.previewView.uuid = self.uuid;
    self.statusView.hidden = YES;
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
    NSDictionary *animation = [self.appDelegate.appData.userAnimations objectAtIndex:index];
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
    
    NSUInteger index = [self.appDelegate.appData.userAnimations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *animation = (NSDictionary *)obj;
        BOOL found = [[animation objectForKey:@"name"] isEqualToString:self.uuid];
        return found;
    }];
    
    if (index == NSNotFound) {
        // a new animation
        [self.appDelegate.appData.userAnimations addObject:animationInfo];
    } else {
        // old animation
        [self.appDelegate.appData.userAnimations replaceObjectAtIndex:index withObject:animationInfo];
    }
    
    [self.appDelegate.appData save];
}

- (void)clean {
    if (!_isClean) {
        _isClean = YES;
        [self.previewView createFrames:self.framesArray withSpeed:_fps];
        [self.previewView createAllGIFs];
        dispatch_async(backgroundSaveQueue, ^{
            [self saveToDisk];
        });
    }
}

- (void)export {
    [self clean];

    NSString *textToShare = @"created with MovePix";
    
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
    dispatch_async(backgroundSaveQueue, ^{
        [self saveToDisk];
    });
}

- (void)addFrame {
    _isClean = NO;
    _currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.uuid = self.uuid;
    drawView.delegate = self;
    [self.framesArray insertObject:drawView atIndex:_currentFrame];
    [self.sketchView addSubview:drawView];
    dispatch_async(backgroundSaveQueue, ^{
        [self saveToDisk];
    });
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

    dispatch_async(backgroundSaveQueue, ^{
        [self saveToDisk];
    });
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

- (void)buildThumbnails {
    self.statusLabel.text = @"Performing GIFness. This may take a while depending on how many animations you have. In the meantime, enjoy some emoji:\n\n👯";
    self.statusView.hidden = NO;

    dispatch_async(backgroundSaveQueue, ^{
        [self dispatchedBuild];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeStatusLabel];
        });
    });
}

- (void)dispatchedBuild {
//    DebugLog(@"buildThumbnails");
    int i;
    NSDictionary *animation;
    NSArray *frames;
    NSMutableArray *drawViewArray;

    NSInteger animationCount = self.appDelegate.appData.userAnimations.count;
    
    for (i=0; i<animationCount; i++) {
//        DebugLog(@"Refreshing %d of %ld", i+1, (long)animationCount);
        animation = (NSDictionary *)[self.appDelegate.appData.userAnimations objectAtIndex:i];
        // check if thumbnail exists
        NSString *uuid = [animation objectForKey:@"name"];
        // get the frames
        frames = [NSArray arrayWithArray:[animation objectForKey:@"frames"]];
        
        drawViewArray = [@[] mutableCopy];
        for (int j=0; j<frames.count; j++) {
            NSArray *lines = [NSArray arrayWithArray:[frames objectAtIndex:j]];
            DrawView *drawView = [[DrawView alloc] initWithFrame:CGRectMake(0, 0, _animationSize, _animationSize)];
            drawView.uuid = uuid;
            drawView.lineList = [lines mutableCopy];
            [drawViewArray addObject:drawView];
        }
        DrawViewAnimator *animator = [[DrawViewAnimator alloc] initWithFrame:CGRectMake(0, 0, _animationSize, _animationSize)];
        animator.uuid = uuid;
        [animator createFrames:drawViewArray withSpeed:_fps];
        [animator createAllGIFs];
    }

}

- (void)removeStatusLabel {
    self.statusLabel.text = @"";
    self.statusView.hidden = YES;
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
    dispatch_async(backgroundSaveQueue, ^{
        [self saveToDisk];
    });
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller withAnimationIndex:(NSInteger)index {
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

- (IBAction)onRebuildTapped:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Rebuild images"
                                                                   message:@"This will rebuild the GIFs generated by your animations. None of your animations will be modified."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Rebuild" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self buildThumbnails];
                                                          }];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
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
