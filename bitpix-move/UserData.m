//
//  UserData.m
//  bitpix-move
//
//  Created by Mauricio Giraldo on 24/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#import "UserData.h"

#ifdef DEBUG
#define DebugLog( s, ... ) NSLog( @"<%p %@:%d (%@)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  NSStringFromSelector(_cmd), [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DebugLog( s, ... )
#endif

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
        DebugLog(@"had to reload");
        [self reload];
    }
}

- (void)reload {
    NSFileManager *fm = [[NSFileManager alloc] init];
    BOOL dataExists = [fm fileExistsAtPath:[UserData dataFilePath:@"Data.plist"]];
    if (dataExists) {
        NSDictionary *userDictionary = [[NSDictionary alloc] initWithContentsOfFile:[UserData dataFilePath:@"Data.plist"]];
        self.data = [[NSMutableDictionary alloc] initWithDictionary:userDictionary];
    } else {
        NSDictionary *defaultDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"]];
        self.data = [[NSMutableDictionary alloc] initWithDictionary:defaultDictionary];
    }
    self.userAnimations = [[NSMutableDictionary alloc] initWithDictionary:[self.data objectForKey:@"userAnimations"]];
    NSLog(@"size: %lu", (unsigned long)[self.userAnimations allKeys].count);
}

- (void)resetDataFile {
    NSDictionary *defaultDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"]];
    self.data = [[NSMutableDictionary alloc] initWithDictionary:defaultDictionary];
    self.userAnimations = [[NSMutableDictionary alloc] initWithDictionary:[self.data objectForKey:@"userAnimations"]];
}

- (void)save {
    DebugLog(@"saved appdata plist");
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
