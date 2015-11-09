//
//  DrawViewAnimator.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "DrawViewAnimator.h"
#import "Config.h"
#import "UIImageXtras.h"
#import "UserData.h"
#import "AppDelegate.h"

@implementation DrawViewAnimator

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)createFrames:(NSArray *)framesArray withSpeed:(float)speed {
    self.speed = speed;
    self.framesArray = [@[] mutableCopy];
    self.imageArray = [@[] mutableCopy];
    self.thumbArray = [@[] mutableCopy];
    for (int i = 0; i < framesArray.count; i++) {
        DrawView *drawView = [framesArray objectAtIndex:i];
        if (drawView.isClean) {
            [drawView drawLines];
        }
        [self.framesArray addObject:drawView];

        CGFloat width = drawView.drawingImageView.image.size.width;
        CGFloat height = drawView.drawingImageView.image.size.height;
        
        // create a new bitmap image context at the device resolution (retina/non-retina)
        UIGraphicsBeginImageContextWithOptions(drawView.drawingImageView.image.size, YES, 1.0); // 1.0 = non-retina
        
        // get context
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // push context to make it current
        // (need to do this manually because we are not drawing in a UIView)
        UIGraphicsPushContext(context);
        
        [[UIColor whiteColor] set]; //set the desired background color
        UIRectFill(CGRectMake(0.0, 0.0, width, height));
        
        // drawing code comes here- look at CGContext reference
        // for available operations
        // this example draws the inputImage into the context
        [drawView.drawingImageView.image drawInRect:CGRectMake(0, 0, width, height)];
        
        // pop context
        UIGraphicsPopContext();
        
        // get a UIImage from the image context- enjoy!!!
        UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // clean up drawing environment
        UIGraphicsEndImageContext();

        [self.imageArray addObject:outputImage];

        UIImage *thumb = [outputImage scaleToSize:CGSizeMake(_thumbSize, _thumbSize)];
        
        [self.thumbArray addObject:thumb];
    }
    self.image = self.imageArray[0];
}

- (void)resetWithNewUUID:(NSString *)uuid {
    self.thumbArray = [@[] mutableCopy];
    self.imageArray = [@[] mutableCopy];
    self.framesArray = [@[] mutableCopy];
    self.uuid = uuid;
}

- (void)animate {
    self.animationImages = self.imageArray;
    self.animationRepeatCount = 0;
    self.animationDuration = (float)self.imageArray.count / self.speed;
    [self startAnimating];
}

- (void)stop {
    [self stopAnimating];
    self.image = nil;
}

- (NSString *)createSVGString {
    NSMutableString *svg = [@"" mutableCopy];
    [svg appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>"];
    [svg appendString:[NSString stringWithFormat:@"<svg width=\"%dpx\" height=\"%dpx\" viewBox=\"0 0 %d %d\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">", _animationSize, _animationSize, _animationSize, _animationSize]];
    [svg appendString:[NSString stringWithFormat:@"<g id=\"Animation-%@\" stroke=\"none\" stroke-width=\"%f\" fill=\"none\" fill-rule=\"evenodd\">", self.uuid, _lineWidth]];
    ///////////////
    NSUInteger l = self.framesArray.count;
    int i;
    for (i=0; i<l; i++) {
        [svg appendString:[NSString stringWithFormat:@"<g id=\"Frame-%d\" stroke=\"#000000\">", i]];
        DrawView *drawView = [self.framesArray objectAtIndex:i];
        [svg appendString:[drawView linesToSVGString]];
        [svg appendString:@"</g>"];
    }
    ///////////////
    [svg appendString:@"</g>"];
    [svg appendString:@"</svg>"];
    return svg;
}

- (void)createAllGIFs {
    [self createLargeGIF];
    [self createThumbnailGIFs];
}

- (void)createThumbnailGIFs {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate.appData createThumbnailsForUUID:self.uuid withArray:self.thumbArray];
}

- (void)createLargeGIF {
    NSString *filename = [NSString stringWithFormat:@"%@.gif", self.uuid];
    [UIImage saveToDiskAnimatedGIFWithFrames:self.imageArray withName:filename andSpeed:(1.0f/self.speed)];
}

@end
