//
//  UserData.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserData : NSObject <NSCoding>

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
- (NSString *)deleteAnimationAtIndex:(NSInteger)index;
- (void)deleteFilesWithUUID:(NSString *)uuid;
- (NSDictionary *)duplicateAnimationAtIndex:(NSInteger)index withUUID:(NSString *)uuid;
- (void)copyFilesFrom:(NSString *)fromUUID to:(NSString *)toUUID withCount:(NSInteger)count;
- (void)save;

@end
