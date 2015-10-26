//
//  DrawViewAnimator.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "DrawViewAnimator.h"
#import "Config.h"

@implementation DrawViewAnimator

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
    if (self) {
        self.speed = _fps;
    }
    return self;
}

- (void)createFrames:(NSArray *)framesArray {
    self.imageArray = [@[] mutableCopy];
    for (int i = 0; i < framesArray.count; i++) {
        DrawView *drawView = [framesArray objectAtIndex:i];
        UIImage *frameImage = [UIImage imageWithCGImage:drawView.drawingImageView.image.CGImage];
        [self.imageArray addObject:frameImage];
    }
    self.image = self.imageArray[0];
}

- (void)animate {
    self.animationImages = self.imageArray;
    self.animationRepeatCount = 0;
    self.animationDuration = 1.0f/self.speed;
    [self startAnimating];
}

@end
