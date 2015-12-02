//
//  SVGExportActivityItemProvider.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 8/11/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SVGExportActivityItemProvider : UIActivityItemProvider

@property (nonatomic) NSData *gifData;
@property (nonatomic) NSString *svgString;
@property (nonatomic) NSURL *videoURL;

@end


@interface VideoSaveActivityIcon : UIActivity

@property (nonatomic) NSURL *videoURL;

@end

@interface SVGCopyActivityIcon : UIActivity

@end

@interface SVGEmailActivityIcon : UIActivity <MFMailComposeViewControllerDelegate>

@property (nonatomic) NSData *svgData;

@end

