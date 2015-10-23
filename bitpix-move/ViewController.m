//
//  ViewController.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 21/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"

@interface ViewController ()

@end

@implementation ViewController

static UIColor *_sketchColor;

- (void)addFrame {
	DrawView *drawView = [[DrawView alloc] initWithFrame:self.sketchView.bounds];
	[self.framesArray addObject:drawView];
	[self.sketchView addSubview:drawView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	_sketchColor = [UIColor redColor];
	self.sketchView.backgroundColor = _sketchColor;
	self.framesArray = [[NSMutableArray alloc] initWithCapacity:1];
	[self addFrame];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
