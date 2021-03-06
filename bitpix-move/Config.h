//
//  Config.h
//  bitpix-move
//
//  Created by Mauricio Giraldo on 25/10/15.
//  Copyright © 2015 Ping Pong Estudio. All rights reserved.
//

#ifndef Config_h
#define Config_h

#ifdef DEBUG
#define DebugLog( s, ... ) NSLog( @"<%p %@:%d (%@)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  NSStringFromSelector(_cmd), [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DebugLog( s, ... )
#endif

static const float _borderWidth = 5.0f;
static const int _maxFrames = 100;
static float _fps = 6.0f;
static const int _minVideoLength = 3;
static const int _animationSize = 300;
static const int _videoSize = 320;
static const int _thumbSize = 100;
static float _lineWidth = 2.0f;
static float _opacity = 0.8f;
static const char _fileSuffix[] = "_t";
static const float _minHeight = 500.0f;

typedef enum {
    kDeleteAction,
    kDuplicateAction
}actionIDs;

#endif /* Config_h */
