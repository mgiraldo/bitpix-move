//
//  UserData.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "UserData.h"
#import "Config.h"
#import "UIImageXtras.h"

@implementation UserData

- (id)init {
    self = [super init];
    if (self) {
        //
    }
    return self;
}

- (id)initWithDefaultData {
    self = [super init];
    if (self) {
        [self load];
    }
    return self;
}

- (void)load {
    if (self.data==nil) {
//        DebugLog(@"had to reload");
        [self reload];
    }
}

- (void)reload {
    NSFileManager *fm = [[NSFileManager alloc] init];
    BOOL dataExists = [fm fileExistsAtPath:[UserData dataFilePath:@"Data.plist"]];
    if (dataExists) {
        NSDictionary *userDictionary = [[NSDictionary alloc] initWithContentsOfFile:[UserData dataFilePath:@"Data.plist"]];
        self.data = [[NSMutableDictionary alloc] initWithDictionary:userDictionary];
        DebugLog(@"loaded: %@", [UserData dataFilePath:@"Data.plist"]);
    } else {
        NSDictionary *defaultDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"]];
        self.data = [[NSMutableDictionary alloc] initWithDictionary:defaultDictionary];
    }
    
    self.userAnimations = [@[] mutableCopy];
    if ([[self.data objectForKey:@"userAnimations"] isKindOfClass:[NSDictionary class]]) {
        // legacy stuff
        NSDictionary *animations = [NSDictionary dictionaryWithDictionary:[self.data objectForKey:@"userAnimations"]];
        for (NSString *key in animations) {
            NSMutableDictionary *animation = [[NSDictionary dictionaryWithDictionary:[animations objectForKey:key]] mutableCopy];
            [animation setObject:key forKey:@"name"];
            [self.userAnimations addObject:animation];
        }
    } else {
        self.userAnimations = [[NSArray arrayWithArray:[self.data objectForKey:@"userAnimations"]] mutableCopy];
    }

    NSLog(@"size: %lu", (unsigned long)self.userAnimations.count);
}

- (void)deleteAnimationAtIndex:(NSInteger)index {
    NSDictionary *animation = [self.userAnimations objectAtIndex:index];
    NSString *uuid = [animation valueForKey:@"name"];
    [self removeThumbnailsForUUID:uuid];
    [self removeAnimationImageForUUI:uuid];
    [self.userAnimations removeObjectAtIndex:index];
    [self save];
}

- (void)removeThumbnailsForUUID:(NSString *)uuid {
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *path = [NSString stringWithFormat:@"%@", uuid];
    NSString *fullPath = [UserData dataFilePath:path];
    
    [fm removeItemAtPath:fullPath error:nil];
}

- (void)createThumbnailsForUUID:(NSString *)uuid withArray:(NSArray *)thumbArray {
    [self removeThumbnailsForUUID:uuid];
    NSString *path = [NSString stringWithFormat:@"%@", uuid];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *fullPath = [UserData dataFilePath:path];
    [fm createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    int i;
    for (i=0; i<thumbArray.count; i++) {
        NSString *thumbname = [NSString stringWithFormat:@"%@/%@_t%d.png", path, uuid, i];
        NSLog(@"th: %@", thumbname);
        UIImage *thumbnail = [thumbArray objectAtIndex:i];
        [thumbnail saveToDiskWithName:thumbname];
    }
}

- (void)removeAnimationImageForUUI:(NSString *)uuid {
    NSString *filename = [NSString stringWithFormat:@"%@.gif", uuid];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *path = [NSString stringWithFormat:@"%@", filename];
    NSString *fullPath = [UserData dataFilePath:path];
    [fm removeItemAtPath:fullPath error:nil];
}

- (void)resetDataFile {
    NSDictionary *defaultDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"]];
    self.data = [[NSMutableDictionary alloc] initWithDictionary:defaultDictionary];
    self.userAnimations = [[NSMutableArray alloc] initWithArray:[self.data objectForKey:@"userAnimations"]];
}

- (void)save {
    DebugLog(@"saved appdata plist: %@", [UserData dataFilePath:@"Data.plist"]);
    [self.data setObject:self.userAnimations forKey:@"userAnimations"];
    //escribir el plist
    [self.data writeToFile:[UserData dataFilePath:@"Data.plist"] atomically:YES];
}

+ (NSString *)dataFilePath:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingPathComponent:filename];
}

@end
