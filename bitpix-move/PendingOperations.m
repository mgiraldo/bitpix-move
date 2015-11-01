//
//  PendingOperations.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 31/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "PendingOperations.h"

@implementation PendingOperations

- (NSOperationQueue *)actionQueue {
    if (!_actionQueue) {
        _actionQueue = [[NSOperationQueue alloc] init];
        _actionQueue.name = @"Action Queue";
//        _actionQueue.maxConcurrentOperationCount = 1;
    }
    return _actionQueue;
}

@end
