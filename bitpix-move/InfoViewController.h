//
//  InfoViewController.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 7/11/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "AppDelegate.h"

@class InfoViewController;

@protocol InfoViewControllerDelegate
- (void)infoViewControllerDidFinish:(InfoViewController *)controller;
@end

@interface InfoViewController : UIViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *statusProgress;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *backupButton;
@property (weak, nonatomic) IBOutlet UIView *borderView;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property (nonatomic, weak) id <InfoViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISwitch *themeSwitch;
@property (nonatomic) dispatch_queue_t refreshQueue;
@property (atomic) int currentRefresh;
@property (nonatomic) BOOL isRestoring;

- (IBAction)onRefreshTapped:(id)sender;
- (IBAction)onReturnTapped:(id)sender;
- (IBAction)onBackupTapped:(id)sender;
- (IBAction)onThemeChanged:(UISwitch *)sender;
@end
