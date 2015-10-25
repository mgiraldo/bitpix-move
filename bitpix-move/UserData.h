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
@property (nonatomic) NSMutableDictionary *userAnimations;

- (id)initWithDefaultData;
+ (NSString *)dataFilePath:(NSString *)filename;
- (void)load;
- (void)reload;
- (void)resetDataFile;
- (void)save;

@end
