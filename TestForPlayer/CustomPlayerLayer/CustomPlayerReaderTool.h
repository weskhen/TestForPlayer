//
//  CustomPlayerReaderTool.h
//  TestForPlayer
//
//  Created by wujian on 2017/1/14.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@protocol CustomPlayerReaderToolDelegate <NSObject>

@required
- (void)converVideoProcess:(CGImageRef )imageRef;

- (void)converFinished:(NSTimeInterval )duration;

- (void)converFailed:(NSError *)error;

@end
@interface CustomPlayerReaderTool : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning, isFinished;
@property (nonatomic, assign) BOOL loop;

@property (nonatomic, weak) id<CustomPlayerReaderToolDelegate> delegate;

//- (void)setCurrentVideoSize:(CGSize)videoSize;
//
//- (void)convertVideoCGImageRefWithURL:(NSURL *)url;

//- (BOOL)currenIsInPlaying;
//- (void)stopPlayerReading;


- (instancetype)initWithVideoPath:(NSString *)videoPath size:(CGSize)size;

- (void)start;

- (void)pause;

- (void)stop;

@end
