//
//  CustomConverGifTool.h
//  TestForPlayer
//
//  Created by wujian on 2017/1/14.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef void (^customConverGifFail)(NSError *error);
typedef void (^customConverGifFinished)(NSTimeInterval duration);

@interface CustomConverGifTool : NSObject

- (void)setCurrentVideoSize:(CGSize)videoSize;

- (void)convertVideoUIImagesWithURL:(NSURL *)url
                             gifUrl:(NSURL *)gifUrl
                 finishSuccessBlock:(customConverGifFinished)finishBlock
                          failBlock:(customConverGifFail)failBlock;

- (void)removeGifTask;

@end
