//
//  AVPlayerLayerCell.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/13.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "AVPlayerLayerCell.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayerConst.h"
#import "PlayerFlagSingleton.h"

typedef enum : NSUInteger {
    AVPlayerLayerCellType_None,
    AVPlayerLayerCellType_Success,
    AVPlayerLayerCellType_Fail,
} AVPlayerLayerCellType;

@interface AVPlayerLayerCell ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIImageView *videoImageView;

@property (nonatomic, assign) AVPlayerLayerCellType videoReadyType;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (nonatomic, strong) NSString *filePath;
@end
@implementation AVPlayerLayerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self.contentView addSubview:self.videoImageView];
        _videoImageView.frame = CGRectMake(10, 5, 40, 30);
        
    }
    return self;
}

- (void)dealloc
{
    [self releaseResource];
}

- (void)addVideoWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    NSString *fileName = [NSString stringWithFormat:@"test00%ld",indexPath.row%10];
    self.filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp4"];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_ScrollEnd object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkPlayingOrRemoveVideo) name:Notification_ScrollEnd object:nil];
    
    self.videoImageView.image = [UIImage imageNamed:@"ic_group_chat"];
    if (![[PlayerFlagSingleton shareInstance] avPlayerLayerTableIsScrolling]) {
        [self setPlayerViewWithVideoFilePath:self.filePath];
    }

}

- (void)setPlayerViewWithVideoFilePath:(NSString *)filePath {
    if (self.playerItem) {
        return;
    }
    self.videoReadyType = AVPlayerLayerCellType_None;
    AVPlayerItem *item  = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:filePath]];
    self.playerItem = item;
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.player.muted = YES;//设置mute
    self.playerLayer.frame = _videoImageView.frame;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:self.playerLayer];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        __weak typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                object:nil
                                 queue:nil
                            usingBlock:^(NSNotification *note) {
                                [weakSelf.player seekToTime:kCMTimeZero];
                                [weakSelf.player play];
                            }];
        
    });
}

//cell 不在可视区域内 可以暂停播放 释放资源
- (BOOL)currentCellIsNotShowedInScreen
{
    UITableView *table;
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UITableView class]]) {
            table = (UITableView *)nextResponder;
            break;
        }
    }
    if (table) {
        CGRect cellR = [table rectForRowAtIndexPath:self.currentIndexPath];
        
        if ((table.contentOffset.y + table.frame.size.height) < CGRectGetMinY(cellR) || table.contentOffset.y > CGRectGetMaxY(cellR)) {
            return true;
        }
        
        
    }
    return false;
}

- (void)stopPlayVideo
{
    [self releaseResource];
    _videoReadyType = AVPlayerLayerCellType_None;
}

- (void)releaseResource
{
    if (_playerItem) {
        [_player pause];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        _playerItem = nil;
        [_player replaceCurrentItemWithPlayerItem:nil];
        _player = nil;
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
        _videoImageView.hidden = NO;
    }
}

#pragma mark - Notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//    NSLog(@"keyPath:%@,object:%@",keyPath,NSStringFromClass([object class]));
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        if (playerItem.status==AVPlayerStatusReadyToPlay) {
            //视频加载完成
            NSLog(@"加载完成");
            [self.player play];
            _videoImageView.hidden = YES;
            self.videoReadyType = AVPlayerLayerCellType_Success;
        }else if (playerItem.status == AVPlayerStatusFailed){
            NSLog(@"加载失败");
            self.videoReadyType = AVPlayerLayerCellType_Fail;
            [self releaseResource];
        }
    }
}


- (void)checkPlayingOrRemoveVideo
{
    if ([self currentCellIsNotShowedInScreen]) {
        [self stopPlayVideo];
    }
    else
    {
        if (self.videoReadyType == AVPlayerLayerCellType_Fail || self.videoReadyType == AVPlayerLayerCellType_None) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setPlayerViewWithVideoFilePath:self.filePath];
                
            });
        }
    }
    
}

#pragma mark - setter/getter
- (UIImageView *)videoImageView
{
    if (!_videoImageView) {
        _videoImageView = [[UIImageView alloc] init];
    }
    return _videoImageView;
}


@end
