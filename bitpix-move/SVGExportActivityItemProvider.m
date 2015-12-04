//
//  SVGExportActivityItemProvider.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 8/11/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "SVGExportActivityItemProvider.h"
#import "Config.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation SVGExportActivityItemProvider

- (id)item {
    NSString *activityType = self.activityType;
    DebugLog(@"activity: %@", activityType);
    if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        return self.videoURL;
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypePostToFlickr]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypeSaveToCameraRoll]) {
        return self.gifData;
    } else if ([activityType isEqualToString:@"UIActivityTypePostToInstagram"]) {
        return self.videoURL;
    } else if ([activityType isEqualToString:@"net.whatsapp.WhatsApp.ShareExtension"]) {
        return self.videoURL;
    } else if ([activityType isEqualToString:@"com.viber.app-share-extension"]) {
        return self.videoURL;
    } else if ([activityType isEqualToString:@"ph.telegra.Telegraph.Share"]) {
        return self.videoURL;
    } else if ([activityType isEqualToString:@"com.pingpongestudio.movePix"]) {
        return self.svgString;
    } else {
        return self.gifData;
    }
}

@end


@implementation VideoSaveActivityIcon

- (NSString *)activityType {
    return @"com.pingpongestudio.movePix.video";
}

- (NSString *)activityTitle {
        return @"Save as video";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"video-icon.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:self.videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
        //
    }];
}

@end

@implementation SVGCopyActivityIcon

- (NSString *)activityType {
    return @"com.pingpongestudio.movePix";
}

- (NSString *)activityTitle {
    return @"Copy SVG";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"svg-icon.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSString *svgString = (NSString *)[activityItems firstObject];
    NSData *svgData = [svgString dataUsingEncoding:NSUTF8StringEncoding];
    [[UIPasteboard generalPasteboard] setData:svgData forPasteboardType:self.activityType];
}

@end


@implementation SVGEmailActivityIcon

- (NSString *)activityType {
    return @"com.pingpongestudio.movePix";
}

- (NSString *)activityTitle {
    return @"Email SVG";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"svg-icon.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (UIViewController *)activityViewController {
    // Email Subject
    NSString *emailTitle = @"MovePix Animation SVG";
    // Email Content
    NSString *messageBody = @"This SVG is organized as a group of frames, each frame in its own nested group of lines and background (last frame top). You can open this file in vector-editing software such as Sketch or Adobe Illustrator.\n\nMade with MovePix\nhttp://movepix.co";
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc addAttachmentData:self.svgData mimeType:@"image/svg+xml" fileName:@"MovePixAnimation.svg"];
    
    return mc;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            [self activityDidFinish:NO];
            break;
        case MFMailComposeResultSaved:
            [self activityDidFinish:NO];
            break;
        case MFMailComposeResultSent:
            [self activityDidFinish:YES];
            break;
        case MFMailComposeResultFailed:
            [self activityDidFinish:NO];
            break;
        default:
            [self activityDidFinish:NO];
            break;
    }
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSString *svgString = (NSString *)[activityItems firstObject];
    self.svgData = [svgString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
