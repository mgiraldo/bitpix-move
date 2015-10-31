//
//  UserData.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserData : NSObject

@property (nonatomic) NSMutableDictionary *data;
@property (nonatomic) NSMutableArray *userAnimations;

- (id)initWithDefaultData;
+ (NSString *)dataFilePath:(NSString *)filename;
+ (void)emptyUserFolder;
- (void)load;
- (void)reload;
- (void)resetDataFile;
- (void)removeThumbnailsForUUID:(NSString *)uuid;
- (void)createThumbnailsForUUID:(NSString *)uuid withArray:(NSArray *)thumbArray;
- (void)deleteAnimationAtIndex:(NSInteger)index;
- (void)duplicateAnimationAtIndex:(NSInteger)index;
- (void)save;

@end
