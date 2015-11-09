//
//  DrawView.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "DrawView.h"
#import "UIImageXtras.h"
#import "Config.h"

@implementation DrawView

- (id)initWithFrame:(CGRect)rect {
	self = [super initWithFrame:rect];
	if (self) {
        self.isClean = YES;
		self.strokeColor = [UIColor blackColor];
		self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
		self.lineList = [[NSMutableArray alloc] initWithCapacity:1];
		self.drawingImageView = [[UIImageView alloc] initWithFrame:self.frame];
		self.drawingImageView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:_opacity];
		[self addSubview:self.drawingImageView];
	}
	return self;
}

- (void)resetLastLine {
	self.lastLine = [[NSMutableArray alloc] initWithCapacity:1];
}

- (NSString *)linesToSVGString {
    NSMutableString *svg = [@"" mutableCopy];
    ///////////////
    NSUInteger l = self.lineList.count;
    NSArray *lines;
    int i, j;
    NSArray *fromArray;
    NSMutableArray *path;
    [svg appendString:[NSString stringWithFormat:@"<rect id=\"Background\" stroke=\"none\" fill=\"#FFFFFF\" x=\"0\" y=\"0\" width=\"%d\" height=\"%d\"></rect>", _animationSize, _animationSize]];
    for (i=0; i<l; i++) {
        lines = [NSArray arrayWithArray:[self.lineList objectAtIndex:i]];
        path = [@[] mutableCopy];
        fromArray = [lines objectAtIndex:0];
        [path addObject:[NSString stringWithFormat:@"M%f,%f", [[fromArray objectAtIndex:0] floatValue], [[fromArray objectAtIndex:1] floatValue]]];
        for (j=1; j<lines.count; j++) {
            fromArray = [lines objectAtIndex:j];
            [path addObject:[NSString stringWithFormat:@"L%f,%f", [[fromArray objectAtIndex:0] floatValue], [[fromArray objectAtIndex:1] floatValue]]];
        }
        [svg appendString:[NSString stringWithFormat:@"<path d=\"%@\" id=\"Path-%d\" sketch:type=\"MSShapeGroup\"></path>", [path componentsJoinedByString:@" "], i]];
    }
    ///////////////
    return svg;
}

- (void)drawLines {
//	NSLog(@"draw");
	NSUInteger l = self.lineList.count;
	NSArray *lines;
	int i, j;
	NSArray *fromArray;
    NSArray *toArray;
    
    // clear the canvas
    self.drawingImageView.image = [UIImage imageNamed:@""];
    
	UIGraphicsBeginImageContext(self.drawingImageView.frame.size);
	
    [self.drawingImageView.image drawInRect:CGRectMake(self.drawingImageView.bounds.origin.x, self.drawingImageView.bounds.origin.y, self.drawingImageView.frame.size.width, self.drawingImageView.frame.size.height)];
	
    for (i=0; i<l; i++) {
		lines = [NSArray arrayWithArray:[self.lineList objectAtIndex:i]];
		for (j=0; j<lines.count-1; j++) {
            fromArray = [lines objectAtIndex:j];
            toArray = [lines objectAtIndex:j+1];
			[self drawLineInContext:UIGraphicsGetCurrentContext() from:fromArray endPoint:toArray];
		}
	}
	// draw the current line
	if (self.lastLine.count > 0) {
		for (j=0; j<self.lastLine.count-1; j++) {
            fromArray = [self.lastLine objectAtIndex:j];
            toArray = [self.lastLine objectAtIndex:j+1];
			[self drawLineInContext:UIGraphicsGetCurrentContext() from:fromArray endPoint:toArray];
		}
	}
	self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

- (void)drawRect:(CGRect)rect {
	[self drawLines];
}

- (void)addTouch:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	NSNumber *x = [NSNumber numberWithFloat:p.x];
    NSNumber *y = [NSNumber numberWithFloat:p.y];
	[self.lastLine addObject:@[x,y]];
	[self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"began");
    self.isClean = NO;
	[self resetLastLine];
	[self addTouch:touches withEvent:event];
    [self.delegate drawViewTouchesBegan:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"move");
	[self addTouch:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"end");
	[self addTouch:touches withEvent:event];
	[self.lineList addObject:[NSArray arrayWithArray:self.lastLine]];
	[self resetLastLine];
    [self.delegate drawViewChanged:self];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"cancel");
	[self touchesEnded:touches withEvent:event];
}

- (void)drawLineInContext:(CGContextRef)context from:(NSArray *)fromArray endPoint:(NSArray *)toArray {
    CGPoint from = CGPointMake([[fromArray objectAtIndex:0] floatValue], [[fromArray objectAtIndex:1] floatValue]);
    CGPoint to = CGPointMake([[toArray objectAtIndex:0] floatValue], [[toArray objectAtIndex:1] floatValue]);

    [self.strokeColor set];
	CGContextSetLineWidth(context, _lineWidth);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, from.x, from.y);
	CGContextAddLineToPoint(context, to.x , to.y);
	
	CGContextStrokePath(context);
}

- (void)undo {
    if (self.lineList.count > 0) {
        [self.lineList removeObject:self.lineList.lastObject];
    }
    [self drawLines];
}

- (BOOL)hasLines {
    return self.lineList.count > 0;
}

@end
