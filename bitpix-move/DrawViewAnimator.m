//
//  DrawViewAnimator.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "DrawViewAnimator.h"

@implementation DrawViewAnimator

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

//- (id)initWithFrame:(CGRect)rect {
//    self = [super initWithFrame:rect];
//    if (self) {
//        //
//    }
//    return self;
//}

- (void)animateWithFrames:(NSArray *)framesArray andSpeed:(int)fps {
    NSMutableArray *imageArray = [@[] mutableCopy];
    for (int i = 0; i < framesArray.count; i++) {
        DrawView *drawView = [framesArray objectAtIndex:i];
        UIImage *frameImage = [UIImage imageWithCGImage:drawView.drawingImageView.image.CGImage];
        [imageArray addObject:frameImage];
    }
    
    self.animationImages = imageArray;
    self.animationRepeatCount = 0;
    self.animationDuration = 1.0f/fps;
    
    self.image = imageArray[0];
    [self startAnimating];
}

@end
