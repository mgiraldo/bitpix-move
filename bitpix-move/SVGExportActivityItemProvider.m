//
//  SVGExportActivityItemProvider.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 8/11/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "SVGExportActivityItemProvider.h"
#import "Config.h"

@implementation SVGExportActivityItemProvider

- (id)item {
    NSString *activityType = self.activityType;
    if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        return self.gifData;
    } else if ([activityType isEqualToString:UIActivityTypePostToFlickr]) {
        return self.gifData;
    } else if ([activityType isEqualToString:@"com.pingpongestudio.movePix"]) {
        return self.svgString;
    } else {
        return self.gifData;
    }
    return self.gifData;
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
    NSString *messageBody = @"Made with MovePix\nhttp://bitpix.co/move";
    
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
