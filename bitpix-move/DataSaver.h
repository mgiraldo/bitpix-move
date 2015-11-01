//
//  DataSaver.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 31/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UserData.h"
#import "DrawViewAnimator.h"

@protocol DataSaverDelegate;

@interface DataSaver : NSOperation

@property (nonatomic, assign) id <DataSaverDelegate> delegate;

@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) DrawViewAnimator *animation;
@property (nonatomic, readonly) UserData *appData;

- (id)initWithUserData:(UserData *)data delegate:(id<DataSaverDelegate>)delegate;
- (id)initWithDrawViewAnimator:(DrawViewAnimator *)animation atIndexPath:(NSIndexPath *)indexPath delegate:(id<DataSaverDelegate>)delegate;

@end

@protocol DataSaverDelegate <NSObject>

- (void)dataSaverDidFinish:(DataSaver *)dataSaver;

@end