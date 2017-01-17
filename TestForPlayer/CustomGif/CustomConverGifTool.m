//
//  CustomConverGifTool.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/14.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "CustomConverGifTool.h"
#import "ConverThreadManager.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface CustomConverGifTool ()

@property (nonatomic, assign) CGSize videoSize; //展示视频的尺寸

@property (nonatomic, copy) customConverGifFail failBlock;
@property (nonatomic, copy) customConverGifFinished finishBlock;

@property (nonatomic, strong) dispatch_block_t task;
@end
@implementation CustomConverGifTool

- (void)dealloc
{
    
}

#pragma mark - setter/getter
- (void)setCurrentVideoSize:(CGSize)videoSize
{
    self.videoSize = videoSize;
}

//转成UIImage 再制作成gif
- (void)convertVideoUIImagesWithURL:(NSURL *)url
                             gifUrl:(NSURL *)gifUrl
                 finishSuccessBlock:(customConverGifFinished)finishBlock
                          failBlock:(customConverGifFail)failBlock  {
    self.finishBlock = finishBlock;
    self.failBlock = failBlock;
    
    __weak typeof(self)weakSelf = self;
    
    self.task = ^(){
        AVAsset *asset = [AVAsset assetWithURL:url];
        NSError *error = nil;
        AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            if (weakSelf.failBlock) {
                weakSelf.failBlock(error);
            }
            return ;
        }
        
        NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack =[videoTracks firstObject];
        if (!videoTrack) {
            if (failBlock) {
                error = [NSError errorWithDomain:@"custom error Code" code:1000 userInfo:nil]; //custom error Code
                failBlock(error);
            }
            return ;
        }
        //     视频播放时，  kCVPixelFormatType_32BGRA;
        // 其他用途，如视频压缩 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        NSDictionary *options = @{
                                  (id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
                                  (id)kCVPixelBufferWidthKey:@(weakSelf.videoSize.width),
                                  (id)kCVPixelBufferHeightKey:@(weakSelf.videoSize.height),
                                  };
        
        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
        if ([reader canAddOutput:videoReaderOutput]) {
            [reader addOutput:videoReaderOutput];
        }
        //开始解码
        [reader startReading];
        
        NSMutableArray *images = [NSMutableArray array];
        
        // 要确保nominalFrameRate>0，之前出现过android拍的0帧视频
        while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
            @autoreleasepool {
                // 读取 video sample
                CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
                
                if (!videoBuffer) {
                    break;
                }
                
                UIImage *temImage = [weakSelf convertSampleBufferRefToUIImage:videoBuffer];
                if (temImage) {
                    [images addObject:temImage];
                }
                CMSampleBufferInvalidate(videoBuffer);
                CFRelease(videoBuffer);
                
                if (reader.status == AVAssetReaderStatusCompleted) {
                    break;
                }
                
            }
        }
        
        if (images.count == 0) {
            NSLog(@"images error count");
        }
        
        dispatch_async( [[ConverThreadManager shareInstance] getVideoConverSerialQueue], ^{
            //转化成gif
            NSString *documetPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
            
            NSURL *temGifUrl = [NSURL fileURLWithPath:[documetPath stringByAppendingPathComponent:[NSString stringWithFormat:@"tem_%ld",random()]]];
            makeAnimatedGif(images, temGifUrl, duration);
            NSError *error;
            [[NSFileManager defaultManager] copyItemAtURL:temGifUrl toURL:gifUrl error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error.code == 0) {
                    if (weakSelf.finishBlock) {
                        weakSelf.finishBlock(duration);
                    }
                }
                else{
                    if (weakSelf.failBlock) {
                        weakSelf.failBlock(error);
                    }
                }

            });
        });
        [[ConverThreadManager shareInstance] finishTask:weakSelf.task];
    };
    
    [[ConverThreadManager shareInstance] addTask:self.task];

}

static void makeAnimatedGif(NSArray *images, NSURL *gifURL, NSTimeInterval duration) {
    NSTimeInterval perSecond = duration /images.count;
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @(perSecond), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (UIImage *image in images) {
        @autoreleasepool {
            
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }else{
        
        
    }
    CFRelease(destination);
    
}

- (UIImage *)convertSampleBufferRefToUIImage:(CMSampleBufferRef)sampleBufferRef
{
    @autoreleasepool {
        
        CGImageRef cgImage = [self convertSamepleBufferRefToCGImage:sampleBufferRef];
        UIImage *image;
        //    image = [UIImage imageWithCGImage:cgImage];
        //    CGImageRelease(cgImage);
        
        CGFloat height = CGImageGetHeight(cgImage);
        CGFloat width = CGImageGetWidth(cgImage);
        
        height = height / 5;
        width = width / 5;
        //        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
        
#define UseUIImage 0
#if UseUIImage
        
        [image drawInRect:CGRectMake(0, 0, width, height)];
#else
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
        
        
        
#endif
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGImageRelease(cgImage);
        
        //        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        UIGraphicsEndImageContext();
        return image;
    }
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



- (void)removeGifTask
{
    if (_task) {
        [[ConverThreadManager shareInstance] removeTask:_task];
    }
}
@end
