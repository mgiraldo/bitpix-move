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

    NSFileManager *fm = [[NSFileManager alloc] init];
    NSArray *filelist= [fm contentsOfDirectoryAtPath:[UserData dataFilePath:filename] error:nil];
    
    if (filelist == nil) {
        DebugLog(@"error loading thumb images");
        return;
    }

    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:filelist.count];
    
    for (NSString *file in filelist) {
        NSString *fullPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@/%@", filename, file]];
        UIImage *frame = [UIImage imageWithContentsOfFile:fullPath];
        [frames addObject:frame];
    }
    
    if (self.thumbnailView == nil) {
        self.thumbnailView = [[ThumbnailView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:self.thumbnailView];
    }
    
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
