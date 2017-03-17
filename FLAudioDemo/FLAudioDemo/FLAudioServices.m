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
    // 录音会话设置
    NSError *errorSession = nil;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance]; // 得到AVAudioSession单例对象
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &errorSession];// 设置类别,表示该应用同时支持播放和录音
    [audioSession setActive:YES error: &errorSession];// 启动音频会话管理,此时会阻断后台音乐的播放.
    
    // 设置成扬声器播放
    UInt32 doChangeDefault = 1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefault), &doChangeDefault);
    NSError *error;
    /* The file type to record is inferred from the file extension. Will overwrite a file at the specified url if a file exists */
    self.recoder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:[self fl_filePath]] settings:[self fl_recorderSetting] error:&error];
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
    NSLog(@"-o-");
    if (self.recoder && !self.recoder.isRecording && self.fl_recorderStatus == Recoder_Prepared) {
        NSLog(@"---");
        [self.recoder record];
        if (complete) {
            complete();
        }
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

- (void)fl_stop:(void(^)(NSData *data))complete{
    if (self.recoder) {
        [self.recoder stop];
        self.fl_recorderStatus = Recoder_Stoping;
        if (complete) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[self fl_filePath]]];
            complete(data);
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
             AVEncoderAudioQualityKey : @(self.fl_audioQuality)
//             AVEncoderBitRateKey:@(self.fl_bitRate)
             };
}


- (NSString *)fl_filePath{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"voice.caf"];
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
@end

@implementation FLAudioPlayer

- (instancetype)initWithUrl:(NSString *)urlString{
    if (self = [super init]) {
        NSURL *url = nil;
        if ([[urlString substringToIndex:4] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[urlString substringToIndex:5] caseInsensitiveCompare:@"https"] == NSOrderedSame) {
            NSLog(@"same");
            url = [NSURL URLWithString:urlString];
        }
        else{
            url = [NSURL fileURLWithPath:urlString];
        }
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        self.player = [AVPlayer playerWithPlayerItem:item];
    }
    return self;
}

- (void)fl_start:(void(^)())complete{
    if (self.player) {
        [self.player play];
        self.fl_playerStatus = Player_Playing;
        if (complete) {
            complete();
        }
    }
}


- (void)fl_pause:(void(^)())complete{
    if (self.player) {
        [self.player pause];
        self.fl_playerStatus = Player_Pausing;
    }
}


- (void)fl_stop:(void(^)())complete{
    if (self.player) {
        [self.player seekToTime:CMTimeMakeWithSeconds(0, 1 *NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            if (complete) {
                complete();
            }
        }];
        [self.player pause];
        self.fl_playerStatus = Player_Stoping;
    }
}

@end


