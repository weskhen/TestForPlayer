//
//  PlayerFlagSingleton.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/16.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "PlayerFlagSingleton.h"

@interface PlayerFlagSingleton ()

@property (nonatomic, assign) BOOL isGifTableScrolling; //table第一次进页面刷新状态没返回，默认没有在滚动
@property (nonatomic, assign) BOOL isCustomPlayerTableScrolling;
@property (nonatomic, assign) BOOL isAVPlayerTableScrolling;

@end
@implementation PlayerFlagSingleton

+ (PlayerFlagSingleton *)shareInstance
{
    static PlayerFlagSingleton *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PlayerFlagSingleton alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isGifTableScrolling = NO;
    }
    return self;
}

- (BOOL)customGifTableIsScrolling
{
    return self.isGifTableScrolling;
}

- (void)setCustomGifTableIsScroll:(BOOL)scrolling
{
    self.isGifTableScrolling = scrolling;
}

//customPlayerLayer  table 是否正在滚动  default false
- (BOOL)customPlayerLayerTableIsScrolling
{
    return self.isCustomPlayerTableScrolling;
}

- (void)setCustomPlayerLayerTableIsScroll:(BOOL)scrolling
{
    self.isCustomPlayerTableScrolling = scrolling;
}

//AVPlayerLayer  table 是否正在滚动  default false
- (BOOL)avPlayerLayerTableIsScrolling
{
    return self.isAVPlayerTableScrolling;
}

- (void)setAVPlayerLayerTableIsScroll:(BOOL)scrolling
{
    self.isAVPlayerTableScrolling = scrolling;
}

@end
