//
//  GridViewCell.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 25/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "GridViewCell.h"

@implementation GridViewCell

- (void)setFilename:(NSString *)filename {
    
    if(_filename != filename) {
        _filename = filename;
    }
    
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@",dir,_filename];
    UIImage * img = [UIImage imageWithContentsOfFile:pngFilePath];
    
    self.thumbnailView.image = img;
}

@end
