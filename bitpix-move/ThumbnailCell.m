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

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel * loadingLabel = [[UILabel alloc] initWithFrame:self.contentView.frame];
        loadingLabel.text = @"⏳ Loading ⌛️";
        loadingLabel.textColor = [UIColor grayColor];
        loadingLabel.textAlignment = NSTextAlignmentCenter;
        loadingLabel.font = [UIFont systemFontOfSize:10.0f];
        [self.contentView addSubview:loadingLabel];
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 1.0;
    }
    return self;
}

- (void)setFilename:(NSString *)filename {
    _filename = filename;

    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:self.frameCount];
    
    for (int i = 0; i<self.frameCount; i++) {
        NSString *fullPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@/%@%s%d.png", filename, filename, _fileSuffix, i]];
        UIImage *frame = [UIImage imageWithContentsOfFile:fullPath];
        if (frame != nil) [frames addObject:frame];
//        DebugLog(@"frames: %@", fullPath);
    }
    
    if (self.thumbnailView == nil) {
        self.thumbnailView = [[ThumbnailView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:self.thumbnailView];
    }
    
//    DebugLog(@"frames: %@", frames);
    
    self.backgroundColor = [UIColor whiteColor];
    self.thumbnailView.backgroundColor = [UIColor whiteColor];

    if (frames.count > 0) {
        self.thumbnailView.animationImages = frames;
        self.thumbnailView.animationRepeatCount = 0;
        self.thumbnailView.animationDuration = self.duration;
        self.thumbnailView.image = frames[0];
        [self.thumbnailView startAnimating];
    }
}

@end
