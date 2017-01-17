//
//  MainViewController.m
//  TestForPlayer
//
//  Created by wujian on 2017/1/11.
//  Copyright © 2017年 wujian. All rights reserved.
//

#import "MainViewController.h"
#import "WJCustomGifController.h"
#import "WJCustomPlayerLayerController.h"
#import "WJAVPlayerLayerController.h"

@interface MainViewController ()

@property (nonatomic, strong) UIButton *avplayerLayerButton;
@property (nonatomic, strong) UIButton *customPlayerButton;
@property (nonatomic, strong) UIButton *gifButton;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.avplayerLayerButton];
    [self.view addSubview:self.customPlayerButton];
    [self.view addSubview:self.gifButton];
    
    self.view.backgroundColor = [UIColor whiteColor];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ButtonEvent

- (void)gifButtonClicked:(id)sender
{
    WJCustomGifController *controller = [[WJCustomGifController alloc] init];
    [self.navigationController pushViewController:controller animated:true];

}

- (void)avplayerLayerButtonClicked:(id)sender
{
    WJAVPlayerLayerController *controller = [[WJAVPlayerLayerController alloc] init];
    [self.navigationController pushViewController:controller animated:true];
}

- (void)customPlayerButtonClicked:(id)sender
{
    WJCustomPlayerLayerController *controller = [[WJCustomPlayerLayerController alloc] init];
    [self.navigationController pushViewController:controller animated:true];
}


#pragma mark - Setter

- (UIButton *)gifButton
{
    if (!_gifButton) {
        _gifButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 100, 250, 40)];
        [_gifButton setTitle:@"customGif" forState:UIControlStateNormal];
        [_gifButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _gifButton.backgroundColor = [UIColor blueColor];
        [_gifButton addTarget:self action:@selector(gifButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _gifButton;
}

- (UIButton *)customPlayerButton
{
    if (!_customPlayerButton) {
        _customPlayerButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 250, 250, 40)];
        [_customPlayerButton setTitle:@"customPlayerButton" forState:UIControlStateNormal];
        [_customPlayerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _customPlayerButton.backgroundColor = [UIColor blueColor];
        [_customPlayerButton addTarget:self action:@selector(customPlayerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _customPlayerButton;
}


- (UIButton *)avplayerLayerButton
{
    if (!_avplayerLayerButton) {
        _avplayerLayerButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 400, 250, 40)];
        [_avplayerLayerButton setTitle:@"avplayerLayerButton" forState:UIControlStateNormal];
        [_avplayerLayerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _avplayerLayerButton.backgroundColor = [UIColor blueColor];
        [_avplayerLayerButton addTarget:self action:@selector(avplayerLayerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _avplayerLayerButton;
}

@end
