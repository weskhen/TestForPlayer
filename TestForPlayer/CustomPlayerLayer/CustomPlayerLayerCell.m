//
//  CustomPlayerLayerCell.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/13.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "CustomPlayerLayerCell.h"
#import "CustomPlayerReaderTool.h"
#import "PlayerConst.h"
#import "PlayerFlagSingleton.h"

@interface CustomPlayerLayerCell ()<CustomPlayerReaderToolDelegate>

@property (nonatomic, strong) CustomPlayerReaderTool *converTool;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (nonatomic, strong) UIImageView *videoImageView;

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, strong) UIImage *firstImage; //
@property (nonatomic, assign) int times;
@end
@implementation CustomPlayerLayerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self.contentView addSubview:self.videoImageView];
        
        _videoImageView.frame = CGRectMake(10, 5, 80, 60);
        _times = 3;
    }
    return self;
}

- (void)addVideoWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    NSString *fileName = [NSString stringWithFormat:@"test00%ld",indexPath.row%10];
    self.filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp4"];

    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkPlayingOrRemoveVideo) name:Notification_ScrollEnd object:nil];

    if (![[PlayerFlagSingleton shareInstance] customPlayerLayerTableIsScrolling]) {
        self.videoImageView.image = [UIImage imageNamed:@"ic_group_chat"];
        [self setCustomPlayerWithFilePath:self.filePath];
    }
    else{
        if (!_converTool) {
            self.videoImageView.image = [UIImage imageNamed:@"ic_group_chat"];
        }
    }

}

- (void)setCustomPlayerWithFilePath:(NSString *)filePath
{
    if (!_converTool) {
        _converTool = [[CustomPlayerReaderTool alloc]initWithVideoPath:filePath size:_videoImageView.frame.size];
        _converTool.delegate = self;
        _converTool.loop = YES;
    }
    [_converTool start];
}

- (void)dealloc
{

}

#pragma mark - Notification
- (void)checkPlayingOrRemoveVideo
{
    if ([self currentCellIsNotShowedInScreen]) {
        //cell没有显示在当前屏幕
        if (!_firstImage) {
            _videoImageView.layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"ic_group_chat"].CGImage);
        }
        else
        {
            _videoImageView.layer.contents = (__bridge id _Nullable)_firstImage.CGImage;
        }
        if (_converTool) {
            [_converTool stop];
        }
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_converTool && [_converTool isRunning]) {
                
            }
            else
            {
                [self setCustomPlayerWithFilePath:self.filePath];
            }
            
        });
    }
    
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
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - CustomPlayerReaderToolDelegate
- (void)converVideoProcess:(CGImageRef)imageRef
{
    if (_times != 0) {
        _times--;
    }
    if (_times == 0) {
        if (!_firstImage) {
            _firstImage = [UIImage imageWithCGImage:imageRef];
        }
    }
    self.videoImageView.layer.contents = (__bridge id)(imageRef);
}

- (void)converFailed:(NSError *)error
{
    NSLog(@"CustomPlayerLayerCell:::errorCode:%ld",error.code);
}

- (void)converFinished:(NSTimeInterval)duration
{
    
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
