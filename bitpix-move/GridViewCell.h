//
//  GridViewCell.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 25/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailView.h"

@interface GridViewCell : UICollectionViewCell

@property (nonatomic) NSString *filename;
@property (weak, nonatomic) IBOutlet ThumbnailView *thumbnailView;

@end
