//
//  FLAudioServices.m
//  FLAudioServicesDemo
//
//  Created by clarence on 17/3/17.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "FLAudioServices.h"
@import UIKit;
@import MediaPlayer;
#define FLSuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

typedef NS_ENUM(NSUInteger, FLAudioRecorderErrorCode) {
    FLAudioRecorderErrorByRecorderIsNotInit = 1000,
    FLAudioRecorderErrorByRecorderPrepareFailure,
    FLAudioRecorderErrorByEncodingFailure,
    FLAudioRecorderErrorByInterruption,
    FLAudioRecorderErrorUnknown,
};

@interface FLAudioRecorder ()<AVAudioRecorderDelegate>
@property (nonatomic,strong)AVAudioRecorder *Recorder;
@property (nonatomic,assign)FLAudioRecorderStatus recorderStatus;
@property (nonatomic,strong)dispatch_source_t timer;
@property (nonatomic,assign)CGFloat count;
@property (nonatomic,assign)BOOL suspended;
@end

@implementation FLAudioRecorder

- (instancetype)init{
    if (self = [super init]) {
        [self fl_initRecorder];
    }
    return self;
}

- (void)fl_initRecorder{
    // 先stop
    [self fl_stop:nil];
    [self fl_default];
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        case AVAuthorizationStatusAuthorized:{
            [self fl_createAudioRecorder];
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted) {
                    [self fl_createAudioRecorder];
                }
                else{
                    [self fl_showAuthTip];
                }
            }];
            break;
        }
        default:
            [self fl_showAuthTip];
            break;
    }
}



- (void)fl_createAudioRecorder{
    NSError *error;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    // 设置类别,表示该应用同时支持播放和录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];
    // 启动音频会话管理,此时会阻断后台音乐的播放.
    [audioSession setActive:YES error: &error];
    
    // 设置成扬声器播放
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    /* The file type to record is inferred from the file extension. Will overwrite a file at the specified url if a file exists */
    self.Recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:[self fl_filePath]] settings:[self fl_recorderSetting] error:&error];
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByRecorderIsNotInit];
        return;
    }
    
    [self fl_createTimer];
    
    self.Recorder.delegate = self;
    // 开启音量检测
    self.Recorder.meteringEnabled = YES;
    
    if (![self.Recorder prepareToRecord]) {
        [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByRecorderPrepareFailure];
    }
}

- (void)fl_start:(void(^)())complete{
    if (!self.Recorder) {
        [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByRecorderIsNotInit];
        return;
    }
    if (!self.Recorder.isRecording) {
        [self.Recorder record];
        if (self.recorderStatus == Recorder_Stoping) {// 首次或者stop后重开
            FL_DELEGATE_RESPONSE(self.delegate, @selector(fl_audioRecorder:beginRecodingToUrl:), @[self,[NSURL fileURLWithPath:[self fl_filePath]]], nil);
        }
        self.recorderStatus = Recorder_Recording;
        // 开启定时器
        [self fl_fireTimer];
        if (complete) {
            complete();
        }
    }
}

- (void)fl_createTimer{
    // 创建定时器对象
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    // 设置时间间隔
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 0);
    // 定时器回调
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf.count >= strongSelf.endTime * 100) {
            strongSelf.count = strongSelf.endTime * 100;
            [strongSelf fl_stopTimer];
            return;
        }
        FL_DELEGATE_RESPONSE(strongSelf.delegate, @selector(fl_audioRecorder:recodingWithCurrentTime:), @[strongSelf,@(strongSelf.count++ / 100)], nil);
    });
    
}
// 内部计数器,不能这样，多线程会造成数据紊乱
//static CGFloat count = 0;
//static BOOL suspended = YES;

- (void)fl_fireTimer{
    if (!self.timer) {
        return;
    }
    if (self.suspended) {
        dispatch_resume(self.timer);
        self.suspended = NO;
    }
}

- (void)fl_pauseTimer{
    if (!self.timer) {
        return;
    }
    if (!self.suspended) {
        dispatch_suspend(self.timer);
        self.suspended = YES;
    }
}

- (void)fl_stopTimer{
    if (!self.timer) {
        return;
    }
    if (!self.suspended) {
        dispatch_suspend(self.timer);
        self.suspended = YES;
        FL_DELEGATE_RESPONSE(self.delegate, @selector(fl_audioRecorder:finishRecodingWithTotalTime:), @[self,@(self.count / 100)], nil);
        // 重置计数器
        self.count = 0;
    }
    
}

- (void)fl_pause:(void(^)())complete{
    if (!self.Recorder) {
        [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByRecorderIsNotInit];
        return;
    }
    if (self.Recorder.isRecording) {
        [self.Recorder pause];
        [self fl_pauseTimer];
        self.recorderStatus = Recorder_Pausing;
        if (complete) {
            complete();
        }
    }
}

- (void)fl_stop:(void(^)(NSString *url))complete{
    if (self.Recorder) {
        [self.Recorder stop];
        [self fl_stopTimer];
        self.recorderStatus = Recorder_Stoping;
        if (complete) {
            complete([self fl_filePath]);
        }
    }
    else{
        [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByRecorderIsNotInit];
    }
}

- (void)dealloc{
    if (self.Recorder) {
        [self.Recorder stop];
        self.recorderStatus = Recorder_Stoping;
        self.Recorder = nil;
    }
}

#pragma mark -- Setter & Getter

- (BOOL)isRecording{
    if (self.Recorder) {
        return self.Recorder.isRecording;
    }
    else{
        [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByRecorderIsNotInit];
        return NO;
    }
}

#pragma mark -- AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (flag) {
        NSLog(@"record did finished");
    }
    else{
        // 编码错误
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    // 编码错误
    [self fl_stop:nil];
    [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByEncodingFailure];
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
    // 被打断
    [self fl_stop:nil];
    [self fl_delegateResponseFailureWithCode:FLAudioRecorderErrorByInterruption];
}

#pragma mark -- private method

- (void)fl_default{
    self.audioFromatId = kAudioFormatAppleIMA4;
    self.sampleRate = 44100.0f;
    self.channels = 2;
    self.bitDepthHint = 16;
    self.bitRate = 128000;
    self.audioQuality = AVAudioQualityHigh;
    self.recorderStatus = Recorder_Stoping;
    self.endTime = MAXFLOAT;
    self.suspended = YES;
}

- (NSDictionary *)fl_recorderSetting{
    return @{
             AVFormatIDKey : @(self.audioFromatId),
             AVSampleRateKey : @(self.sampleRate),
             AVNumberOfChannelsKey : @(self.channels),
             AVEncoderBitDepthHintKey : @(self.bitDepthHint),
             AVEncoderAudioQualityKey : @(self.audioQuality),
             AVEncoderBitRateKey:@(self.bitRate)
             };
}


- (NSString *)fl_filePath{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"gitKong.caf"];
}

- (void)fl_showAuthTip{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"您还没开启授权麦克风，请打开--> 设置 -- > 隐私 --> 通用等权限设置" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}


- (void)fl_delegateResponseToSelector:(SEL)selector withObject:(NSArray<id> *)objects complete:(void(^)())complete{
    FL_DELEGATE_RESPONSE(self.delegate, selector, objects, complete);
}

- (void)fl_delegateResponseFailureWithCode:(FLAudioRecorderErrorCode)errorCode{
    [self fl_delegateResponseToSelector:@selector(fl_audioRecorder:didFailureWithError:) withObject:@[self,[self fl_errorWithCode:errorCode]] complete:nil];
}

- (NSError *)fl_errorWithCode:(NSInteger)code{
    NSString *description = @"";
    switch (code - 1000) {
        case 0:
            description = @"录音器出现错误，录音器未初始化，请重新创建";
            break;
        case 1:
            description = @"录音器出现错误，录音器准备失败，请重新创建";
            break;
        case 2:
            description = @"录音器出现错误，编码失败";
            break;
        case 3:
            description = @"录音器出现错误，被打断";
            break;
        default:
            description = @"未知错误";
            break;
    }
    NSError *error = [NSError errorWithDomain:description code:code userInfo:@{NSLocalizedDescriptionKey:description}];
    
    return error;
}

void FL_DELEGATE_RESPONSE(id delegate,SEL selector,NSArray<id> * objects,void(^complete)()){
    if (delegate && [delegate respondsToSelector:selector]) {
        FLSuppressPerformSelectorLeakWarning(
                                             FL_PERFORM_SELECTOR(delegate, selector, objects);
                                             );
        if (complete) {
            complete();
        }
    }
}

id FL_PERFORM_SELECTOR(id target,SEL selector,NSArray <id>* objects){
    // 获取方法签名
    NSMethodSignature *sig = [target methodSignatureForSelector:selector];
    if (sig){
        NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
        [invo setTarget:target];
        [invo setSelector:selector];
        for (NSInteger index = 0; index < objects.count; index ++) {
            id object = objects[index];
            // 参数从下标2开始
            [invo setArgument:&object atIndex:index + 2];
        }
        [invo invoke];
        if (sig.methodReturnLength) {
            id anObject;
            [invo getReturnValue:&anObject];
            return anObject;
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}

#pragma mark - setter & getter

@end

typedef NS_ENUM(NSUInteger, FLAudioPlayerErrorCode) {
    FLAudioPlayerErrorByDeviceUnavailable = 1000,
    FLAudioPlayerErrorByPlayerStatusFailed,
    FLAudioPlayerErrorByFailureToPlayToEnd,
    FLAudioPlayerErrorByEnterBackground,
    FLAudioPlayerErrorByPlayerIsNotInit,
    FLAudioPlayerErrorByUnknow
};

@interface FLAudioPlayer ()
@property (strong, nonatomic) AVPlayer *player;
@property (nonatomic,assign)FLAudioPlayerStatus playerStatus;
@property (nonatomic,strong)id timeObserver;
@property (nonatomic,strong)NSNumber *bufferProgress;
@property (nonatomic,strong)NSNumber *totalTime;
@property (nonatomic,strong)NSNumber *currentTime;
@property (nonatomic,strong)UISlider *volumSlider;
@end

@implementation FLAudioPlayer

- (instancetype)initWithUrl:(NSString *)urlString{
    if (self = [super init]) {
        [self fl_createPlayWithUrl:urlString andStartImmediately:NO];
    }
    return self;
}

- (void)fl_start:(void(^)())complete{
    if (self.player) {
        if (self.playerStatus == Player_Stoping) {// 第一次播放和结束后重新播放
            [self fl_delegateResponseToSelector:@selector(fl_audioPlayer:beginPlayingWithTotalTime:) withObject:@[self,self.totalTime] complete:nil];
        }
        [self.player play];
        self.playerStatus = Player_Playing;
        if (complete) {
            complete();
        }
    }
    else{
        [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerIsNotInit];
    }
}

- (void)fl_pause:(void(^)())complete{
    if (self.player) {
        [self.player pause];
        self.playerStatus = Player_Pausing;
        if (complete) {
            complete();
        }
    }
    else{
        [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerIsNotInit];
    }
}

- (void)fl_stop:(void(^)())complete{
    if (self.player) {
        [self.player pause];
        self.playerStatus = Player_Stoping;
        [self fl_seek:self.player toTime:0 andStartImmediately:NO complete:^(BOOL finished) {
            if (complete) {
                complete();
            }
        }];
    }
    else{
        [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerIsNotInit];
    }
}

- (void)fl_seekToProgress:(CGFloat)progress complete:(void (^)(BOOL))complete{
    [self fl_seekToProgress:progress andStartImmediately:YES complete:complete];
}

- (void)fl_seekToProgress:(CGFloat)progress andStartImmediately:(BOOL)startImmediately complete:(void (^)(BOOL finished))complete{
    double time = FL_SAVE_PROGRESS(progress) * self.totalTime.doubleValue;
    
    if (self.player) {
        if (self.playerStatus == Player_Playing) {
            [self fl_pause:nil];
        }
        [self fl_seek:self.player toTime:time andStartImmediately:startImmediately complete:complete];
    }
    else{
        [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerIsNotInit];
    }
}


#pragma mark - private method

- (NSURL *)fl_getSuitableUrl:(NSString *)urlString{
    NSURL *url = nil;
    if (FL_ISNETURL(urlString)) {
        url = [NSURL URLWithString:urlString];
    }
    else{
        url = [NSURL fileURLWithPath:urlString];
    }
    return url;
}

- (void)fl_createPlayWithUrl:(NSString *)urlString andStartImmediately:(BOOL)startImmediately{
    // 销毁之前的
    [self fl_removeObserve];
    // 创建新的
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[self fl_getSuitableUrl:urlString]];
    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:item];
    }
    else{
        [self.player replaceCurrentItemWithPlayerItem:item];
    }
    [self fl_addObserve];
    self.playerStatus = Player_Stoping;
    if (startImmediately) {
        [self fl_start:nil];
    }
}

- (void)fl_seek:(AVPlayer *)player toTime:(double)time andStartImmediately:(BOOL)startImmediately complete:(void(^)(BOOL finished))complete{
    __weak typeof(self) weakSelf = self;
    [player seekToTime:CMTimeMakeWithSeconds(time, 1 *NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        typeof(self) strongSelf = weakSelf;
        if (startImmediately) {
            [strongSelf fl_start:nil];
        }
        if (complete) {
            complete(finished);
        }
    }];
}

- (void)fl_addObserve{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    
    if (!self.player) {
        return;
    }
    [self fl_addObserverToPlayerItem:self.player.currentItem];
    
    // 调用者主动stop、正常播放结束stop、没正常播放结束stop
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        typeof(self) strongSelf = weakSelf;
        CGFloat progress = strongSelf.currentTime.doubleValue / strongSelf.totalTime.doubleValue;
        [strongSelf fl_delegateResponseToSelector:@selector(fl_audioPlayer:playingToCurrentProgress:withBufferProgress:) withObject:@[strongSelf,@(FL_SAVE_PROGRESS(progress)),strongSelf.bufferProgress] complete:nil];
    }];
}

- (void)fl_addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放的区域缓存是否为空
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)fl_removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

- (void)fl_resetDefault{
    self.bufferProgress = @0.0f;
    self.currentTime = @0.0f;
    self.totalTime = @0.0f;
    self.playerStatus = Player_Stoping;
}

- (void)fl_removeObserve{
    self.bufferProgress = @0.0f;
    if (self.player) {
        if (self.timeObserver) {
            [self.player removeTimeObserver:self.timeObserver];
        }
        [self fl_removeObserverFromPlayerItem:self.player.currentItem];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didFinishPlay:(NSNotification *)notification{
    if (self.delegate && [self.delegate respondsToSelector:@selector(fl_audioPlayer:didFinishAndPlayNext:)]) {
        NSString __autoreleasing *nextUrl = nil;
        [self.delegate fl_audioPlayer:self didFinishAndPlayNext:&nextUrl];
        if (nextUrl) {
            [self fl_createPlayWithUrl:nextUrl andStartImmediately:YES];
        }
        else{
            [self fl_stop:nil];
        }
    }
}

- (void)didFailedToPlayToEndTime:(NSNotification *)notification{
    [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByFailureToPlayToEnd];
}

- (void)audioRouteChange:(NSNotification*)notification{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //耳机插入
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:{
            //耳机拔出
            [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByDeviceUnavailable];
        }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            break;
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification{
    [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByEnterBackground];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
        }
        else if(status == AVPlayerStatusUnknown){
            [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByUnknow];
        }
        else if (status == AVPlayerStatusFailed){
            [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerStatusFailed];
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲总长度
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        CGFloat bufferProgress = totalBuffer / self.totalTime.doubleValue;
        self.bufferProgress = @(FL_SAVE_PROGRESS(bufferProgress));
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        self.bufferProgress = @0.0f;
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
    }
}

- (void)fl_delegateResponseToSelector:(SEL)selector withObject:(NSArray<id> *)objects complete:(void(^)())complete{
    FL_DELEGATE_RESPONSE(self.delegate, selector, objects, complete);
}

- (void)fl_delegateResponseFailureWithCode:(FLAudioPlayerErrorCode)errorCode{
    [self fl_delegateResponseToSelector:@selector(fl_audioPlayer:didFailureWithError:) withObject:@[self,[self fl_errorWithCode:errorCode]] complete:nil];
}

- (NSError *)fl_errorWithCode:(NSInteger)code{
    NSString *description = @"";
    switch (code - 1000) {
        case 0:
            description = @"播放出现错误，耳机拔出";
            break;
        case 1:
            description = @"播放器不能播放当前URL";
            break;
        case 2:
            description = @"播放器不能正常播放到结束位置";
            break;
        case 3:
            description = @"播放器播放出现错误，应用进入后台";
            break;
        case 4:
            description = @"播放器出现错误，播放器未初始化";
            break;
        case 5:
            description = @"未知错误";
            break;
        default:
            description = @"未知错误";
            break;
    }
     NSError *error = [NSError errorWithDomain:description code:code userInfo:@{NSLocalizedDescriptionKey:description}];
    
    return error;
}

- (void)dealloc{
    [self fl_removeObserve];
}

BOOL FL_ISNETURL(NSString *urlString){
    return [[urlString substringToIndex:4] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[urlString substringToIndex:5] caseInsensitiveCompare:@"https"] == NSOrderedSame;
}

CGFloat FL_SAVE_PROGRESS(CGFloat progress){
    if (progress > 1.0) progress = 1.0;
    if (progress < 0) progress = 0;
    return progress;
}



NSString *FL_COVERTTIME(CGFloat second){
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:date];
    return showtimeNew;
}

#pragma mark - setter & getter

- (void)setCurrentVolum:(CGFloat)currentVolum{
    self.volumSlider.value = FL_SAVE_PROGRESS(currentVolum);
}

- (CGFloat)currentVolum{
    return FL_SAVE_PROGRESS(self.volumSlider.value);
}

- (NSNumber *)totalTime{
    if (self.player) {
        return @(CMTimeGetSeconds(self.player.currentItem.asset.duration) > 0.0f ? CMTimeGetSeconds(self.player.currentItem.asset.duration) : 0.0f);
    }
    [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerIsNotInit];
    return @0.0f;
}

- (NSNumber *)currentTime{
    if (self.player) {
        return @(CMTimeGetSeconds(self.player.currentItem.currentTime) > 0.0f ? CMTimeGetSeconds(self.player.currentItem.currentTime) : 0.0f);
    }
    [self fl_delegateResponseFailureWithCode:FLAudioPlayerErrorByPlayerIsNotInit];
    return @0.0f;
}

- (UISlider *)volumSlider{
    if (_volumSlider == nil) {
        MPVolumeView *volumView = [[MPVolumeView alloc] init];
        _volumSlider = [volumView valueForKey:@"volumeSlider"];
    }
    return _volumSlider;
}

@end


