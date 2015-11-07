//
//  ThumbnailCell.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 25/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "ThumbnailCell.h"
#import "UserData.h"
#import "Config.h"

@implementation ThumbnailCell

- (void)setFilename:(NSString *)filename {
    _filename = filename;
    
    UIImage *animatedImage = [UIImage animatedImageNamed:[UserData dataFilePath:[NSString stringWithFormat:@"%@/%@%s", filename, filename, _fileSuffix]] duration:self.duration];
    
    if (self.thumbnailView == nil) {
        self.thumbnailView = [[ThumbnailView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:self.thumbnailView];
    }
    
    self.backgroundColor = [UIColor whiteColor];
    self.thumbnailView.backgroundColor = [UIColor whiteColor];
    
    if (animatedImage != nil) {
        self.thumbnailView.image = animatedImage;
        [self.thumbnailView startAnimating];
    }
}

@end
