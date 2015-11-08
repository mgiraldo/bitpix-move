//
//  InfoViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 7/11/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "InfoViewController.h"
#import "DrawView.h"
#import "DrawViewAnimator.h"
#import "Config.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

static int _currentRefresh = -1;
static dispatch_queue_t _refreshQueue;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _refreshQueue = dispatch_queue_create("com.pingpongestudio.bitpix-move.refreshqueue", NULL);

    self.statusView.hidden = YES;
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    self.versionLabel.text = [NSString stringWithFormat:@"MovePix v.%@ (%@)", appVersion, buildVersion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Status stuff

- (void)removeStatusLabel {
    self.statusLabel.text = @"";
    self.statusView.hidden = YES;
}

- (void)refreshThumbnails {
    _currentRefresh = 0;

    srand ((int)time(NULL));

    [self updateRefreshText];

    dispatch_async(_refreshQueue, ^{
        [self refreshNext];
    });
}

- (void)updateRefreshText {
    NSInteger animationCount = self.appDelegate.appData.userAnimations.count;
    self.statusView.hidden = NO;
    NSArray *emojiArray = @[@"👯", @"💁", @"👻", @"🙃", @"😶", @"🤖", @"👾", @"🎃", @"⏳", @"😎", @"🐌", @"🐢"];
    int emojiCount = (int)emojiArray.count;
    int index = rand()%emojiCount;
    NSString *emoji = [emojiArray objectAtIndex:index];
    
    self.statusLabel.text = [NSString stringWithFormat:@"%@\n\nPerforming GIFness\nfor animation\n%d of %d.\n\n%@", emoji, _currentRefresh+1, (int)animationCount, emoji];
}

- (void)refreshNext {
    NSInteger animationCount = self.appDelegate.appData.userAnimations.count;
    NSDictionary *animation;
    NSArray *frames;
    NSMutableArray *drawViewArray;

    animation = (NSDictionary *)[self.appDelegate.appData.userAnimations objectAtIndex:_currentRefresh];
    // check if thumbnail exists
    NSString *uuid = [animation objectForKey:@"name"];
    [self.appDelegate.appData removeThumbnailsForUUID:uuid];
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

    _currentRefresh++;
    
    if (_currentRefresh < animationCount) {
        // dispatch again
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC));

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRefreshText];
        });
        dispatch_after(popTime, _refreshQueue, ^{
            [self refreshNext];
        });
    } else {
        // stop
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeStatusLabel];
        });
    }
}

- (IBAction)onRefreshTapped:(id)sender {
    if (self.appDelegate.appData.userAnimations.count == 0) return;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Refresh thumbnails"
                                                                   message:@"Tap “Refresh” If the thumbnails you see do not match your animation. None of your animations will be modified. This may take a while depending on how many animations you have."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Refresh" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self refreshThumbnails];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (IBAction)onReturnTapped:(id)sender {
    [self.delegate infoViewControllerDidFinish:self];
}

@end
