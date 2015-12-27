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
#import "SVGExportActivityItemProvider.h"
#import "CEMovieMaker.h"
#import "DMActivityInstagram.h"
#import "FrameCell.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MainViewController ()

@property (nonatomic) CEMovieMaker *movieMaker;

@end

@implementation MainViewController

- (void)viewDidLoad {
	[super viewDidLoad];

    [self updateTheme];
    
    self.currentFrame = -1;
    self.isPreviewing = NO;
    self.isClean = YES;
    self.firstLoad = YES;
    self.tappedAdd = NO;
    self.tappedPreview = NO;
    self.tappedStop = NO;
    self.isVertical = YES;
    self.frameBuffer = 3;
    self.frameViewShown = NO;
    self.frameCollectionView.hidden = YES;

    self.statusView.hidden = YES;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleTap:)];
    [self.statusView addGestureRecognizer:tapRecognizer];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (self.appDelegate.appData.userAnimations.count > 0) {
        self.firstLoad = NO;
        self.tappedAdd = YES;
        self.tappedPreview = YES;
        self.tappedStop = YES;
        self.drawLabel.hidden = YES;
    }
    
    CGSize size = [[UIScreen mainScreen] bounds].size;

    [self updateScreenSize:size];

    if (self.firstLoad) {
        self.addButton.hidden = YES;
        self.addButtonH.hidden = YES;
        self.drawLabel.text = @"Draw here";
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.isRestoring) {
        self.isRestoring = NO;
        [self performSelector:@selector(restoreBackup) withObject:nil afterDelay:0.0];
    }
}

- (void)restoreBackup {
    [self performSegueWithIdentifier:@"restoreBackup" sender:self];
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
            self.arrowButtonsConstraint.constant = 10.0f;
            [self verticalUI];
        } else {
            self.verticalCenterConstraint.active = YES;
            self.bottomDistanceConstraint.active = NO;
            [self horizontalUI];
        }
    }
}

- (void)horizontalUI {
    self.isVertical = NO;
    self.mainActionsView.hidden = YES;
    self.frameActionsView.hidden = YES;
    self.mainArrowView.hidden = YES;

    if (!self.firstLoad) {
        self.mainActionsViewH.hidden = NO;
        self.frameActionsViewH.hidden = NO;
    } else {
        self.mainActionsViewH.hidden = YES;
        self.frameActionsViewH.hidden = YES;
    }
}

- (void)verticalUI {
    self.isVertical = YES;
    self.mainActionsViewH.hidden = YES;
    self.frameActionsViewH.hidden = YES;
    self.mainArrowView.hidden = NO;

    if (!self.firstLoad) {
        self.mainActionsView.hidden = NO;
        self.frameActionsView.hidden = NO;
    } else {
        self.mainActionsView.hidden = YES;
        self.frameActionsView.hidden = YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //	NSLog(@"prepare for segue: [%@] sender: [%@]", [segue identifier], sender);
    if ([[segue identifier] isEqualToString:@"viewGrid"]) {
        [self saveToDisk];
        [self clean];
        [[segue destinationViewController] setDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"viewInfo"]) {
        [self saveToDisk];
        [self clean];
        [[segue destinationViewController] setDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"restoreBackup"]) {
        InfoViewController *vc = [segue destinationViewController];
        vc.isRestoring = YES;
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)updateTheme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isBlack = [[defaults valueForKey:@"blackTheme"] boolValue];
    UIColor *tintColor;
    UIColor *bgColor;
    NSString *letter;
    
    if (isBlack) {
        tintColor = [UIColor whiteColor];
        bgColor = [UIColor blackColor];
        letter = @"";
    } else {
        tintColor = [UIColor blackColor];
        bgColor = [UIColor whiteColor];
        letter = @"_w";
    }
    
    [self.view setBackgroundColor:bgColor];
    [self.view setTintColor:tintColor];
    
    [self.frameCollectionView setBackgroundColor:bgColor];
    [self.frameCollectionView setTintColor:tintColor];
    [self.frameCollectionViewLabel setTextColor:tintColor];
    self.frameLabel.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.frameLabel setTitleColor:tintColor forState:UIControlStateNormal];
    self.frameLabelH.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.frameLabelH setTitleColor:tintColor forState:UIControlStateNormal];
    [self.nextButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"next%@", letter]] forState:UIControlStateNormal];
    [self.nextButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"next-small%@", letter]] forState:UIControlStateNormal];
    [self.addButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"new%@", letter]] forState:UIControlStateNormal];
    [self.addButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"new%@", letter]] forState:UIControlStateNormal];
    [self.previousButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"previous%@", letter]] forState:UIControlStateNormal];
    [self.previousButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"previous-small%@", letter]] forState:UIControlStateNormal];
    [self.exportButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"export%@", letter]] forState:UIControlStateNormal];
    [self.exportButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"export%@", letter]] forState:UIControlStateNormal];
    [self.stopPreviewButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"stop%@", letter]] forState:UIControlStateNormal];
    [self.stopPreviewButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"stop%@", letter]] forState:UIControlStateNormal];
    [self.previewButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"play%@", letter]] forState:UIControlStateNormal];
    [self.previewButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"play%@", letter]] forState:UIControlStateNormal];
    [self.deleteButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"trash%@", letter]] forState:UIControlStateNormal];
    [self.deleteButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"trash%@", letter]] forState:UIControlStateNormal];
    [self.duplicateButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"duplicate%@", letter]] forState:UIControlStateNormal];
    [self.duplicateButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"duplicate%@", letter]] forState:UIControlStateNormal];
    [self.undoButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"undo%@", letter]] forState:UIControlStateNormal];
    [self.undoButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"undo%@", letter]] forState:UIControlStateNormal];
    [self.myAnimationsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"list%@", letter]] forState:UIControlStateNormal];
    [self.myAnimationsButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"list%@", letter]] forState:UIControlStateNormal];
    [self.settingsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"settings%@", letter]] forState:UIControlStateNormal];
    [self.settingsButtonH setImage:[UIImage imageNamed:[NSString stringWithFormat:@"settings%@", letter]] forState:UIControlStateNormal];
}

#pragma mark - Preview stuff

- (void)showPreview {
    self.isPreviewing = YES;
    [self disableUI];
    self.previewButton.hidden = YES;
    self.stopPreviewButton.hidden = NO;
    self.previewButtonH.hidden = YES;
    self.stopPreviewButtonH.hidden = NO;
    self.previewView.hidden = NO;

    [self saveToDisk];
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
    self.isPreviewing = NO;
    [self updateUI];
}

#pragma mark - Video stuff

- (void)createVideo {
    NSDictionary *settings = [CEMovieMaker videoSettingsWithCodec:AVVideoCodecH264 withWidth:_videoSize andHeight:_videoSize];
    
    NSMutableArray *frames = [@[] mutableCopy];
    
    int numberOfLoops = 1;
    
    int frameCount = (int)self.previewView.imageArray.count;
    
    float duration = (float)frameCount / (float)self.previewView.speed;
    
    if (duration < _minVideoLength) {
        numberOfLoops = ceil((float)_minVideoLength / duration);
        duration = (float)(numberOfLoops * frameCount) / (float)self.previewView.speed;
    }
    
    for (int i=0; i<frameCount * numberOfLoops; i++) {
        UIImage *resized = [self.previewView.imageArray[i%frameCount] scaleToSize:CGSizeMake(_videoSize, _videoSize)];
        [frames addObject:resized];
    }
    
    self.movieMaker = [[CEMovieMaker alloc] initWithSettings:settings andName:@"export.mov"];
    
    self.movieMaker.frameTime = CMTimeMake(duration, 1);
    
    [self.movieMaker createMovieFromImages:[frames copy] withCompletion:^(NSURL *fileURL) {
        [self showActivityView];
    }];
}

- (void)viewMovieAtUrl:(NSURL *)fileURL {
    MPMoviePlayerViewController *playerController = [[MPMoviePlayerViewController alloc] initWithContentURL:fileURL];
    [playerController.view setFrame:self.view.bounds];
    [self presentMoviePlayerViewControllerAnimated:playerController];
    [playerController.moviePlayer prepareToPlay];
    playerController.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    [playerController.moviePlayer play];
    [self.view addSubview:playerController.view];
}

- (void)videoCreatedWithURL:(NSURL *)fileURL {
    
}

#pragma mark - Load/new/save stuff

- (void)newAnimation {
    if (self.isPreviewing) {
        [self stopPreview];
    }
    // new name for animation
    self.uuid = [[NSUUID UUID] UUIDString];
    [self.previewView resetWithNewUUID:self.uuid];
    // cleanup
    [self removeFrames];
    self.currentFrame = -1;
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
    [self.frameCollectionView reloadData];
    self.isClean = YES;
    self.currentFrame = 0;
    [self updateUI];
}

- (void)saveToDisk {
    // ignore if empty
    if (self.framesArray.count == 0) return;
    DrawView *drawView = [self.framesArray objectAtIndex:0];
    // do not save if only one frame that is clean
    if (self.framesArray.count == 1 && [drawView isClean]) return;

    if (!self.currentView.isClean) {
        self.currentView.isClean = YES;
    } else {
        return;
    }

    dispatch_async(self.appDelegate.backgroundSaveQueue, ^{
        @synchronized(self.appDelegate.appData) {
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
    });
}

- (void)clean {
    if (!self.isClean) {
        self.isClean = YES;
        [self.previewView createFrames:self.framesArray withSpeed:_fps];
        [self.previewView createAllGIFs];
    }
}

- (void)export {
    [self clean];

    [self showStatusView:@"Exporting animation…"];
    // create video and wait until it fires the activity view
    [self createVideo];
}

- (void)showActivityView {
    [self hideStatusView];

    NSString *svg = [self.previewView createSVGString];

    NSString *filename = [NSString stringWithFormat:@"%@.gif", self.uuid];
    NSString *path = [UserData dataFilePath:filename];
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    NSString *videoPath = [UserData dataFilePath:@"export.mov"];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    SVGExportActivityItemProvider *provider = [[SVGExportActivityItemProvider alloc] initWithPlaceholderItem:fileData];
    
    provider.svgString = svg;
    provider.gifData = fileData;
    provider.videoURL = videoURL;
    
    SVGEmailActivityIcon *svgEmailIcon = [[SVGEmailActivityIcon alloc] init];
    
    VideoSaveActivityIcon *videoIcon = [[VideoSaveActivityIcon alloc] init];
    videoIcon.videoURL = videoURL;
    
    NSArray *activities;
    
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
    
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
        DMActivityInstagram *instagramIcon = [[DMActivityInstagram alloc] init];
        activities = @[instagramIcon, svgEmailIcon, videoIcon];
    } else {
        activities = @[svgEmailIcon, videoIcon];
    }
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[provider]
                                      applicationActivities:activities];
    
    
    
    NSArray *excludeActivities = @[UIActivityTypePrint,
                                   UIActivityTypeAddToReadingList,
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
    if (self.firstLoad) {
        self.firstLoad = NO;
        CGSize size = [[UIScreen mainScreen] bounds].size;
        [self updateScreenSize:size];
    }
    self.isClean = NO;
    [self updateUndoButtonForDrawView:drawView];
    [self.framesArray replaceObjectAtIndex:self.currentFrame withObject:drawView];
    [self.frameCollectionView reloadData];
    [self updateUI];
}

- (void)drawViewTouchesBegan:(DrawView *)drawView {
    if (self.drawLabel.hidden) return;
    self.drawLabel.hidden = YES;
}

#pragma mark - Frame stuff

- (void)refreshDrawViews {
    if ([self.framesArray isEqualToArray:self.tempFramesArray]) return;
    self.tempFramesArray = nil;
    [[self.sketchView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // add frames
    self.currentFrame = 0;
    DrawView *drawView = [self.framesArray objectAtIndex:self.currentFrame];
    [self.sketchView addSubview:drawView];
    [self.previewView createFrames:self.framesArray withSpeed:_fps];
    self.isClean = NO;
    [self updateUI];
}

- (void)removeFrames {
    [[self.sketchView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.framesArray = [@[] mutableCopy];
    [self.frameCollectionView reloadData];
}

- (void)addFrame {
    if (self.currentFrame != -1) self.isClean = NO;
    self.currentFrame++;
    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.uuid = self.uuid;
    drawView.delegate = self;
    drawView.isClean = self.isClean;
    [self.framesArray insertObject:drawView atIndex:self.currentFrame];
    [self.sketchView addSubview:drawView];
    [self.frameCollectionView reloadData];
    [self popFrame];
    [self updateUI];
    [self saveToDisk];
}

- (void)duplicateCurrentFrame {
    self.isClean = NO;
    // duplicate view
    DrawView *originalView = [self.framesArray objectAtIndex:self.currentFrame];

    self.currentFrame++;

    DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
    drawView.uuid = self.uuid;
    drawView.delegate = self;
    drawView.isClean = NO;
    drawView.lineList = [NSMutableArray arrayWithArray:originalView.lineList];

    [self.framesArray insertObject:drawView atIndex:self.currentFrame];
    [self.sketchView addSubview:drawView];
    
    [self.frameCollectionView reloadData];
    [self popFrame];
    [self updateUI];
    [self saveToDisk];
}

- (void)deleteCurrentFrame {
    self.isClean = NO;
    // dispose of view
    DrawView *drawView = [self.framesArray objectAtIndex:self.currentFrame];
    [drawView removeFromSuperview];

    // dispose of object in array
    [self.framesArray removeObjectAtIndex:self.currentFrame];

    [self unshiftFrame];

    if (self.currentFrame == 0) {
        // we removed the first frame
        drawView = [self.framesArray objectAtIndex:self.currentFrame];
        [self.sketchView addSubview:drawView];
    } else {
        self.currentFrame--;
    }
    
    // make the current view dirty for saving purposes
    drawView = [self.framesArray objectAtIndex:self.currentFrame];
    drawView.isClean = NO;

    [self.frameCollectionView reloadData];
    [self clean];
    [self saveToDisk];
    [self updateUI];
}

- (void)nextFrame {
    if (!self.currentView.isClean) {
        [self saveToDisk];
    }
    self.currentFrame++;
    if (self.currentFrame > self.framesArray.count) self.currentFrame = (int)self.framesArray.count - 1;
    DrawView *drawView = [self.framesArray objectAtIndex:self.currentFrame];
    [self.sketchView addSubview:drawView];
    [self popFrame];
    [self updateUI];
}

- (void)prevFrame {
    if (!self.currentView.isClean) {
        [self saveToDisk];
    }
    DrawView *drawView = [self.framesArray objectAtIndex:self.currentFrame];
    [drawView removeFromSuperview];
    [self unshiftFrame];
    self.currentFrame--;
    if (self.currentFrame < 0) self.currentFrame = 0;
    [self updateUI];
}

- (void)popFrame {
    if ([self.sketchView subviews].count > self.frameBuffer) {
        // remove first subview
        [[[self.sketchView subviews] objectAtIndex:0] removeFromSuperview];
    }
}

- (void)unshiftFrame {
    if ([self.sketchView subviews].count < self.frameBuffer && self.currentFrame >= self.frameBuffer) {
        // add the subview behind
        DrawView *drawViewB = [self.framesArray objectAtIndex:self.currentFrame-self.frameBuffer];
        [self.sketchView insertSubview:drawViewB atIndex:0];
    }
}

#pragma mark - UI/undo stuff

- (void)updateUI {
    DrawView *drawView = [self.framesArray objectAtIndex:self.currentFrame];
    self.currentView = drawView;
    [self updateUndoButtonForDrawView:drawView];
    
    if (self.isVertical) {
        self.previousButtonH.hidden = YES;
        self.nextButtonH.hidden = YES;
        self.addButtonH.hidden = YES;
        self.myAnimationsButtonH.hidden = YES;
        self.addAnimationButtonH.hidden = YES;
        self.deleteButtonH.hidden = YES;
        self.duplicateButtonH.hidden = YES;
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
        self.duplicateButton.hidden = YES;
        self.exportButton.hidden = YES;
        self.previewButton.hidden = YES;
        self.settingsButton.hidden = YES;
    }

    if (self.currentFrame <= 0) {
        self.previousButton.hidden = YES;
        self.previousButtonH.hidden = YES;
    } else {
        if (self.isVertical) self.previousButton.hidden = NO;
        if (!self.isVertical) self.previousButtonH.hidden = NO;
    }

    if (self.currentFrame >= self.framesArray.count-1) {
        self.nextButton.hidden = YES;
        self.nextButtonH.hidden = YES;
    } else {
        if (self.isVertical) self.nextButton.hidden = NO;
        if (!self.isVertical) self.nextButtonH.hidden = NO;
    }
    
    if (self.framesArray.count >= _maxFrames) {
        self.addButton.hidden = YES;
        self.addButtonH.hidden = YES;
    } else {
        if (!self.firstLoad) {
            if (self.isVertical) self.addButton.hidden = NO;
            if (!self.isVertical) self.addButtonH.hidden = NO;
        }
    }

    if (!self.tappedStop) {
        self.myAnimationsButton.hidden = YES;
        self.myAnimationsButtonH.hidden = YES;
        self.addAnimationButton.hidden = YES;
        self.addAnimationButtonH.hidden = YES;
        self.settingsButton.hidden = YES;
        self.settingsButtonH.hidden = YES;
        self.duplicateButton.hidden = YES;
        self.duplicateButtonH.hidden = YES;
    } else {
        if (self.isVertical) self.myAnimationsButton.hidden = NO;
        if (!self.isVertical) self.myAnimationsButtonH.hidden = NO;
        if (self.isVertical) self.addAnimationButton.hidden = NO;
        if (!self.isVertical) self.addAnimationButtonH.hidden = NO;
        if (self.isVertical) self.settingsButton.hidden = NO;
        // TODO: fix settings view to work on landscape mode
//        if (!self.isVertical) self.settingsButtonH.hidden = NO;
    }
    
    if (self.framesArray.count > 1) {
        if (self.isVertical) self.deleteButton.hidden = NO;
        if (!self.isVertical) self.deleteButtonH.hidden = NO;
    } else {
        self.deleteButton.hidden = YES;
        self.deleteButtonH.hidden = YES;
    }
    
    if (self.framesArray.count > 1) {
        if (self.tappedAdd && !self.isPreviewing && self.drawLabel.hidden) {
            if (self.isVertical) self.previewButton.hidden = NO;
            if (!self.isVertical) self.previewButtonH.hidden = NO;
        }
        if (self.tappedStop) {
            if (self.isVertical) {
                self.exportButton.hidden = NO;
                self.duplicateButton.hidden = NO;
            }
            if (!self.isVertical) {
                self.exportButtonH.hidden = NO;
                self.duplicateButtonH.hidden = NO;
            }
        }
    } else {
        self.exportButton.hidden = YES;
        self.exportButtonH.hidden = YES;
        self.previewButton.hidden = YES;
        self.previewButtonH.hidden = YES;
    }
    
    NSString * frameString = [NSString stringWithFormat:@"%i/%i", self.currentFrame+1, (int)self.framesArray.count];

    [self.frameLabel setTitle:frameString forState:UIControlStateNormal];
    [self.frameLabelH setTitle:frameString forState:UIControlStateNormal];
}

- (void)disableUI {
    self.previousButton.hidden = YES;
    self.nextButton.hidden = YES;
    self.addButton.hidden = YES;
    self.exportButton.hidden = YES;
    self.deleteButton.hidden = YES;
    self.duplicateButton.hidden = YES;
    self.undoButton.hidden = YES;

    self.previousButtonH.hidden = YES;
    self.nextButtonH.hidden = YES;
    self.addButtonH.hidden = YES;
    self.exportButtonH.hidden = YES;
    self.deleteButtonH.hidden = YES;
    self.duplicateButtonH.hidden = YES;
    self.undoButtonH.hidden = YES;
}

- (void)updateUndoButtonForDrawView:(DrawView *)drawView {
    if ([drawView hasLines]) {
        self.undoButton.hidden = NO;
        self.undoButtonH.hidden = NO;
        self.duplicateButton.hidden = NO;
        self.duplicateButtonH.hidden = NO;
    } else {
        self.undoButton.hidden = YES;
        self.undoButtonH.hidden = YES;
        self.duplicateButton.hidden = YES;
        self.duplicateButtonH.hidden = YES;
    }
}

- (void)undo {
    DrawView *drawView = [self.framesArray objectAtIndex:self.currentFrame];
    [drawView undo];
//    [self saveToDisk];
    [self updateUI];
}

#pragma mark - Grid/Info view delegate

- (void)infoViewControllerDidFinish:(InfoViewController *)controller {
    [self updateTheme];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gridViewControllerDidFinish:(GridViewController *)controller withAnimationIndex:(NSInteger)index {
    if (self.isPreviewing) {
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

#pragma mark - Status view stuff

- (void)showStatusView:(NSString *)text {
    self.statusView.hidden = NO;
    if ([text isEqualToString:@""]) return;
    srand ((int)time(NULL));
    NSArray *emojiArray = @[@"📹", @"🎥", @"👯", @"🐌", @"🐢", @"🚀"];
    int emojiCount = (int)emojiArray.count;
    int index = rand()%emojiCount;
    NSString *emoji = [emojiArray objectAtIndex:index];
    
    self.statusLabel.text = [NSString stringWithFormat:@"%@%@%@\n\n%@\n\n%@%@%@", emoji, emoji, emoji, text, emoji, emoji, emoji];
}

- (void)hideStatusView {
    self.statusLabel.text = @"";
    self.statusView.hidden = YES;
}

#pragma mark - frame collection view show/hide

- (void)showFrameCollectionView {
    self.frameViewShown = YES;
    LXReorderableCollectionViewFlowLayout *layout = [[LXReorderableCollectionViewFlowLayout alloc] init];
    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    self.frameCollectionView.collectionViewLayout = layout;
    self.frameCollectionView.bounces = YES;
    self.frameCollectionView.alwaysBounceHorizontal = YES;
    self.frameCollectionView.hidden = NO;
    [self.frameCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
    [self showStatusView:@""];
    self.tempFramesArray = [NSMutableArray arrayWithArray:self.framesArray];
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frameViewConstraint.constant = 0;
                         self.statusViewHConstraint.constant = -140;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         //
                     }];
}

- (void)hideFrameCollectionView {
    self.frameViewShown = NO;
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frameViewConstraint.constant = -140;
                         self.statusViewHConstraint.constant = 0;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         //
                         self.frameCollectionView.hidden = YES;
                         [self refreshDrawViews];
                         [self hideStatusView];
                     }];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded){
        if (self.frameViewShown) [self hideFrameCollectionView];
    }
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)theCollectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    return self.framesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DrawView *drawView = self.framesArray[indexPath.item];
    FrameCell *frameCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FrameCell" forIndexPath:indexPath];
    frameCell.drawView = drawView;
    return frameCell;
}

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
//    DebugLog(@"from %ld, to %ld", (long)fromIndexPath.row, (long)toIndexPath.row);
    DrawView *drawView = self.framesArray[fromIndexPath.item];
    
    [self.framesArray removeObjectAtIndex:fromIndexPath.item];
    [self.framesArray insertObject:drawView atIndex:toIndexPath.item];
    self.currentView.isClean = NO;
    [self saveToDisk];
    [self updateUI];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval = CGSizeMake(_thumbSize, _thumbSize);
    return retval;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(30, 10, 10, 10);
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"will begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"did begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"will end drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"did end drag");
}

#pragma mark - Button actions

- (IBAction)onMyAnimationsTapped:(id)sender {
    [self performSegueWithIdentifier:@"viewGrid" sender:self];
}

- (IBAction)onNewTapped:(id)sender {
    [self newAnimation];
}

- (IBAction)onDuplicateTapped:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Duplicate frame" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self duplicateCurrentFrame];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.sketchView;
        popover.sourceRect = CGRectMake(self.sketchView.bounds.size.width * .5, self.sketchView.bounds.size.height * .5, 1.0, 1.0);
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:alert animated:NO completion:nil];
}

- (IBAction)onFrameViewTapped:(id)sender {
    if (self.framesArray.count > 2) [self showFrameCollectionView];
}

- (IBAction)onNextTapped:(id)sender {
    [self nextFrame];
}

- (IBAction)onPreviousTapped:(id)sender {
    [self prevFrame];
}

- (IBAction)onAddTapped:(id)sender {
    self.tappedAdd = YES;
    if (!self.tappedPreview && ![self.drawLabel.text isEqualToString:@"Draw again"]) {
        self.drawLabel.text = @"Draw again";
        self.drawLabel.hidden = NO;
    }
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
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];

    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.sketchView;
        popover.sourceRect = CGRectMake(self.sketchView.bounds.size.width * .5, self.sketchView.bounds.size.height * .5, 1.0, 1.0);
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:alert animated:NO completion:nil];
}

- (IBAction)onStopPreviewTapped:(id)sender {
    self.tappedStop = YES;
    [self stopPreview];
}

- (IBAction)onUndoTapped:(id)sender {
    [self undo];
}

- (IBAction)onPreviewTapped:(id)sender {
    self.tappedPreview = YES;
    [self showPreview];
}

- (IBAction)onExportTapped:(id)sender {
    [self export];
}

@end
