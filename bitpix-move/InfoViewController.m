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
#import "Objective-Zip.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

static const NSUInteger BUFFER_SIZE = 1024;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentRefresh = -1;
    
    self.refreshQueue = dispatch_queue_create("com.pingpongestudio.bitpix-move.refreshqueue", NULL);

    self.statusView.hidden = YES;
    self.statusProgress.hidden = YES;
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    self.versionLabel.text = [NSString stringWithFormat:@"MovePix v.%@ (%@)", appVersion, buildVersion];
    
    if (self.isRestoring) {
        [self performSelector:@selector(startRestoreBackup) withObject:nil afterDelay:0.0];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Backup stuff

- (void)createBackup {
    [self removeBackup];
    OZZipFile *zipFile = [[OZZipFile alloc] initWithFileName:[UserData dataFilePath:@"MovePixBackup.zip"] mode:OZZipFileModeCreate legacy32BitMode:YES];
    
    OZZipWriteStream *stream = [zipFile writeFileInZipWithName:@"animations.plist" compressionLevel:OZZipCompressionLevelBest];
    
    NSData *animationData = [NSData dataWithContentsOfFile:[UserData dataFilePath:@"Data.plist"]];
 
    [stream writeData:animationData];
    
    [stream finishedWriting];
    
    [zipFile close];
}

- (void)saveBackup {
    self.statusView.hidden = NO;
    NSArray *emojiArray = @[@"👯", @"💁", @"👻", @"🙃", @"😶", @"🤖", @"👾", @"🎃", @"⏳", @"😎", @"🐌", @"🐢"];
    int emojiCount = (int)emojiArray.count;
    int index = rand()%emojiCount;
    NSString *emoji = [emojiArray objectAtIndex:index];
    self.statusLabel.text = [NSString stringWithFormat:@"%@\n\nPlease wait…\n\nYour backup is being generated\n\n%@", emoji, emoji];
    dispatch_async(self.refreshQueue, ^{
        [self createBackup];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSString *filename = @"MovePixBackup.zip";
            
            NSString *path = [UserData dataFilePath:filename];
            NSData *fileData = [NSData dataWithContentsOfFile:path];
            
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            picker.mailComposeDelegate = self;
            [picker setSubject:@"MovePix Animation Backup"];
            
            [picker addAttachmentData:fileData mimeType:@"application/zip" fileName:filename];
            
            // Fill out the email body text
            NSString *emailBody = @"Attached is a ZIP file for all your animations.\n\nMade with MovePix\nhttp://bitpix.co/move";
            [picker setMessageBody:emailBody isHTML:NO];
            
            [self presentViewController:picker
                               animated:YES
                             completion:^{}];
        });
    });
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
//    switch (result)
//    {
//        case MFMailComposeResultCancelled:
//            NSLog(@"Result: canceled");
//            break;
//        case MFMailComposeResultSaved:
//            NSLog(@"Result: saved");
//            break;
//        case MFMailComposeResultSent:
//            NSLog(@"Result: sent");
//            break;
//        case MFMailComposeResultFailed:
//            NSLog(@"Result: failed");
//            break;
//        default:
//            NSLog(@"Result: not sent");
//            break;
//    }

    [self dismissViewControllerAnimated:YES completion:^{
        self.statusView.hidden = YES;
        [self removeBackup];
    }];
}

- (void)removeBackup {
    NSFileManager *fm = [[NSFileManager alloc] init];
    [fm removeItemAtPath:[UserData dataFilePath:@"MovePixBackup/MovePixBackup.zip"] error:nil];
}

- (void)startRestoreBackup {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Restore animations"
                                                                   message:@"This will REPLACE ALL ANIMATIONS currently in the app with those found in the backup. Tap “Restore” to proceed."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Restore" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self confirmRestore];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             [self cleanInbox];
                                                         }];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)updateProgress:(long long)value total:(long long)total {
    float progress = (float)value/(float)total;
    self.statusProgress.progress = progress;
}

- (void)restoreBackup {
    NSString *dataFilePath = [UserData dataFilePath:@"temp.plist"];
    [[NSFileManager defaultManager] createFileAtPath:dataFilePath contents:nil attributes:nil];
    self.statusView.hidden = NO;
    self.statusProgress.hidden = NO;
    self.statusLabel.text = @"⌛️\n\nPlease wait while your backup is restored…\n\n⏳";
    dispatch_async(self.refreshQueue, ^{
        @try {
            OZZipFile *unzipFile= [[OZZipFile alloc] initWithFileName:self.appDelegate.restoreURL.path
                                                                 mode:OZZipFileModeUnzip legacy32BitMode:YES];
            [unzipFile goToFirstFileInZip];
            
            OZZipReadStream *read= [unzipFile readCurrentFileInZip];
            OZFileInZipInfo *info= [unzipFile getCurrentFileInZipInfo];
            __block long long progress = 0;
            __block long long total = info.length;
            NSMutableData *buffer = [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
            NSMutableData *data= [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
            NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:dataFilePath];
            
            do {
                
                // Reset buffer length
                [buffer setLength:BUFFER_SIZE];
                
                // Read bytes and check for end of file
                int bytesRead= (int)[read readDataWithBuffer:data];
                if (bytesRead <= 0)
                    break;
                
                [buffer setLength:bytesRead];
                [file writeData:data];
                
                progress += bytesRead;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgress:progress total:total];
                });
                
            } while (YES);
            
            [file closeFile];
            [read finishedReading];
        }
        @catch (NSException *exception) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Backup not restored"
                                                                           message:@"There was an error importing your backup. It may be malformed or otherwise unreadable by MovePix. None of your existing animations were deleted"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * action) {}];
            
            [alert addAction:okAction];
            [self presentViewController:alert animated:NO completion:nil];
        }
        @finally {
            NSError *error;
            NSDictionary *animationDictionary = [[NSDictionary alloc] initWithContentsOfFile:dataFilePath];
            if (error) {
                DebugLog(@"error: %@", error);
            }
            
            if (!([animationDictionary valueForKey:@"userAnimations"] != nil && [[animationDictionary valueForKey:@"userAnimations"] isKindOfClass:[NSArray class]])) {
                DebugLog(@"error: zip file has no animations");
            }
            
            NSArray *animations = [animationDictionary valueForKey:@"userAnimations"];
            NSMutableArray *newAnimations = [@[] mutableCopy];
            
            BOOL skip = NO;
            
            int progress = 0;
            int total = (int)animations.count;
            
            for (int i=0; i<animations.count; i++) {
                NSDictionary *animation = [animations objectAtIndex:i];
                if ([animation valueForKey:@"name"]==nil || [animation valueForKey:@"date"]==nil || [animation valueForKey:@"frames"]==nil) {
                    DebugLog(@"error: animation %d is invalid", i);
                    skip = YES;
                }
                if (![[animation valueForKey:@"name"] isKindOfClass:[NSString class]]) {
                    DebugLog(@"error: animation %d has no name", i);
                    skip = YES;
                }
                if (![[animation valueForKey:@"date"] isKindOfClass:[NSDate class]]) {
                    DebugLog(@"error: animation %d has no date", i);
                    skip = YES;
                }
                if (![[animation valueForKey:@"frames"] isKindOfClass:[NSArray class]] || [[animation valueForKey:@"frames"] count] > _maxFrames) {
                    DebugLog(@"error: animation %d has no frames", i);
                    skip = YES;
                }
                if (skip) continue;
                NSArray *frames = [animation valueForKey:@"frames"];
                for (int j=0; j<frames.count; j++) {
                    if (![[frames objectAtIndex:j] isKindOfClass:[NSArray class]]) {
                        DebugLog(@"error: wrong frame %d in animation %d", j, i);
                        skip = YES;
                    }
                    if (!skip) {
                        NSArray *lines = frames[j];
                        for (int k=0; k<lines.count; k++) {
                            if (![[lines objectAtIndex:k] isKindOfClass:[NSArray class]]) {
                                DebugLog(@"error: wrong lines %d in frame %d in animation %d", k, j, i);
                                skip = YES;
                            }
                            if (!skip) {
                                NSArray *line = lines[k];
                                for (int l=0; l<line.count; l++) {
                                    if (![[line objectAtIndex:l] isKindOfClass:[NSArray class]] || [[line objectAtIndex:l] count] != 2) {
                                        DebugLog(@"error: wrong line %d lines %d in frame %d in animation %d", l, k, j, i);
                                        skip = YES;
                                    } else if (![[[line objectAtIndex:l] objectAtIndex:0] isKindOfClass:[NSNumber class]] || ![[[line objectAtIndex:l] objectAtIndex:1] isKindOfClass:[NSNumber class]]) {
                                        DebugLog(@"error: wrong line %d lines %d in frame %d in animation %d", l, k, j, i);
                                        skip = YES;
                                    }
                                }
                            }
                        }
                    }
                }
                if (!skip) {
                    [newAnimations addObject:[animation mutableCopy]];
                }
                progress++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgress:progress total:total];
                });
            }
            
            if (newAnimations.count > 0) {
                self.appDelegate.appData.userAnimations = newAnimations;
                dispatch_async(self.refreshQueue, ^{
                    [self.appDelegate.appData save];
                });
            }
            
            [self cleanInbox];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                [self refreshThumbnails];
            });
        }
    });
}

- (void)restoreComplete {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Import is complete!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * action) {}];
    
    [alert addAction:okAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)cleanInbox {
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSArray *filelist= [fm contentsOfDirectoryAtPath:[UserData dataFilePath:@"Inbox"] error:nil];
    NSString *fullPath;
    
    if (filelist == nil) {
        return;
    }
    
    
    for (NSString *file in filelist) {
        NSError *error;
        fullPath = [UserData dataFilePath:[NSString stringWithFormat:@"Inbox/%@", file]];
        DebugLog(@"removed: %@", fullPath);
        [fm removeItemAtPath:fullPath error:&error];
        if (error) {
            DebugLog(@"error: %@", error);
        }
    }
    
    [fm removeItemAtPath:[UserData dataFilePath:@"temp.plist"] error:nil];
}

- (void)confirmRestore {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                   message:@"Please confirm once again that you want to REPLACE ALL ANIMATIONS in the app with those found in the backup. Tap “Confirm” to proceed."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self restoreBackup];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             [self cleanInbox];
                                                         }];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - Refresh stuff

- (void)removeStatusLabel {
    self.statusLabel.text = @"";
    self.statusView.hidden = YES;
    self.statusProgress.hidden = YES;
    
    if (self.isRestoring) {
        self.isRestoring = NO;
        [self restoreComplete];
    }
}

- (void)refreshThumbnails {
    self.currentRefresh = 0;

    srand ((int)time(NULL));
    
    [UserData emptyUserFolder];

    [self updateRefreshText];

    dispatch_async(self.refreshQueue, ^{
        [self refreshNext];
    });
}

- (void)updateRefreshText {
    NSInteger animationCount = self.appDelegate.appData.userAnimations.count;
    self.statusView.hidden = NO;
    self.statusProgress.hidden = YES;
    NSArray *emojiArray = @[@"👯", @"💁", @"👻", @"🙃", @"😶", @"🤖", @"👾", @"🎃", @"⏳", @"😎", @"🐌", @"🐢"];
    int emojiCount = (int)emojiArray.count;
    int index = rand()%emojiCount;
    NSString *emoji = [emojiArray objectAtIndex:index];
    
    self.statusLabel.text = [NSString stringWithFormat:@"%@\n\nPerforming GIFness\nfor animation\n%d of %d\n\n%@", emoji, self.currentRefresh+1, (int)animationCount, emoji];
}

- (void)refreshNext {
    NSInteger animationCount = self.appDelegate.appData.userAnimations.count;
    NSDictionary *animation;
    NSArray *frames;
    NSMutableArray *drawViewArray;

    animation = (NSDictionary *)[self.appDelegate.appData.userAnimations objectAtIndex:self.currentRefresh];
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

    self.currentRefresh++;
    
    if (self.currentRefresh < animationCount) {
        // dispatch again
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC));

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRefreshText];
        });
        dispatch_after(popTime, self.refreshQueue, ^{
            [self refreshNext];
        });
    } else {
        // stop
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeStatusLabel];
        });
    }
}

#pragma mark - Interaction events

- (IBAction)onRefreshTapped:(id)sender {
    if (self.appDelegate.appData.userAnimations.count == 0) return;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Refresh thumbnails"
                                                                   message:@"Tap “Refresh” if the thumbnails you see do not match your animation. None of your animations will be modified. This may take a while depending on how many animations you have."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Refresh" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self refreshThumbnails];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:NO completion:nil];
}

- (IBAction)onReturnTapped:(id)sender {
    [self.delegate infoViewControllerDidFinish:self];
}

- (IBAction)onBackupTapped:(id)sender {
    if (self.appDelegate.appData.userAnimations.count == 0) return;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Backup animations"
                                                                   message:@"Tap “Backup” to create a zip file with your data and save it somewhere. This may take a while depending on how many animations you have."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Backup" style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self saveBackup];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:NO completion:nil];
}

@end
