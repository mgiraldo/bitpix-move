//
//  FrameCellCollectionViewCell.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 26/12/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"

@interface FrameCell : UICollectionViewCell

@property (nonatomic) DrawView *drawView;
@property (nonatomic) IBOutlet UIImageView *frameImageView;

- (void)setFilename:(NSString *)filename;

@end
