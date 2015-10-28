//
//  ThumbnailCell.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 25/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "ThumbnailCell.h"

@implementation ThumbnailCell

- (void)setFilename:(NSString *)filename {
    _filename = filename;

    UIImage *img = [UIImage animatedImageNamed:filename duration:self.duration];
    
    self.backgroundColor = [UIColor whiteColor];
    self.thumbnailView.backgroundColor = [UIColor whiteColor];
    
    if (self.thumbnailView == nil) {
        self.thumbnailView = [[ThumbnailView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:self.thumbnailView];
    }
 
    self.thumbnailView.image = img;
    [self.thumbnailView startAnimating];
}

@end
