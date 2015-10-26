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

    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@",dir,filename];
    BOOL fileExists = [fm fileExistsAtPath:pngFilePath];
    
    if (!fileExists) return;

    UIImage *img = [UIImage imageWithContentsOfFile:pngFilePath];
    
    self.backgroundColor = [UIColor whiteColor];
    self.thumbnailView.image = img;
    
    NSLog(@"image: %@", img);
    NSLog(@"path: %@", pngFilePath);
}

@end
