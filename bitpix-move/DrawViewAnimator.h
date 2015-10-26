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

@property (nonatomic) float speed;
@property (nonatomic) NSMutableArray *imageArray;

- (void)createFrames:(NSArray *)framesArray;
- (void)animate;

@end
