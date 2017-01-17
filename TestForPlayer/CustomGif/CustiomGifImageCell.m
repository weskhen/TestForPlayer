//
//  CustiomGifImageCell.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/14.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "CustiomGifImageCell.h"
#import "CustomConverGifTool.h"
#import "UIImageView+PlayGIF.h"
#import "PlayerConst.h"
#import "PlayerFlagSingleton.h"

@interface CustiomGifImageCell ()

@property (nonatomic, strong) CustomConverGifTool *converTool;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (nonatomic, strong) UIImageView *videoImageView;

@property (nonatomic, strong) NSString *gifPath;
@end

@implementation CustiomGifImageCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self.contentView addSubview:self.videoImageView];
        
        _videoImageView.frame = CGRectMake(10, 5, 80, 60);
        
    }
    return self;
}

- (void)addVideoWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    NSString *fileName = [NSString stringWithFormat:@"test00%ld",indexPath.row%10];
    NSString *documetPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.gifPath = [documetPath stringByAppendingPathComponent:fileName];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkPlayingOrRemoveVideo) name:Notification_ScrollEnd object:nil];
    _videoImageView.image = [UIImage imageNamed:@"ic_group_chat"];
    
    if (![[PlayerFlagSingleton shareInstance] customGifTableIsScrolling]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.gifPath]) {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp4"];
            [self setGifImagesWithVideoPath:filePath andGifUrl:self.gifPath];
        }
        else
        {
            _videoImageView.gifPath = self.gifPath;
            [_videoImageView startGIF];
        }
    }
}

- (void)setGifImagesWithVideoPath:(NSString *)filePath andGifUrl:(NSString *)gifUrl
{    
    
    __weak __typeof(self) weakSelf = self;
    if (_converTool == nil) {
        self.converTool = [CustomConverGifTool new];
        [_converTool setCurrentVideoSize:CGSizeMake(160, 120)];
    }
    else
    {
        [_converTool removeGifTask];
    }
    [_converTool convertVideoUIImagesWithURL:[NSURL fileURLWithPath:filePath] gifUrl:[NSURL fileURLWithPath:gifUrl] finishSuccessBlock:^(NSTimeInterval duration) {
        weakSelf.videoImageView.gifPath = gifUrl;
        [weakSelf.videoImageView startGIF];
        
    } failBlock:^(NSError *error) {
        
    }];
}

#pragma mark - Notification
- (void)checkPlayingOrRemoveVideo
{
    if ([self currentCellIsNotShowedInScreen]) {

    }
    else
    {
        __weak __typeof(self) weakSelf = self;
        //for gif
        if (![[NSFileManager defaultManager] fileExistsAtPath:weakSelf.gifPath]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *fileName = [NSString stringWithFormat:@"test00%ld",weakSelf.currentIndexPath.row%10];
                NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp4"];
                [weakSelf setGifImagesWithVideoPath:filePath andGifUrl:weakSelf.gifPath];
            });
        }
        else
        {
            if (![weakSelf.videoImageView isGIFPlaying]) {
                weakSelf.videoImageView.gifPath = weakSelf.gifPath;
                [weakSelf.videoImageView startGIF];
            }
        }

    }
    
}

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
            //cell 不在可视区域内 可以暂停播放 释放资源
            return true;
        }
        
        
    }
    return false;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - setter/getter
- (UIImageView *)videoImageView
{
    if (!_videoImageView) {
        _videoImageView = [[UIImageView alloc] init];
        _videoImageView.backgroundColor = [UIColor grayColor];
    }
    return _videoImageView;
}

@end
