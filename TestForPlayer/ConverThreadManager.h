//
//  ConverThreadManager.h
//  TestForPlayer
//
//  Created by wujian on 2017/1/11.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConverThreadManager : NSObject

+ (instancetype)shareInstance;

//NSOperationQueue 控制并发比较简单 也可以用dispatch_semaphore_t 来控制
- (NSOperationQueue *)addOperationWithBlock:(void (^)(void))block;

- (NSOperationQueue *)addGifOperationWithBlock:(void (^)(void))block;

- (dispatch_queue_t)getVideoConverConcurrentQueue;
- (dispatch_queue_t)getVideoConverSerialQueue;

//使用NSThread是为了实现单条线程的队列    使当前滑动到的最新cell 能最快展示Gif更符合用户的需求
- (void)performTaskInVideoConverThread:(dispatch_block_t)block async:(BOOL)async;

- (void)addTask:(dispatch_block_t)block;
- (void)removeTask:(dispatch_block_t)block;

- (void)finishTask:(dispatch_block_t)task;

@end
