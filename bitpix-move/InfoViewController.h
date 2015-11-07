//
//  InfoViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 7/11/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class InfoViewController;

@protocol InfoViewControllerDelegate
- (void)infoViewControllerDidFinish:(InfoViewController *)controller;
@end

@interface InfoViewController : UIViewController

@property (nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) id <InfoViewControllerDelegate> delegate;

- (IBAction)onRefreshTapped:(id)sender;
- (IBAction)onReturnTapped:(id)sender;
@end
