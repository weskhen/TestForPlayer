//
//  PlayerFlagSingleton.h
//  TestForPlayer
//
//  Created by wujian on 2017/1/16.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayerFlagSingleton : NSObject

+ (PlayerFlagSingleton *)shareInstance;

//customGif  table 是否正在滚动  default false
- (BOOL)customGifTableIsScrolling;

- (void)setCustomGifTableIsScroll:(BOOL)scrolling;


//customPlayerLayer  table 是否正在滚动  default false
- (BOOL)customPlayerLayerTableIsScrolling;

- (void)setCustomPlayerLayerTableIsScroll:(BOOL)scrolling;


//AVPlayerLayer  table 是否正在滚动  default false
- (BOOL)avPlayerLayerTableIsScrolling;

- (void)setAVPlayerLayerTableIsScroll:(BOOL)scrolling;

@end
