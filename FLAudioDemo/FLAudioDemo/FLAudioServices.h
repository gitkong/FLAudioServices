/*
 * author gitKong
 *
 * 个人博客 https://gitKong.github.io
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 微信公众号 原创技术分享
 * 喜欢就给个like 和 star 喔~
 */

#import <Foundation/Foundation.h>
@import AVFoundation;
@import AudioToolbox;

typedef NS_ENUM(NSInteger,FLAudioRecoderStatus){
    Recoder_NotPrepare,
    Recoder_Prepared,
    Recoder_Recording,
    Recoder_Pausing,
    Recoder_Stoping
};

typedef NS_ENUM(NSInteger,FLAudioPlayerStatus){
    Player_Playing,
    Player_Pausing,
    Player_Stoping
};

@interface FLAudioRecorder : NSObject
/*
 *  BY gitKong
 *
 *  音频格式,Default is kAudioFormatAppleIMA4
 */
@property (nonatomic,assign)AudioFormatID fl_audioFromatId;
/*
 *  BY gitKong
 *
 *  录音采样率（Hz）Default is 44100
 */
@property (nonatomic,assign)NSInteger fl_sampleRate;
/*
 *  BY gitKong
 *
 *  音频通道数,Default is 2
 */
@property (nonatomic,assign)NSInteger fl_channels;
/*
 *  BY gitKong
 *
 *  线性音频的量化精度(位深度)（当进行频率采样时，较高的量化精度可以提供更多可能性的振幅值，从而产生更为大的振动范围，更高的信噪比，提高保真度） Default is 16
 */
@property (nonatomic,assign)NSInteger fl_bitDepthHint;
/*
 *  BY gitKong
 *
 *  录音的质量,Defalut is AVAudioQualityHigh
 */
@property (nonatomic,assign)AVAudioQuality fl_audioQuality;
/*
 *  BY gitKong
 *
 *  音频编码的比特率(传输的速率) 单位bps Default is 128000
 */
@property (nonatomic,assign)NSInteger fl_bitRate;

/*
 *  BY gitKong
 *
 *  录音状态
 */
@property (nonatomic,assign,readonly)FLAudioRecoderStatus fl_recorderStatus;

/*
 *  BY gitKong
 *
 *  准备录音，设置参数后需要调用
 */
- (void)fl_prepareToRecord;
/*
 *  BY gitKong
 *
 *  开始录音，录音前必须先调用 fl_prepareToRecord 
 */
- (void)fl_start:(void(^)())complete;
/*
 *  BY gitKong
 *
 *  暂停录音
 */
- (void)fl_pause:(void(^)())complete;
/*
 *  BY gitKong
 *
 *  结束录音，data 为录音数据
 */
- (void)fl_stop:(void(^)(NSData *data))complete;

@end


@interface FLAudioPlayer : NSObject
/*
 *  BY gitKong
 *
 *  播放状态
 */
@property (nonatomic,assign,readonly)FLAudioPlayerStatus fl_playerStatus;

@property (nonatomic,assign,readonly)double totalTime;

@property (nonatomic,assign,readonly)double currentTime;

/*
 *  BY gitKong
 *
 *  播放地址
 */
- (instancetype)initWithUrl:(NSString *)urlString;
/*
 *  BY gitKong
 *
 *  开始播放
 */
- (void)fl_start:(void(^)())complete;

/*
 *  BY gitKong
 *
 *  暂停播放
 */
- (void)fl_pause:(void(^)())complete;

/*
 *  BY gitKong
 *
 *  结束播放
 */
- (void)fl_stop:(void(^)())complete;
/*
 *  BY gitKong
 *
 *  设置当前播放进度
 */
- (void)fl_seekToTime:(double)time complete:(void (^)(BOOL finished))complete;

@end

