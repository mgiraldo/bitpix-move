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

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _userAnimations = [coder decodeObjectForKey:@"userAnimations"];
        _data = [coder decodeObjectForKey:@"data"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.userAnimations forKey:@"userAnimations"];
    [coder encodeObject:self.data forKey:@"data"];
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

- (void)deleteAnimationWithUUID:(NSString *)uuid {
    NSUInteger index = [self.userAnimations indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *animation = (NSDictionary *)obj;
        BOOL found = [[animation objectForKey:@"name"] isEqualToString:uuid];
        return found;
    }];
    
    if (index != NSNotFound) {
        [self deleteAnimationAtIndex:index];
    }
}

- (NSString *)deleteAnimationAtIndex:(NSInteger)index {
    NSDictionary *animation = [self.userAnimations objectAtIndex:index];
    NSString *uuid = [animation valueForKey:@"name"];
    [self.userAnimations removeObjectAtIndex:index];
    [self save];
    return uuid;
}

- (void)deleteFilesWithUUID:(NSString *)uuid {
    [self removeThumbnailsForUUID:uuid];
    [self removeAnimationImageForUUI:uuid];
}

- (NSDictionary *)duplicateAnimationWithUUID:(NSString *)uuid withUUID:(NSString *)toUUID {
    NSUInteger index = [self.userAnimations indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *animation = (NSDictionary *)obj;
        BOOL found = [[animation objectForKey:@"name"] isEqualToString:uuid];
        return found;
    }];
    
    if (index != NSNotFound) {
        NSDictionary *result = [self duplicateAnimationAtIndex:index withUUID:toUUID];
        return result;
    }
    
    return nil;
}

- (NSDictionary *)duplicateAnimationAtIndex:(NSInteger)index withUUID:(NSString *)uuid {
    NSMutableDictionary *animation = [[self.userAnimations objectAtIndex:index] mutableCopy];
    NSString *olduuid = [animation valueForKey:@"name"];
    NSDate *today = [NSDate date];
    NSArray *frames = [animation objectForKey:@"frames"];
    NSNumber *frameCount = [NSNumber numberWithInteger:frames.count];
    [animation setValue:uuid forKey:@"name"];
    [animation setValue:today forKey:@"date"];
    NSInteger newIndex = (index == self.userAnimations.count-1) ? self.userAnimations.count : index + 1;
    [self.userAnimations insertObject:animation atIndex:newIndex];
    [self save];
    NSDictionary *result = [NSDictionary dictionaryWithObjects:@[olduuid, uuid, frameCount] forKeys:@[@"olduuid", @"newuuid", @"frameCount"]];
    return result;
}

+ (void)emptyUserFolder {
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSArray *filelist= [fm contentsOfDirectoryAtPath:[UserData dataFilePath:@""] error:nil];
    NSString *fullPath;
    
    if (filelist == nil) {
        return;
    }
    
    for (NSString *file in filelist) {
        if ([file isEqualToString:@"Data.plist"]) continue;
        fullPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@", file]];
        [fm removeItemAtPath:fullPath error:nil];
    }
}

- (void)copyFilesFrom:(NSString *)fromUUID to:(NSString *)toUUID withCount:(NSInteger)count {
    DebugLog(@"copying %ld files from %@ to %@", (long)count, fromUUID, toUUID);
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *fromPath, *toPath;
    NSError *error;
    // create the folder
    NSString *dirPath = [UserData dataFilePath:toUUID];
    [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    // add the gif
    fromPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@.gif", fromUUID]];
    toPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@.gif", toUUID]];
    [fm copyItemAtPath:fromPath toPath:toPath error:&error];
    if (error) {
        DebugLog(@"error: %@", error);
    }
    // copy each frame
    for (int i=0; i<count; i++) {
        fromPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@/%@%s%d.png", fromUUID, fromUUID, _fileSuffix, i]];
        toPath = [UserData dataFilePath:[NSString stringWithFormat:@"%@/%@%s%d.png", toUUID, toUUID, _fileSuffix, i]];
        [fm copyItemAtPath:fromPath toPath:toPath error:&error];
        if (error) {
            DebugLog(@"error: %@", error);
        }
    }
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
        NSString *thumbname = [NSString stringWithFormat:@"%@/%@%s%d.png", path, uuid, _fileSuffix, i];
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
//    DebugLog(@"saved appdata plist: %@", [UserData dataFilePath:@"Data.plist"]);
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
