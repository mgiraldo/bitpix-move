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
static BOOL _firstLoad = YES;
static BOOL _tappedAdd = NO;
static BOOL _tappedPreview = NO;
static BOOL _tappedStop = NO;
static BOOL _isVertical = YES;

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (self.appDelegate.appData.userAnimations.count > 0) {
        _firstLoad = NO;
        _tappedAdd = YES;
        _tappedPreview = YES;
        _tappedStop = YES;
        self.drawLabel.hidden = YES;
    }
    
    CGSize size = [[UIScreen mainScreen] bounds].size;

    [self updateScreenSize:size];

    if (_firstLoad) {
        self.addButton.hidden = YES;
        self.addButtonH.hidden = YES;
    }
    
    // the next id will be the count
    self.uuid = [[NSUUID UUID] UUIDString];
    self.previewView.uuid = self.uuid;
    self.previewView.hidden = YES;
    self.stopPreviewButton.hidden = YES;
    self.stopPreviewButtonH.hidden = YES;
	self.sketchView.backgroundColor = [UIColor whiteColor];
	[self newAnimation];
    [self updateUI];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    CGSize size = [[UIScreen mainScreen] bounds].size;
    if (size.height < _minHeight && size.height > size.width) {
        return NO;
    }
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self updateScreenSize:size];
    [self updateUI];
}

- (void)updateScreenSize:(CGSize)size {
    if (size.height > _minHeight) {
        self.verticalCenterConstraint.active = YES;
        self.bottomDistanceConstraint.active = NO;
        [self verticalUI];
    } else {
        if (size.height > size.width) {
            self.verticalCenterConstraint.active = NO;
            self.bottomDistanceConstraint.active = YES;
            self.bottomDistanceConstraint.constant = 60.0f;
            [self verticalUI];
        } else {
            self.verticalCenterConstraint.active = YES;
            self.bottomDistanceConstraint.active = NO;
            [self horizontalUI];
        }
    }
}

- (void)horizontalUI {
    _isVertical = NO;
    self.mainActionsView.hidden = YES;
    self.frameActionsView.hidden = YES;

    if (!_firstLoad) {
        self.mainActionsViewH.hidden = NO;
        self.frameActionsViewH.hidden = NO;
    } else {
        self.mainActionsViewH.hidden = YES;
        self.frameActionsViewH.hidden = YES;
    }
}

- (void)verticalUI {
    _isVertical = YES;
    self.mainActionsViewH.hidden = YES;
    self.frameActionsViewH.hidden = YES;

    if (!_firstLoad) {
        self.mainActionsView.hidden = NO;
        self.frameActionsView.hidden = NO;
    } else {
        self.mainActionsView.hidden = YES;
        self.frameActionsView.hidden = YES;
    }
}

#pragma mark - Preview stuff

- (void)showPreview {
    _isPreviewing = YES;
    [self disableUI];
    self.previewButton.hidden = YES;
    self.stopPreviewButton.hidden = NO;
    self.previewButtonH.hidden = YES;
    self.stopPreviewButtonH.hidden = NO;
    self.previewView.hidden = NO;

    [self clean];
    [self.previewView animate];
}

- (void)stopPreview {
    [self.previewView stop];
    self.stopPreviewButton.hidden = YES;
    self.previewButton.hidden = NO;
    self.stopPreviewButtonH.hidden = YES;
    self.previewButtonH.hidden = NO;
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
    }
}

- (void)export {
    [self clean];

//    NSString *textToShare = @"created with MovePix";
    
    NSArray *objectsToShare;
    
    NSString *filename = [NSString stringWithFormat:@"%@.gif", self.uuid];
    NSString *path = [UserData dataFilePath:filename];
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    
    objectsToShare = @[fileData];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                      applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypePrint,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToTencentWeibo];
    
    activityViewController.excludedActivityTypes = excludeActivities;

    UIPopoverPresentationController *popover = activityViewController.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.sketchView;
        popover.sourceRect = CGRectMake(self.sketchView.bounds.size.width * .5, self.sketchView.bounds.size.height * .5, 1.0, 1.0);
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    [self presentViewController:activityViewController
                       animated:YES
                     completion:^{}];
}

#pragma mark - DrawView delegate

- (void)drawViewChanged:(DrawView *)drawView {
    if (_firstLoad) {
        _firstLoad = NO;
        CGSize size = [[UIScreen mainScreen] bounds].size;
        [self updateScreenSize:size];
    }
    _isClean = NO;
    [self updateUndoButtonForDrawView:drawView];
    [self.framesArray replaceObjectAtIndex:_currentFrame withObject:drawView];
    [self updateUI];
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(drawView) {
            [self saveToDisk];
        }
    });
}

- (void)drawViewTouchesBegan:(DrawView *)drawView {
    if (self.drawLabel.hidden) return;
    self.drawLabel.hidden = YES;
}

#pragma mark - Frame stuff

- (void)removeFrames {
    [[self.sketchView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.framesArray = [@[] mutableCopy];
}

- (void)addFrame {
    _isClean = NO;
    _currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.uuid = self.uuid;
    drawView.delegate = self;
    [self.framesArray insertObject:drawView atIndex:_currentFrame];
    [self.sketchView addSubview:drawView];
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(drawView) {
            [self saveToDisk];
        }
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

    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(drawView) {
            [self saveToDisk];
        }
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

#pragma mark - UI/undo stuff

- (void)updateUI {
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [self updateUndoButtonForDrawView:drawView];
    
    if (_isVertical) {
        self.previousButtonH.hidden = YES;
        self.nextButtonH.hidden = YES;
        self.addButtonH.hidden = YES;
        self.myAnimationsButtonH.hidden = YES;
        self.addAnimationButtonH.hidden = YES;
        self.deleteButtonH.hidden = YES;
        self.exportButtonH.hidden = YES;
        self.previewButtonH.hidden = YES;
        self.settingsButtonH.hidden = YES;
    } else {
        self.previousButton.hidden = YES;
        self.nextButton.hidden = YES;
        self.addButton.hidden = YES;
        self.myAnimationsButton.hidden = YES;
        self.addAnimationButton.hidden = YES;
        self.deleteButton.hidden = YES;
        self.exportButton.hidden = YES;
        self.previewButton.hidden = YES;
        self.settingsButton.hidden = YES;
    }

    if (_currentFrame <= 0) {
        self.previousButton.hidden = YES;
        self.previousButtonH.hidden = YES;
    } else {
        if (_isVertical) self.previousButton.hidden = NO;
        if (!_isVertical) self.previousButtonH.hidden = NO;
    }

    if (_currentFrame >= self.framesArray.count-1) {
        self.nextButton.hidden = YES;
        self.nextButtonH.hidden = YES;
    } else {
        if (_isVertical) self.nextButton.hidden = NO;
        if (!_isVertical) self.nextButtonH.hidden = NO;
    }
    
    if (self.framesArray.count >= _maxFrames) {
        self.addButton.hidden = YES;
        self.addButtonH.hidden = YES;
    } else {
        if (!_firstLoad) {
            if (_isVertical) self.addButton.hidden = NO;
            if (!_isVertical) self.addButtonH.hidden = NO;
        }
    }

    if (!_tappedStop) {
        self.myAnimationsButton.hidden = YES;
        self.myAnimationsButtonH.hidden = YES;
        self.addAnimationButton.hidden = YES;
        self.addAnimationButtonH.hidden = YES;
        self.settingsButton.hidden = YES;
        self.settingsButtonH.hidden = YES;
    } else {
        if (_isVertical) self.myAnimationsButton.hidden = NO;
        if (!_isVertical) self.myAnimationsButtonH.hidden = NO;
        if (_isVertical) self.addAnimationButton.hidden = NO;
        if (!_isVertical) self.addAnimationButtonH.hidden = NO;
        if (_isVertical) self.settingsButton.hidden = NO;
        if (!_isVertical) self.settingsButtonH.hidden = NO;
    }
    
    if (self.framesArray.count > 1) {
        if (_isVertical) self.deleteButton.hidden = NO;
        if (!_isVertical) self.deleteButtonH.hidden = NO;
    } else {
        self.deleteButton.hidden = YES;
        self.deleteButtonH.hidden = YES;
    }
    
    if (self.framesArray.count > 1) {
        if (_tappedAdd && !_isPreviewing) {
            if (_isVertical) self.previewButton.hidden = NO;
            if (!_isVertical) self.previewButtonH.hidden = NO;
        }
        if (_tappedStop) {
            if (_isVertical) self.exportButton.hidden = NO;
            if (!_isVertical) self.exportButtonH.hidden = NO;
        }
    } else {
        self.exportButton.hidden = YES;
        self.exportButtonH.hidden = YES;
        self.previewButton.hidden = YES;
        self.previewButtonH.hidden = YES;
    }

    self.frameLabel.text = [NSString stringWithFormat:@"%i/%i", _currentFrame+1, (int)self.framesArray.count];
    self.frameLabelH.text = [NSString stringWithFormat:@"%i/%i", _currentFrame+1, (int)self.framesArray.count];
}

- (void)disableUI {
    self.previousButton.hidden = YES;
    self.nextButton.hidden = YES;
    self.addButton.hidden = YES;
    self.exportButton.hidden = YES;
    self.deleteButton.hidden = YES;
    self.undoButton.hidden = YES;

    self.previousButtonH.hidden = YES;
    self.nextButtonH.hidden = YES;
    self.addButtonH.hidden = YES;
    self.exportButtonH.hidden = YES;
    self.deleteButtonH.hidden = YES;
    self.undoButtonH.hidden = YES;
}

- (void)updateUndoButtonForDrawView:(DrawView *)drawView {
    if ([drawView hasLines]) {
        self.undoButton.hidden = NO;
        self.undoButtonH.hidden = NO;
    } else {
        self.undoButton.hidden = YES;
        self.undoButtonH.hidden = YES;
    }
}

- (void)undo {
    DrawView *drawView = [self.framesArray objectAtIndex:_currentFrame];
    [drawView undo];
    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(drawView) {
            [self saveToDisk];
        }
    });
    [self updateUI];
}

#pragma mark - Grid/Info view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //	NSLog(@"prepare for segue: [%@] sender: [%@]", [segue identifier], sender);
    if ([[segue identifier] isEqualToString:@"viewGrid"]) {
        [self clean];
        [[segue destinationViewController] setDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"viewInfo"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)infoViewControllerDidFinish:(InfoViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (IBAction)onNextTapped:(id)sender {
    [self nextFrame];
}

- (IBAction)onPreviousTapped:(id)sender {
    [self prevFrame];
}

- (IBAction)onAddTapped:(id)sender {
    _tappedAdd = YES;
	[self addFrame];
}

- (IBAction)onDeleteTapped:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Delete frame" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self deleteCurrentFrame];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];

    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.sketchView;
        popover.sourceRect = CGRectMake(self.sketchView.bounds.size.width * .5, self.sketchView.bounds.size.height * .5, 1.0, 1.0);
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alert animated:NO completion:nil];
}

- (IBAction)onStopPreviewTapped:(id)sender {
    _tappedStop = YES;
    [self stopPreview];
}

- (IBAction)onUndoTapped:(id)sender {
    [self undo];
}

- (IBAction)onPreviewTapped:(id)sender {
    _tappedPreview = YES;
    [self showPreview];
}

- (IBAction)onExportTapped:(id)sender {
    [self export];
}

@end
