//
//  UIImageXtras.h
//  CameraTest
//
//  Created by Mauricio Giraldo A on 9/3/12.
//  Copyright (c) 2012 Ping Pong Estudio. All rights reserved.
//
//  Based on http://www.catamount.com/forums/viewtopic.php?f=21&t=967
//

#import <UIKit/UIKit.h>

@interface UIImage (CS_Extensions)

- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
- (NSString *)saveToDiskWithName:(NSString *)name;
- (NSString *)saveToDisk;

@end
