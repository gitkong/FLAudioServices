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
    self.recoder.endTime = 10.33;
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
    [self.player fl_stop:nil];
}

- (IBAction)clickToRecord:(id)sender {
    __weak typeof(self) weakSelf = self;
    if (self.recordSwitch.on) {
        [self.recoder fl_start:^{
            NSLog(@"start");
            typeof(self) strongSelf = weakSelf;
            strongSelf.recordTip.text = @"正在录音...";
        }];
    }
    else{
        [self.recoder fl_pause:nil];
//        [self.recoder fl_stop:nil];
    }
}

- (IBAction)clickToPlay:(id)sender {
    __weak typeof(self) weakSelf = self;
    if (self.playSwitch.on) {
//        [self.recoder fl_stop:^(NSString *url) {
//            typeof(self) strongSelf = weakSelf;
//            NSLog(@"stop");
//            strongSelf.recordTip.text = @"录音";
//            strongSelf.player = [[FLAudioPlayer alloc] initWithUrl:url];
//            strongSelf.player.delegate = strongSelf;
//            strongSelf.startLabel.text = FL_COVERTTIME(strongSelf.player.currentTime.doubleValue);
//            strongSelf.endLabel.text = FL_COVERTTIME(strongSelf.player.totalTime.doubleValue);
//        }];
        
        [self.player fl_start:^{
            typeof(self) strongSelf = weakSelf;
            strongSelf.playTip.text = @"正在播放...";
            strongSelf.startLabel.text = FL_COVERTTIME(strongSelf.player.currentTime.doubleValue);
            strongSelf.endLabel.text = FL_COVERTTIME(strongSelf.player.totalTime.doubleValue);
        }];
    }
    else{
        [self.player fl_pause:^{
            typeof(self) strongSelf = weakSelf;
            NSLog(@"pause");
            /*
             *  BY gitKong
             *
             *  是不会出现循环引用，因此player没有引用block，安全起见，还是建议加上
             */
            strongSelf.playTip.text = @"播放";
        }];
    }
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
    self.player = [[FLAudioPlayer alloc] initWithUrl:url];
    self.player.delegate = self;
    self.startLabel.text = FL_COVERTTIME(self.player.currentTime.doubleValue);
    self.endLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue);
}

- (void)fl_audioRecorder:(FLAudioRecorder *)recorder didFailureWithError:(NSError *)error{
    NSLog(@"录音失败,error = %@",error.localizedDescription);
}

#pragma mark - audio player delegate

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer beginPlayingWithTotalTime:(NSNumber *)totalTime{
    self.endLabel.text = FL_COVERTTIME(totalTime.doubleValue);
}

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer playingToCurrentProgress:(NSNumber *)progress withBufferProgress:(NSNumber *)bufferProgress{
    self.fl_slider.value = progress.floatValue;
//    NSLog(@"VC -- progress = %.2lf",bufferProgress.floatValue);
//    self.fl_slider.cacheValue = bufferProgress.floatValue;
    self.startLabel.text = FL_COVERTTIME(self.player.totalTime.doubleValue * progress.doubleValue);
}

- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer cacheToCurrentBufferProgress:(NSNumber *)bufferProgress{
    self.fl_slider.cacheValue = bufferProgress.floatValue;
}

/*
 *  BY gitKong
 *
 *  模拟下一个播放的个数
 */
static int playMaxCount = 2;

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
        
        [audioPlayer fl_stop:nil];
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
