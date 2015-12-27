//
//  FrameCellCollectionViewCell.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 26/12/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "FrameCell.h"

@implementation FrameCell

- (void)setFilename:(NSString *)filename {
    self.backgroundColor = [UIColor whiteColor];
    self.frameImageView.backgroundColor = [UIColor whiteColor];
    
    UIImage *frame = [UIImage imageWithContentsOfFile:filename];
    self.frameImageView.image = frame;
}

@end
