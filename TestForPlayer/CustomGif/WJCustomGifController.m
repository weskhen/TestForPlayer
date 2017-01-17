//
//  WJCustomGifController.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/14.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "WJCustomGifController.h"
#import "CustiomGifImageCell.h"
#import "PlayerConst.h"
#import "PlayerFlagSingleton.h"

@interface WJCustomGifController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation WJCustomGifController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dataArray = [NSMutableArray new];
    
    for (int i = 0; i < 100; i ++) {
        [_dataArray addObject:@(i)];
    }
    [self.view addSubview:self.table];
    _table.delegate = self;
    _table.dataSource = self;
//    [_table reloadData];
    [_table setContentOffset:CGPointMake(0, 0.01)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _table.frame = self.view.bounds;
}

- (void)dealloc
{
    [[PlayerFlagSingleton shareInstance] setCustomGifTableIsScroll:false];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = [NSString stringWithFormat:@"%@_%ld",NSStringFromSelector(_cmd),indexPath.row];
    CustiomGifImageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[CustiomGifImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [cell addVideoWithIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
    
}

#pragma mark -scrollViewDelegate
// 触摸屏幕并拖拽画面，再松开，最后停止时，触发该函数
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        //滚动停止
        [[PlayerFlagSingleton shareInstance] setCustomGifTableIsScroll:false];
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_ScrollEnd object:nil];
    }
    //    NSLog(@"scrollViewDidEndDragging  -  End of Scrolling. %d",decelerate);
}
// 滚动停止时，触发该函数
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //    NSLog(@"scrollViewDidEndDecelerating  -   End of Scrolling.");
    [[PlayerFlagSingleton shareInstance] setCustomGifTableIsScroll:false];
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_ScrollEnd object:nil];
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[PlayerFlagSingleton shareInstance] setCustomGifTableIsScroll:true];
}

#pragma mark - setter
- (UITableView *)table
{
    if (!_table) {
        _table = [UITableView new];
        _table.backgroundColor = [UIColor whiteColor];
    }
    return _table;
}
@end
