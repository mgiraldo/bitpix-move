//
//  AppDelegate.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "AppDelegate.h"
#import "Config.h"
#import "Objective-Zip.h"
#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

static const int BUFFER_SIZE = 1024;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
    self.appData = [[UserData alloc] initWithDefaultData];
    self.backgroundSaveQueue = dispatch_queue_create("com.pingpongestudio.bitpix-move.bgqueue", NULL);
	return YES;
}

- (void)restoreBackup {
    NSString *dataFilePath = [UserData dataFilePath:@"temp.plist"];
    [[NSFileManager defaultManager] createFileAtPath:dataFilePath contents:nil attributes:nil];
    MainViewController *vc = (MainViewController *)self.window.rootViewController;
    vc.statusView.hidden = NO;
    vc.statusLabel.text = @"⌛️\n\nPlease wait while your backup is restored…\n\n⏳";
    dispatch_async(self.backgroundSaveQueue, ^{
        @try {
            DebugLog(@"path: %@ exists: %d", dataFilePath, [[NSFileManager defaultManager] fileExistsAtPath:dataFilePath]);
            
            OZZipFile *unzipFile= [[OZZipFile alloc] initWithFileName:self.restoreURL.path
                                                                 mode:OZZipFileModeUnzip];
            [unzipFile goToFirstFileInZip];
            
            OZZipReadStream *read= [unzipFile readCurrentFileInZip];
            NSMutableData *buffer = [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
            NSMutableData *data= [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
            NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:dataFilePath];
            
            do {
                
                // Reset buffer length
                [buffer setLength:BUFFER_SIZE];
                
                // Read bytes and check for end of file
                int bytesRead= [read readDataWithBuffer:data];
                if (bytesRead <= 0)
                    break;
                
                [buffer setLength:bytesRead];
                [file writeData:buffer];
                
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
            [self.window.rootViewController presentViewController:alert animated:NO completion:nil];
        }
        @finally {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
            dispatch_after(popTime, self.backgroundSaveQueue, ^{
                NSError *error;
                NSData *data = [NSData dataWithContentsOfFile:dataFilePath];
                if (error) {
                    DebugLog(@"error: %@", error);
                }
                
                DebugLog(@"data: %@", data);
                [self cleanInbox];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                                   message:@"Import is complete!"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction * action) {}];
                    
                    [alert addAction:okAction];
                    [self.window.rootViewController presentViewController:alert animated:NO completion:nil];
                    MainViewController *vc = (MainViewController *)self.window.rootViewController;
                    vc.statusView.hidden = YES;
                    vc.statusLabel.text = @"";
                });
            });
        }
    });
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
    [self.window.rootViewController presentViewController:alert animated:NO completion:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // NOTE: deprecated in iOS 9.0! added for lower iOS support
    self.restoreURL = url;
    
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
    [self.window.rootViewController presentViewController:alert animated:NO completion:nil];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
