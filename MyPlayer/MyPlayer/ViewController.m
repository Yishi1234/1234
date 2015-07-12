//
//  ViewController.m
//  MyPlayer
//
//  Created by qianfeng on 15-6-23.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VedioView.h"

#define VIDEO_URL @"http://hot.vrs.sohu.com/ipad1407291_4596271359934_4618512.m3u8"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet VedioView *playerView;
@property (weak, nonatomic) IBOutlet UISlider *slider;

//使用AVPlayer进行视频播放
@property(nonatomic)AVPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    //设置滑块的最大值最小值以及当前值
    self.slider.maximumValue = 1.0;
    self.slider.minimumValue = 0.0;
    self.slider.value        = 0.0;
}

- (IBAction)playVideo:(id)sender {
    
    if (self.player != nil) {
        //对于播放状态的再次调用play没有影响
        [self.player play];
        return;
    }
    
    //播放本地资源的方式
    NSString *videoPath = [[NSBundle mainBundle]pathForResource:@"1" ofType:@"mp4"];
    NSURL *localURL = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *localAssert = [[AVURLAsset alloc]initWithURL:localURL options:nil];
    
    //播放网络资源的方式
    //AVURLAsset 代表一个播放的资源，可以是视频，也可以是音频
    AVURLAsset *assert = [[AVURLAsset alloc]initWithURL:[NSURL URLWithString:VIDEO_URL] options:nil];
    
    //AVPlayerItem 他是对assert对应资源的一种整体描述，包括能够播放，以及影片长度等内容
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithAsset:localAssert];
    
    //使用item生成player，这里会对影片进行预加载分析，然后更新item的状态
    self.player = [AVPlayer playerWithPlayerItem:item];
    
    //把AVPlayer和AVPlayerLayer进行关联
    [self.playerView setPlayer:self.player];
    
    //监听AVPlayerItem的status状态，当status状态为readyToPlayer时，我们认为影片时可以播放的
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem*)object;
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            //这里影片可以播放
            [self.player play];
            
            //AVPlayer提供了一个周期性调用block的方法，这里可以进行进度更新
            //CMTime 指定一个时间，value/timeScale可以得到秒数
            //CMTimeMake(1, 1) 间隔为1s
            __weak typeof(self)weakSelf = self;
            [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                //time是指当前影片播放的时间
                
                //得到影片的总时间
                CMTime totalTime = weakSelf.player.currentItem.duration;
                
                //CMTimeGetSeconds 把CMTime转换为秒数
                CGFloat currentTimeSeconds = CMTimeGetSeconds(time);
                CGFloat totalSeconds = CMTimeGetSeconds(totalTime);
                
                //更新进度
                weakSelf.slider.value = currentTimeSeconds*1.0/totalSeconds;
            }];
        }else{
            NSLog(@"影片不能播放");
        }
    }
}

- (IBAction)pauseVideo:(id)sender {
    [self.player pause];
}

- (IBAction)progessChanged:(id)sender {
    float progressValue = self.slider.value;
    CMTime totalTime = self.player.currentItem.duration;
    
    //seekToTime 实现影片的定位
    //CMTimeMultiplyByFloat64 让一个CMTime乘以float值，返回对应的CMTime
    [self.player seekToTime:CMTimeMultiplyByFloat64(totalTime, progressValue)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
