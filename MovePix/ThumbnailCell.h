//
//  ThumbnailCell.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 25/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailView.h"

@interface ThumbnailCell : UICollectionViewCell

@property (nonatomic) float duration;
@property (nonatomic) NSInteger frameCount;
@property (nonatomic) NSString *filename;
@property (nonatomic) ThumbnailView *thumbnailView;

@end
