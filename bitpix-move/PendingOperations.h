//
//  PendingOperations.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 31/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PendingOperations : NSObject

@property (nonatomic) NSMutableDictionary *actionsInProgress;
@property (nonatomic) NSOperationQueue *actionQueue;

@property (nonatomic) NSMutableDictionary *animationsInProgress;
@property (nonatomic) NSOperationQueue *animationQueue;

@end
