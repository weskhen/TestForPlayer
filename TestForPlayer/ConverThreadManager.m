//
//  ConverThreadManager.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/11.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "ConverThreadManager.h"
#import "BBWeakTimerTarget.h"

@interface ConverThreadManager ()

@property (nonatomic, strong) NSOperationQueue *generateQueue;
@property (nonatomic, strong) NSOperationQueue *generateGifQueue;

@property (nonatomic, strong) dispatch_queue_t concurrenceQueue;
@property (nonatomic, strong) dispatch_queue_t serialQueue;


@property (nonatomic, strong) NSThread*       videoConverThread;
@property (nonatomic, assign)   BOOL  keepAlive;
@property (nonatomic, strong) NSTimer *taskTimer;
@property (nonatomic, strong) NSMutableArray *taskArray;
@end

@implementation ConverThreadManager

+ (ConverThreadManager *)shareInstance
{
    static ConverThreadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ConverThreadManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _generateQueue = [[NSOperationQueue alloc] init];
        _generateQueue.maxConcurrentOperationCount = 1; //控制并发量 不同手机性能不一样
        _generateQueue.name = @"com.wesk.VideoConcurrentConvert01";
        
        _generateGifQueue = [[NSOperationQueue alloc] init];
        _generateGifQueue.maxConcurrentOperationCount = 3; //控制并发量 不同手机性能不一样
        _generateGifQueue.name = @"com.wesk.VideoConcurrentConvertgif";

        
        _concurrenceQueue = dispatch_queue_create("com.wesk.VideoConcurrentConvert02", DISPATCH_QUEUE_CONCURRENT);
        _serialQueue = dispatch_queue_create("com.wesk.VideoSerialConvert", DISPATCH_QUEUE_SERIAL);
        
        self.taskArray = [[NSMutableArray alloc] init];
//        [self startTaskTimer];

    }
    return self;
}

- (NSOperation *)addOperationWithBlock:(void (^)(void))block
{
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        block();
    }];
    [_generateQueue addOperation:operation];
    
    return operation;
}

- (NSOperation *)addGifOperationWithBlock:(void (^)(void))block
{
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        block();
    }];
    [_generateGifQueue addOperation:operation];
    
    return operation;
}

- (dispatch_queue_t)getVideoConverConcurrentQueue
{
    return _concurrenceQueue;
}

- (dispatch_queue_t)getVideoConverSerialQueue
{
    return _serialQueue;
}


- (void)performTaskInVideoConverThread:(dispatch_block_t)block async:(BOOL)async
{
    NSThread* converThread = [self getConverThread];
    
    if ([NSThread currentThread] == converThread) {
        block();
    }
    else
    {
        if (async) {
            [self performSelector:@selector(performBlock:) onThread:converThread withObject:block waitUntilDone:false];
        }
        else
        {
            [self performSelector:@selector(performBlock:) onThread:converThread withObject:block waitUntilDone:true];
        }
    }
}

- (void)performBlock:(dispatch_block_t)block
{
    block();
}

- (NSThread*)getConverThread
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.keepAlive = true;
        _videoConverThread = [[NSThread alloc] initWithTarget:self selector:@selector(dbThreadMain:) object:nil];
        [_videoConverThread setName:@"###coco db thread###"];
        [_videoConverThread start];
    });
    return _videoConverThread;
}

- (void)dbThreadMain:(id)data {
    @autoreleasepool {
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        
        while (self.keepAlive) {
            [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            //            CCLog(@"##############################db thread entered##############################");
        }
    }
}

- (void)addTask:(dispatch_block_t)block
{
    @synchronized (self.taskArray) {
        NSInteger lastCount = self.taskArray.count;
        NSUInteger blockIndex = [self.taskArray indexOfObject:block];
        if (blockIndex < self.taskArray.count ) {
            [self.taskArray exchangeObjectAtIndex:blockIndex withObjectAtIndex:0];
        }
        else
        {
            [self.taskArray insertObject:block atIndex:0];
        }
        if (lastCount == 0) {
            [self startTask];
        }
    }
    
}

- (void)removeTask:(dispatch_block_t)block
{
    @synchronized (self.taskArray) {
        [self.taskArray removeObject:block];
    }
}

- (void)startTaskTimer
{
    if (_taskTimer)
    {
        if (_taskTimer.isValid) {
            [_taskTimer invalidate];
        }
    }
    _taskTimer = nil;
    
//    _taskTimer = [BBWeakTimerTarget scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(startNextTask) userInfo:nil repeats:true];
}

- (void)cancelTaskTimer
{
    
}

- (void)finishTask:(dispatch_block_t)task
{
    [self removeTask:task];
    [self startTask];
}

- (void)startTask
{
    @synchronized (self.taskArray) {
        if (self.taskArray.count > 0) {
            dispatch_block_t block = [self.taskArray firstObject];
            [self performTaskInVideoConverThread:block async:YES];
            
        }
    }
}
@end
