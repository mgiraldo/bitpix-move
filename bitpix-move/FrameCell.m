//
//  FrameCellCollectionViewCell.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 26/12/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "FrameCell.h"

@implementation FrameCell

- (void)setDrawView:(DrawView *)drawView {
    _drawView = drawView;
    [_drawView drawLines];
    self.backgroundColor = [UIColor whiteColor];
    self.frameImageView.backgroundColor = [UIColor whiteColor];
    self.frameImageView.image = [UIImage imageWithCGImage:_drawView.drawingImageView.image.CGImage];
}

- (void)setFilename:(NSString *)filename {
    self.backgroundColor = [UIColor whiteColor];
    self.frameImageView.backgroundColor = [UIColor whiteColor];
    
    UIImage *frame = [UIImage imageWithContentsOfFile:filename];
    self.frameImageView.image = frame;
}

@end
