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
    self.imageArray = [@[] mutableCopy];
    self.thumbArray = [@[] mutableCopy];
    for (int i = 0; i < framesArray.count; i++) {
        DrawView *drawView = [framesArray objectAtIndex:i];
        if (drawView.isClean) {
            [drawView drawLines];
        }

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

- (void)createAllGIFs {
    [self createLargeGIF];
    [self createThumbnailGIFs];
}

- (void)createThumbnailGIFs {
    int i;

    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *path = [NSString stringWithFormat:@"%@", self.uuid];
    NSString *fullPath = [UserData dataFilePath:path];
    
    [fm removeItemAtPath:fullPath error:nil];
    [fm createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];

    for (i=0; i<self.thumbArray.count; i++) {
        NSString *thumbname = [NSString stringWithFormat:@"%@/%@_t%d.png", path, self.uuid, i];
        NSLog(@"th: %@", thumbname);
        UIImage *thumbnail = [self.thumbArray objectAtIndex:i];
        [thumbnail saveToDiskWithName:thumbname];
    }
}

- (void)createLargeGIF {
    NSString *filename = [NSString stringWithFormat:@"%@.gif", self.uuid];
    [UIImage saveToDiskAnimatedGIFWithFrames:self.imageArray withName:filename andSpeed:(1.0f/self.speed)];
}

@end
