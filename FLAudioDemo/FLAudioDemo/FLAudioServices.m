//
//  FLAudioServices.m
//  FLAudioServicesDemo
//
//  Created by clarence on 17/3/17.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "FLAudioServices.h"
@import UIKit;

@interface FLAudioRecorder ()<AVAudioRecorderDelegate>
@property (nonatomic,strong)AVAudioRecorder *recoder;
@property (nonatomic,assign)FLAudioRecoderStatus fl_recorderStatus;
@end

@implementation FLAudioRecorder

- (instancetype)init{
    if (self = [super init]) {
        [self fl_default];
    }
    return self;
}


- (void)fl_prepareToRecord{
    // 先stop
    [self fl_stop:nil];
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        case AVAuthorizationStatusAuthorized:{
            // already authorize,init capture session
            [self fl_createAudioRecorder];
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            // waiting user to authorize
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
    self.recoder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:[self fl_filePath]] settings:[self fl_recorderSetting] error:&error];
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return;
    }
    
    self.recoder.delegate = self;
    // 开启音量检测
    self.recoder.meteringEnabled = YES;
    if ([self.recoder prepareToRecord]) {
        self.fl_recorderStatus = Recoder_Prepared;
    }
    else{
        self.fl_recorderStatus = Recoder_NotPrepare;
    }
}

- (void)fl_start:(void(^)())complete{
    if (self.recoder && !self.recoder.isRecording && self.fl_recorderStatus == Recoder_Prepared) {
        [self.recoder record];
        if (complete) {
            complete();
        }
    }
    else{
        NSLog(@"请先 prepare");
    }
}

- (void)fl_pause:(void(^)())complete{
    if (self.recoder && self.recoder.isRecording) {
        [self.recoder pause];
        self.fl_recorderStatus = Recoder_Pausing;
        if (complete) {
            complete();
        }
    }
}

- (void)fl_stop:(void(^)(NSString *url))complete{
    if (self.recoder) {
        [self.recoder stop];
        self.fl_recorderStatus = Recoder_Stoping;
        if (complete) {
            complete([self fl_filePath]);
        }
    }
}

- (void)dealloc{
    if (self.recoder) {
        [self.recoder stop];
        self.fl_recorderStatus = Recoder_Stoping;
        self.recoder = nil;
    }
}

#pragma mark -- Setter & Getter

- (BOOL)isRecording{
    if (self.recoder) {
        return self.recoder.isRecording;
    }
    else{
        return NO;
    }
}

#pragma mark -- AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"record did finished");
}

#pragma mark -- private method

- (void)fl_default{
    self.fl_audioFromatId = kAudioFormatAppleIMA4;
    self.fl_sampleRate = 44100.0f;
    self.fl_channels = 2;
    self.fl_bitDepthHint = 16;
    self.fl_bitRate = 128000;
    self.fl_audioQuality = AVAudioQualityHigh;
    self.fl_recorderStatus = Recoder_NotPrepare;
}

- (NSDictionary *)fl_recorderSetting{
    return @{
             AVFormatIDKey : @(self.fl_audioFromatId),
             AVSampleRateKey : @(self.fl_sampleRate),
             AVNumberOfChannelsKey : @(self.fl_channels),
             AVEncoderBitDepthHintKey : @(self.fl_bitDepthHint),
             AVEncoderAudioQualityKey : @(self.fl_audioQuality),
             AVEncoderBitRateKey:@(self.fl_bitRate)
             };
}


- (NSString *)fl_filePath{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"gitKong.caf"];
}

/**
 *  @author gitKong
 *
 *  show tip for user auth
 */
- (void)fl_showAuthTip{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"您还没开启授权麦克风，请打开--> 设置 -- > 隐私 --> 通用等权限设置" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

@end


@interface FLAudioPlayer ()
@property (strong, nonatomic) AVPlayer *player;
@property (nonatomic,assign)FLAudioPlayerStatus fl_playerStatus;
@property (nonatomic,strong)id timeObserver;
@property (nonatomic,assign)CGFloat bufferProgress;

@end

@implementation FLAudioPlayer

BOOL fl_isNetUrl(NSString *urlString){
    return [[urlString substringToIndex:4] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[urlString substringToIndex:5] caseInsensitiveCompare:@"https"] == NSOrderedSame;
}

- (instancetype)initWithUrl:(NSString *)urlString{
    if (self = [super init]) {
        [self fl_createPlayWithUrl:urlString andStartImmediately:NO];
    }
    return self;
}

- (void)fl_start:(void(^)())complete{
    if (self.player) {
        [self.player play];
        self.fl_playerStatus = Player_Playing;
        if (self.delegate && [self.delegate respondsToSelector:@selector(fl_audioPlayer:beginPlayingWithTotalTime:)]) {
            [self.delegate fl_audioPlayer:self beginPlayingWithTotalTime:self.totalTime];
        }
        if (complete) {
            complete();
        }
    }
}


- (void)fl_pause:(void(^)())complete{
    if (self.player) {
        [self.player pause];
        self.fl_playerStatus = Player_Pausing;
        if (complete) {
            complete();
        }
    }
}


- (void)fl_stop:(void(^)())complete{
    if (self.player) {
        [self.player pause];
        self.fl_playerStatus = Player_Stoping;
        [self fl_seek:self.player toTime:0 andStartImmediately:NO complete:^(BOOL finished) {
            if (complete) {
                complete();
            }
        }];
    }
}

- (void)fl_seekToProgress:(CGFloat)progress complete:(void (^)(BOOL))complete{
    [self fl_seekToProgress:progress andStartImmediately:YES complete:complete];
}

- (void)fl_seekToProgress:(CGFloat)progress andStartImmediately:(BOOL)startImmediately complete:(void (^)(BOOL finished))complete{
    if (progress > 1.0) {
        progress = 1.0;
    }
    if (progress < 0) {
        progress = 0;
    }
    double time = progress * self.totalTime;
    
    if (self.player) {
        if (self.fl_playerStatus == Player_Playing) {
            [self fl_pause:nil];
        }
        
        [self fl_seek:self.player toTime:time andStartImmediately:startImmediately complete:complete];
    }
}


#pragma mark - private method

- (NSURL *)fl_getSuitableUrl:(NSString *)urlString{
    NSURL *url = nil;
    if (fl_isNetUrl(urlString)) {
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
        CGFloat progress = strongSelf.currentTime / strongSelf.totalTime;
        if (progress > 1.0) {
            progress = 1.0;
        }
        if (progress < 0) {
            progress = 0;
        }
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(fl_audioPlayer:playingToCurrentProgress:withBufferProgress:)]) {
            [strongSelf.delegate fl_audioPlayer:strongSelf playingToCurrentProgress:progress withBufferProgress:strongSelf.bufferProgress];
        }
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

- (void)fl_removeObserve{
    // reset currentBufferProgress
    self.bufferProgress = 0.0f;
    
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
            NSLog(@"自动播放下一条");
            [self fl_createPlayWithUrl:nextUrl andStartImmediately:YES];
        }
        else{
            [self fl_stop:nil];
            NSLog(@"停止了");
        }
    }
}

- (void)didFailedToPlayToEndTime:(NSNotification *)notification{
    if (self.delegate && [self.delegate respondsToSelector:@selector(fl_audioPlayer:didFailureWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"FLAudioPlayerFailedToPlayToEndTime" code:1002 userInfo:@{NSLocalizedDescriptionKey:@"不能正常播放到结束位置"}];
        [self.delegate fl_audioPlayer:self didFailureWithError:error];
    }
}

- (void)audioRouteChange:(NSNotification*)notification{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
            /*
             *  BY gitKong
             *
             *  耳机插入
             */
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            
            break;
            /*
             *  BY gitKong
             *
             *  耳机拔出
             */
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(fl_audioPlayer:didFailureWithError:)]) {
                NSError *error = [NSError errorWithDomain:@"FLAudioPlayerRouteChangeReasonOldDeviceUnavailable" code:1000 userInfo:@{NSLocalizedDescriptionKey:@"耳机拔出"}];
                [self.delegate fl_audioPlayer:self didFailureWithError:error];
            }
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            break;
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification{
    if (self.delegate && [self.delegate respondsToSelector:@selector(fl_audioPlayer:didFailureWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"FLAudioPlayerApplicationDidEnterBackground" code:1003 userInfo:@{NSLocalizedDescriptionKey:@"App 进入后台"}];
        [self.delegate fl_audioPlayer:self didFailureWithError:error];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
        }
        else if(status == AVPlayerStatusUnknown){
        }
        else if (status == AVPlayerStatusFailed){
            if (self.delegate && [self.delegate respondsToSelector:@selector(fl_audioPlayer:didFailureWithError:)]) {
                NSError *error = [NSError errorWithDomain:@"FLAudioPlayerStatusFailed" code:1001 userInfo:@{NSLocalizedDescriptionKey:@"初始化播放器信息失败"}];
                [self.delegate fl_audioPlayer:self didFailureWithError:error];
            }
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        CGFloat bufferProgress = totalBuffer / self.totalTime;
        self.bufferProgress = bufferProgress;
        NSLog(@"缓冲：%.2f",bufferProgress);
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        NSLog(@"playbackBufferEmpty");
        self.bufferProgress = 0.0f;
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        
        NSLog(@"playbackLikelyToKeepUp");
    }
}


- (void)dealloc{
    [self fl_removeObserve];
}

/*
 *  BY gitKong
 *
 *  保留
 */
NSString *fl_convertTime(CGFloat second){
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
#warning TODO 优化formatter，影响性能
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

- (double)totalTime{
    if (self.player) {
        return CMTimeGetSeconds(self.player.currentItem.asset.duration);
    }
    return 0.0f;
}

- (double)currentTime{
    if (self.player) {
        return CMTimeGetSeconds(self.player.currentItem.currentTime);
    }
    return 0.0f;
}


@end


