//
//  AppDelegate.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserData.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UserData *appData;
@property (nonatomic) UIWindow *window;
@property (nonatomic) dispatch_queue_t backgroundSaveQueue;
@property (nonatomic) NSURL *restoreURL;

@end

