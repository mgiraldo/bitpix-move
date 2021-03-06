//
//  CEMovieMaker.m
//  CEMovieMaker
//
//  Created by Cameron Ehrlich on 9/17/14.
//  Copyright (c) 2014 Cameron Ehrlich. All rights reserved.
//

#import "CEMovieMaker.h"

@implementation CEMovieMaker

- (instancetype)initWithSettings:(NSDictionary *)videoSettings andName:(NSString *)filename {
    self = [self init];
    if (self) {
        NSError *error;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *tempPath = [documentsDirectory stringByAppendingPathComponent:filename];
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
            if (error) {
                NSLog(@"Error: %@", error.debugDescription);
            }
        }
        
        self.fileURL = [NSURL fileURLWithPath:tempPath];
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.fileURL
                                                 fileType:AVFileTypeQuickTimeMovie error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
        NSParameterAssert(self.assetWriter);
        
        self.videoSettings = videoSettings;
        self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                          outputSettings:videoSettings];
        NSParameterAssert(self.writerInput);
        NSParameterAssert([self.assetWriter canAddInput:self.writerInput]);
        
        [self.assetWriter addInput:self.writerInput];
        
        NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        self.bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
        self.frameTime = CMTimeMake(1, 10);
    }
    return self;
}

- (void)createMovieFromImages:(NSArray *)images withCompletion:(CEMovieMakerCompletion)completion;
{
    self.completionBlock = completion;
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    __block NSInteger i = 0;
    
    NSInteger frameNumber = [images count];
    
    int singleFrameMultiplier = 10000;
    int singleFrameTime = ((float)self.frameTime.value/frameNumber)*singleFrameMultiplier;
    
    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        while (YES){
            if (i >= frameNumber) {
                break;
            }
            if ([self.writerInput isReadyForMoreMediaData]) {
                
                CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:[[images objectAtIndex:i] CGImage]];
                
                if (sampleBuffer) {
                    if (i == 0) {
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                    }else{
                        CMTime frameTime = CMTimeMake(i * singleFrameTime, singleFrameMultiplier);
                        // NSLog(@"i: %d -> second: %f", i, CMTimeGetSeconds(frameTime));
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:frameTime];
                    }
                    CFRelease(sampleBuffer);
                    i++;
                }
            }
        }
        
        [self.writerInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(self.fileURL);
            });
        }];
        
        CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
    }];
}

- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4 * frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height
{
    
    if ((int)width % 16 != 0 ) {
        NSLog(@"Warning: video settings width must be divisible by 16.");
    }
    
    NSDictionary *videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : [NSNumber numberWithInt:(int)width],
                                    AVVideoHeightKey : [NSNumber numberWithInt:(int)height]};
    
    return videoSettings;
}

@end
