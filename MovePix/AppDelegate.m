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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.appData = [[UserData alloc] initWithDefaultData];
    self.backgroundSaveQueue = dispatch_queue_create("com.pingpongestudio.bitpix-move.bgqueue", NULL);
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        NSLog(@"WCSession is supported");
    }
    
    return YES;
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
    if ([[WCSession defaultSession] isReachable]) {
//        if (self.appData.userAnimations.count > 10) {
//            firstTen = [self.appData.userAnimations subarrayWithRange:NSMakeRange(0, 10)];
//        } else {
//            firstTen = [NSArray arrayWithArray:self.appData.userAnimations];
//        }
        NSString *action = message[@"request"];
        if ([action isEqualToString:@"few"]) {
            NSArray *firstFew = [self getFew];
            NSNumber *total = [NSNumber numberWithUnsignedInteger:self.appData.userAnimations.count];
            replyHandler(@{@"total":total, @"uuids": firstFew});
        } else {
            NSDictionary *animation = [self getFramesForUUID:action];
            replyHandler(@{@"animation": animation});
        }
//        [session transferUserInfo:@{@"animations": firstTen}];
    }
}

- (NSArray *)getFew {
    NSMutableArray *firstFew = [@[] mutableCopy];
    NSUInteger limit = 25;

    if (self.appData.userAnimations.count < limit) limit = self.appData.userAnimations.count;

    for (NSUInteger i=0; i<limit; i++) {
        NSDictionary *animation = [self getFramesForIndex:i];
        [firstFew addObject:animation[@"name"]];
    }

    NSArray *few = [NSArray arrayWithArray:firstFew];
    return few;
}

- (NSDictionary *)getFramesForUUID:(NSString *)uuid {
    NSUInteger index = [self.appData indexOfAnimationWithUUID:uuid];
    return [self getFramesForIndex:index];
}

- (NSDictionary *)getFramesForIndex:(NSUInteger)index {
    NSDictionary *animation = [self.appData.userAnimations objectAtIndex:index];
    NSArray *svgframes = [animation objectForKey:@"frames"];
    NSUInteger frameCount = svgframes.count;
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:frameCount];
    NSString *filename = [animation objectForKey:@"name"];
    for (int j = 0; j<frameCount; j++) {
        NSString *fullPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@/%@%s%d.png", filename, filename, _fileSuffix, j]];
        NSData *frameData = [NSData dataWithContentsOfFile:fullPath];
        if (frameData != nil) [frames addObject:frameData];
    }
    return @{@"frames":frames, @"name":filename};
}

- (void)restoreBackup {
    UIStoryboard *sb = self.window.rootViewController.storyboard;
    MainViewController *vc = (MainViewController *)[sb instantiateInitialViewController];
    vc.isRestoring = YES;
    self.window.rootViewController = vc;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // NOTE: deprecated in iOS 9.0! added for lower iOS support
    self.restoreURL = url;
    [self performSelector:@selector(restoreBackup) withObject:nil afterDelay:0.0];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    dispatch_async(self.backgroundSaveQueue, ^{
        @synchronized(self.appData) {
            [self.appData save];
        }
    });
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
