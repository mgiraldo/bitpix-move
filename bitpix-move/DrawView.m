//
//  DrawView.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "DrawView.h"

@implementation DrawView

static float _lineWidth = 2.0f;
static float _opacity = 0.8f;
static UIColor *_strokeColor;

- (id)initWithFrame:(CGRect)rect {
	self = [super initWithFrame:rect];
	if (self) {
		_strokeColor = [UIColor blackColor];
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

- (void)drawLines {
//	NSLog(@"draw");
	NSUInteger l = self.lineList.count;
	NSArray *lines;
	int i, j;
	NSValue *from;
	NSValue *to;
	UIGraphicsBeginImageContext(self.drawingImageView.frame.size);
	[self.drawingImageView.image drawInRect:CGRectMake(self.drawingImageView.bounds.origin.x, self.drawingImageView.bounds.origin.y, self.drawingImageView.frame.size.width, self.drawingImageView.frame.size.height)];
	for (i=0; i<l; i++) {
		lines = [NSArray arrayWithArray:[self.lineList objectAtIndex:i]];
		for (j=0; j<lines.count-1; j++) {
			from = [lines objectAtIndex:j];
			to = [lines objectAtIndex:j+1];
			[self drawLineInContext:UIGraphicsGetCurrentContext() from:from endPoint:to];
		}
	}
	// draw the current line
	if (self.lastLine.count > 0) {
		for (j=0; j<self.lastLine.count-1; j++) {
			from = [self.lastLine objectAtIndex:j];
			to = [self.lastLine objectAtIndex:j+1];
			[self drawLineInContext:UIGraphicsGetCurrentContext() from:from endPoint:to];
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
	NSValue* point = [NSValue valueWithCGPoint:p];
	[self.lastLine addObject:point];
	[self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"began");
	[self resetLastLine];
	[self addTouch:touches withEvent:event];
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
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"cancel");
	[self touchesEnded:touches withEvent:event];
}

- (void)drawLineInContext:(CGContextRef)context from:(NSValue*)fromValue endPoint:(NSValue*)toValue {
	CGPoint from = [fromValue CGPointValue];
	CGPoint to = [toValue CGPointValue];

	[_strokeColor set];
	CGContextSetLineWidth(context, _lineWidth);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, from.x, from.y);
	CGContextAddLineToPoint(context, to.x , to.y);
	
	CGContextStrokePath(context);
}

//
//// Drawings a line onscreen based on where the user touches
//- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
//{
//	static GLfloat*		vertexBuffer = NULL;
//	static NSUInteger	vertexMax = 64;
//	NSUInteger			vertexCount = 0,
//	count,
//	i;
//	
//	[EAGLContext setCurrentContext:context];
//	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
//	
//	// Convert locations from Points to Pixels
//	CGFloat scale = self.contentScaleFactor;
//	start.x *= scale;
//	start.y *= scale;
//	end.x *= scale;
//	end.y *= scale;
//	
//	// Allocate vertex array buffer
//	if(vertexBuffer == NULL)
//		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
//	
//	// Add points to the buffer so there are drawing points every X pixels
//	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
//	for(i = 0; i < count; ++i) {
//		if(vertexCount == vertexMax) {
//			vertexMax = 2 * vertexMax;
//			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
//		}
//		
//		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
//		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
//		vertexCount += 1;
//	}
//	
//	// Load data to the Vertex Buffer Object
//	glBindBuffer(GL_ARRAY_BUFFER, vboId);
//	glBufferData(GL_ARRAY_BUFFER, vertexCount*2*sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
//	
//	glEnableVertexAttribArray(ATTRIB_VERTEX);
//	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);
//	
//	// Draw
//	glUseProgram(program[PROGRAM_POINT].id);
//	glDrawArrays(GL_POINTS, 0, (int)vertexCount);
//	
//	// Display the buffer
//	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
//	[context presentRenderbuffer:GL_RENDERBUFFER];
//}

@end
