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
@property (nonatomic) NSString  *uuid;
@property (nonatomic) NSMutableArray *framesArray;
@property (nonatomic) NSMutableArray *imageArray;
@property (nonatomic) NSMutableArray *thumbArray;

- (void)createFrames:(NSArray *)framesArray withSpeed:(float)speed;
- (void)resetWithNewUUID:(NSString *)uuid;
- (void)animate;
- (void)stop;
- (NSString *)createSVGString;
- (void)createAllGIFs;
- (void)createLargeGIF;
- (void)createThumbnailGIFs;

@end
