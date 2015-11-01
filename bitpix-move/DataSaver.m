//
//  DataSaver.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 31/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "DataSaver.h"

@interface DataSaver()
@property (nonatomic, readwrite) NSIndexPath *indexPath;
@property (nonatomic, readwrite) DrawViewAnimator *animation;
@property (nonatomic, readwrite) UserData *appData;
@end

@implementation DataSaver

- (id)initWithUserData:(UserData *)data delegate:(id<DataSaverDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        self.appData = data;
    }
    return self;
}

- (id)initWithDrawViewAnimator:(DrawViewAnimator *)animation atIndexPath:(NSIndexPath *)indexPath delegate:(id<DataSaverDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        self.indexPath = indexPath;
        self.animation = animation;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if (self.isCancelled) return;
    }
}

@end
