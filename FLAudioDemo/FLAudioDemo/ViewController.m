//
//  ViewController.m
//  FLAudioDemo
//
//  Created by clarence on 17/1/12.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "ViewController.h"
#import "FLAudioServices.h"
#import "FLSlider.h"
@interface ViewController ()<FLAudioPlayerDelegate,FLSliderDelegate,FLAudioRecorderDelegate>
@property (weak, nonatomic) IBOutlet UILabel *totalUrlCount;
@property (weak, nonatomic) IBOutlet UILabel *recordSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *playTip;
@property (weak, nonatomic) IBOutlet UILabel *recordTip;
@property (nonatomic,strong)FLAudioRecorder *recoder;
@property (weak, nonatomic) IBOutlet FLSlider *fl_slider;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet UISwitch *recordSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *playSwitch;
@property (strong, nonatomic) FLAudioPlayer *player;//播放器对象
@end

@implementation ViewController{
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint prevLocation = [touch previousLocationInView:self.view];
    if (location.y < prevLocation.y) {
        // 划上
        self.player.currentVolum += (prevLocation.y - location.y) / prevLocation.y;
    }
    else{
        self.player.currentVolum -= (location.y - prevLocation.y) / location.y;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"gitKong";
    
    self.navigationItem.rightBarButtonItem=  [[UIBarButtonItem alloc] initWithTitle:@"reset" style:UIBarButtonItemStyleDone target:self action:@selector(reset)];
    
    self.recoder = [[FLAudioRecorder alloc] init];
    [self.recoder fl_prepare];
    self.recoder.delegate = self;
    self.recoder.endTime = 3.33;
    self.fl_slider.backgroundColor = [UIColor lightGrayColor];
    self.fl_slider.delegate = self;
}

- (void)reset{
    self.fl_slider.value = 0;
    self.fl_slider.cacheValue = 0;
    self.startLabel.text = @"00:00";
    self.endLabel.text = @"00:00";
    self.recordSecondLabel.text = @"00:00";
    self.recordTip.text = @"录音";
    self.playTip.text = @"播放";
    self.recordSwitch.on = NO;
    self.playSwitch.on = NO;
    [self.recoder fl_stop:nil];
    [self.player fl_stop];
}

- (IBAction)clickToRecord:(id)sender {
    if (self.recordSwitch.on) {
        [self.recoder fl_start];
        self.recordTip.text = @"正在录音...";
    }
    else{
        [self.recoder fl_pause];
//        [self.recoder fl_stop:nil];
    }
}

- (IBAction)clickToPlay:(id)sender {
    if (self.playSwitch.on) {
        [self.player fl_start];
        self.playTip.text = @"正在播放...";
        self.startLabel.text = FL_COVERTTIME(self.player.currentTime.doubleValue);
        self.endLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue);
    }
    else{
        [self.player fl_pause];
        self.playTip.text = @"播放";
    }
}
- (IBAction)addNewPlayUrl:(id)sender {
//    NSString *str = @"hTtp://ws.stream.qqmusic.qq.com/M500001VfvsJ21xFqb.mp3?guid=ffffffff82def4af4b12b3cd9337d5e7&uin=346897220&vkey=6292F51E1E384E061FF02C31F716658E5C81F5594D561F2E88B854E81CAAB7806D5E4F103E55D33C16F3FAC506D1AB172DE8600B37E43FAD&fromtag=46";
    NSString *str = [[NSBundle mainBundle] pathForResource:@"Thank You" ofType:@"mp3"];
    NSString *str1 = [[NSBundle mainBundle] pathForResource:@"MP3Sample" ofType:@"mp3"];
    if (!self.player) {
        NSLog(@"还没创建播放器呢，别着急...");
        return;
    }
    [self.player fl_addUrl:@[str,str1]];
    
    self.totalUrlCount.text = [NSString stringWithFormat:@"总剩下地址数：%zd",self.player.lastTotalItemsCount];
}
- (IBAction)previous:(id)sender {
    if (!self.player) {
        return;
    }
    [self.player fl_moveToPrevious];
    self.totalUrlCount.text = [NSString stringWithFormat:@"总剩下地址数：%zd",self.player.lastTotalItemsCount];
}
- (IBAction)next:(id)sender {
    if (!self.player) {
        return;
    }
    [self.player fl_moveToNext];
    self.totalUrlCount.text = [NSString stringWithFormat:@"总剩下地址数：%zd",self.player.lastTotalItemsCount];
}

#pragma mark - audio recorder delegate

- (void)fl_audioRecorder:(FLAudioRecorder *)recorder beginRecordingToUrl:(NSString *)url{
    NSLog(@"开始录音,url = %@",url);
}

- (void)fl_audioRecorder:(FLAudioRecorder *)recorder recordingWithCurrentTime:(NSNumber *)currentTime{
//    NSLog(@"currentTime = %@",currentTime);
    self.recordSecondLabel.text = [NSString stringWithFormat:@"%@ s",currentTime];
}

- (void)fl_audioRecorder:(FLAudioRecorder *)recorder finishRecordingWithTotalTime:(NSNumber *)totalTime toUrl:(NSString *)url{
    NSLog(@"结束录音,totalTime = %@",totalTime);
    self.recordSwitch.on = NO;
    self.recordTip.text = @"录音";
    
     NSString *str = @"hTtp://ws.stream.qqmusic.qq.com/M500001VfvsJ21xFqb.mp3?guid=ffffffff82def4af4b12b3cd9337d5e7&uin=346897220&vkey=6292F51E1E384E061FF02C31F716658E5C81F5594D561F2E88B854E81CAAB7806D5E4F103E55D33C16F3FAC506D1AB172DE8600B37E43FAD&fromtag=46";
    self.player = [[FLAudioPlayer alloc] initWithUrl:@[url,str]];
    self.player.delegate = self;
    self.startLabel.text = FL_COVERTTIME(self.player.currentTime.doubleValue);
    self.endLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue);
    self.totalUrlCount.text = [NSString stringWithFormat:@"总剩下地址数：%zd",self.player.lastTotalItemsCount];
}

- (void)fl_audioRecorder:(FLAudioRecorder *)recorder didFailureWithError:(NSError *)error{
    NSLog(@"录音失败,error = %@",error.localizedDescription);
}

#pragma mark - audio player delegate

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer beginPlaying:(NSString *)currentUrl withTotalTime:(NSNumber *)totalTime{
    NSLog(@"currentUrl = %@",currentUrl);
    self.endLabel.text = FL_COVERTTIME(totalTime.doubleValue);
}

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer playingToCurrentProgress:(NSNumber *)progress withBufferProgress:(NSNumber *)bufferProgress{
    self.fl_slider.value = progress.floatValue;
    self.startLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue * progress.doubleValue);
}

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer cacheToCurrentBufferProgress:(NSNumber *)bufferProgress{
    NSLog(@"bufferProgress = %.2lf",bufferProgress.floatValue);
    self.fl_slider.cacheValue = bufferProgress.floatValue;
}

/*
 *  BY gitKong
 *
 *  模拟下一个播放的个数
 */
static int playMaxCount = 1;

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFinishAndPlayNext:(NSString *__autoreleasing *)nextUrl{
    
    NSString *str = @"hTtp://ws.stream.qqmusic.qq.com/M500001VfvsJ21xFqb.mp3?guid=ffffffff82def4af4b12b3cd9337d5e7&uin=346897220&vkey=6292F51E1E384E061FF02C31F716658E5C81F5594D561F2E88B854E81CAAB7806D5E4F103E55D33C16F3FAC506D1AB172DE8600B37E43FAD&fromtag=46";
    if (playMaxCount == 0) {
        *nextUrl = nil;
        self.playTip.text = @"播放";
        self.playSwitch.on = NO;
    }
    else{
        playMaxCount--;
        *nextUrl = str;
    }
}

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFinishWithFlag:(NSNumber *)isFinishAll{
    self.totalUrlCount.text = [NSString stringWithFormat:@"总剩下地址数：%zd",self.player.lastTotalItemsCount];
    if (isFinishAll.boolValue) {
        self.playTip.text = @"播放";
        self.playSwitch.on = NO;
    }
}

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFailureWithError:(NSError *)error{
//    self.playTip.text = @"播放";
//    self.playSwitch.on = NO;
    if (error.code == 1000) {
        // 耳机拔出，会自动暂停
    }
    else if (error.code == 1003){
        // app 进入后台，应该暂停
//        [audioPlayer fl_pause:nil];
    }
    else if (error.code == 1004){
        NSLog(@"error.description = %@",error.description);
    }
    else{
        // 其他错误应该stop
        
        [audioPlayer fl_stop];
    }
    
    NSLog(@"error : %@",error.localizedDescription);
}


#pragma mark - slider delegate

- (void)beginSlide:(FLSliderButton *)sliderBtn slider:(FLSlider *)slider{
    self.startLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue * slider.value);
}

- (void)sliding:(FLSliderButton *)sliderBtn slider:(FLSlider *)slider{
    self.startLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue * slider.value);
}

- (void)endSlide:(FLSliderButton *)sliderBtn slider:(FLSlider *)slider{
    __weak typeof(self) weakSelf = self;
    [self.player fl_seekToProgress:slider.value complete:^(BOOL finished) {
        typeof(self) strongSelf = weakSelf;
        NSLog(@"seek finish");
        strongSelf.playTip.text = @"正在播放";
        strongSelf.playSwitch.on = YES;
    }];
}

@end
