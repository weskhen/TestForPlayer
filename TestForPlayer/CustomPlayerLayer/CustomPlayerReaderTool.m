//
//  CustomPlayerReaderTool.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/14.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "CustomPlayerReaderTool.h"
#import "ConverThreadManager.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BBWeakTimerTarget.h"

@interface CustomPlayerReaderTool ()

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) double frameRate;
@property (nonatomic, assign) double currentTime;

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderOutput;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation CustomPlayerReaderTool

#pragma mark - Initialization

- (instancetype)initWithVideoPath:(NSString *)videoPath size:(CGSize)size {
    self = [super init];
    if (self) {
        _size = size;
        _lock = [[NSRecursiveLock alloc] init];
        
        NSDictionary *opts = @{
                               AVURLAssetPreferPreciseDurationAndTimingKey : @YES
                               };
        _asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath] options:opts];
        _frameRate = 30;
    }
    return self;
}

- (void)dealloc {
//    [_lock lock];
//    [_timer invalidate];
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
//    [_lock unlock];
}



#pragma mark - Public

- (void)start {
    [self.lock lock];
    
    if( [self isRunning] ){
        [self.lock unlock];
        return;
    }
    [self preprocessForDecoding];
    //定时器按照帧率获取
    _timer = [BBWeakTimerTarget scheduledTimerWithTimeInterval:(1.0/self.frameRate) target:self selector:@selector(captureLoop) userInfo:nil repeats:YES];
    
    [self.lock unlock];
}

- (void)pause {
    [self.lock lock];
    
    if( ![self isRunning] ){
        [self.lock unlock];
        return;
    }
    [self.timer invalidate];
    self.timer = nil;
    [self processForPausing];
    
    [self.lock unlock];
}

- (void)stop {
    [self.lock lock];
    [self releaseResource];
    [self.lock unlock];
}



#pragma mark - Private

- (BOOL)isRunning {
    return [self.timer isValid]? YES : NO;
}

- (void)preprocessForDecoding {
    [self initReader];
}

- (void)postprocessForDecoding {
    [self releaseReader];
}


- (void)releaseResource
{
    self.currentTime  = 0;
    [self.timer invalidate];
    self.timer = nil;
    [self postprocessForDecoding];
}

- (void)captureLoop {
    dispatch_async([[ConverThreadManager shareInstance] getVideoConverConcurrentQueue], ^{
        [self captureNext];
    });
}

- (void)captureNext {
    [self.lock lock];
    
    [self processForDecoding];
    
    [self.lock unlock];
}

- (void)processForDecoding {
    if( self.assetReader.status != AVAssetReaderStatusReading ){
        if(self.assetReader.status == AVAssetReaderStatusCompleted ){
            NSTimeInterval duration = CMTimeGetSeconds(_asset.duration);
            if(!self.loop ){
                [self releaseResource];
                return;
            } else {
                self.currentTime = 0;
                [self initReader];
                
                __weak __typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(converFinished:)]) {
                        [weakSelf.delegate converFinished:duration];
                    }
                });
            }
            
      
        }
    }
//    else
    {
        CMSampleBufferRef sampleBuffer = [self.assetReaderOutput copyNextSampleBuffer];
        if(!sampleBuffer ){
            return;
        }
        self.currentTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
        CGImageRef cgImage = [self convertSamepleBufferRefToCGImage:sampleBuffer];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(converVideoProcess:)]) {
                [self.delegate converVideoProcess:cgImage];
            }
            CFRelease(cgImage);
        });
        CMSampleBufferInvalidate(sampleBuffer);
        CFRelease(sampleBuffer);
    }
}

- (void)processForPausing {
    
}

- (BOOL)isFinished {
    return (self.assetReader.status == AVAssetReaderStatusCompleted) ? YES : NO;
}

- (void)releaseReader {
    self.assetReader = nil;
    self.assetReaderOutput = nil;
}

- (void)initReader {
    AVAssetTrack *track = [[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    NSDictionary *setting = @{
                              (id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
                              (id)kCVPixelBufferWidthKey:@(self.size.width),
                              (id)kCVPixelBufferHeightKey:@(self.size.height),
                              };
    self.assetReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:setting];
    self.frameRate = @(track.nominalFrameRate).doubleValue;
    
    NSError *error;
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
    if (error.code != 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(converFailed:)]) {
            [self.delegate converFailed:error];
        }
        return;
    }
    
    if ([self.assetReader canAddOutput:self.assetReaderOutput]) {
        [self.assetReader addOutput:self.assetReaderOutput];
    }
    
    CMTime tm = CMTimeMake((int64_t)(self.currentTime*self.frameRate), self.frameRate);
    [self.assetReader setTimeRange:CMTimeRangeMake(tm,self.asset.duration)];
    
    [self.assetReader startReading];
}

//https://developer.apple.com/library/content/qa/qa1702/_index.html
- (CGImageRef)convertSamepleBufferRefToCGImage:(CMSampleBufferRef)sampleBufferRef
{
    @autoreleasepool {
        
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        // Get the number of bytes per row for the pixel buffer
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        
        // Get the number of bytes per row for the pixel buffer
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        // Get the pixel buffer width and height
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        // Create a device-dependent RGB color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                     bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        // Create a Quartz image from the pixel data in the bitmap graphics context
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        // Free up the context and color space
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        return quartzImage;
    }

}
@end
