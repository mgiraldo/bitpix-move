//
//  DrawView.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrawView : UIView

@property (nonatomic) UIImageView *drawingImageView;
@property (nonatomic) NSMutableArray *lineList;
@property (nonatomic) NSMutableArray *lastLine;

@end
