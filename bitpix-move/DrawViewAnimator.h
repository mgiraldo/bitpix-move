//
//  DrawViewAnimator.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DrawView.h"

@interface DrawViewAnimator : UIImageView

- (void)animateWithFrames:(NSArray *)framesArray andSpeed:(int)fps;

@end
