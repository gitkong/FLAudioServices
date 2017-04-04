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


#define FL_COVERTTIME(second) (((NSString *)fl_convertTime(second)));
NSString *fl_convertTime(CGFloat second);
typedef NS_ENUM(NSInteger,FLAudioRecoderStatus){
    Recoder_NotPrepare,
    Recoder_Prepared,
    Recoder_Recording,
    Recoder_Pausing,
    Recoder_Stoping
};

typedef NS_ENUM(NSInteger,FLAudioPlayerStatus){
    Player_Playing,// 正在播放
    Player_Pausing,//暂停播放
    Player_Stoping// 停止播放
};
@class FLAudioRecorder;
@protocol FLAudioRecoderDelegate <NSObject>

- (void)fl_audioRecoder:(FLAudioRecorder *)recoder beginRecodingWithUrl:(NSURL *)url;

- (void)fl_audioRecoder:(FLAudioRecorder *)recoder recodingWithCurrentTime:(NSNumber *)currentTime;

- (void)fl_audioRecoder:(FLAudioRecorder *)recoder finishRecodingWithTotalTime:(NSNumber *)totalTime;

@end

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
 *  准备录音，设置参数或者stop后需要重新调用
 */
- (void)fl_prepareToRecord;
/*
 *  BY gitKong
 *
 *  开始录音，注意，stop后需要重新调用fl_prepareToRecord 
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
 *  结束录音，url 为默认录音文件路径
 */
- (void)fl_stop:(void(^)(NSString *url))complete;

@end

@class FLAudioPlayer;
@protocol FLAudioPlayerDelegate <NSObject>
/*
 *  BY gitKong
 *
 *  当开始播放时会调用，对应一个音频url只会调用一次
 *
 *  totalTime：总播放时间
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer beginPlayingWithTotalTime:(NSNumber *)totalTime;
/*
 *  BY gitKong
 *
 *  正在播放会调用，多次执行
 *
 *  progress：当前的播放进度 bufferProgress：当前的缓冲进度
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer playingToCurrentProgress:(NSNumber *)progress withBufferProgress:(NSNumber *)bufferProgress;
/*
 *  BY gitKong
 *
 *  正常结束播放调用，对应一个音频url只会调用一次
 *
 *  nextUrl：就是下一条要播放的url，传入nil表示不自动放下一条
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFinishAndPlayNext:(NSString * __autoreleasing *)nextUrl;
/*
 *  BY gitKong
 *
 *  出现错误会执行,注意：耳机拔出也会调用
 *
 *  code     1000：耳机拔出
                1001：播放器不能播放当前URL
                1002：不能正常播放到结束位置
                1003：进入后台
                1004:  播放器未初始化
                1005:  未知错误
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFailureWithError:(NSError *)error;

@end


@interface FLAudioPlayer : NSObject
/*
 *  BY gitKong
 *
 *  播放状态
 */
@property (nonatomic,assign,readonly)FLAudioPlayerStatus fl_playerStatus;
/*
 *  BY gitKong
 *
 *  播放总时间,自带转换字符串方法 利用宏 FL_COVERTTIME(second)
 */
@property (nonatomic,strong,readonly)NSNumber *totalTime;
/*
 *  BY gitKong
 *
 *  当前播放时间,自带转换字符串方法 利用宏 FL_COVERTTIME(second)
 */
@property (nonatomic,strong,readonly)NSNumber *currentTime;
/*
 *  BY gitKong
 *
 *  当前缓冲进度
 */
@property (nonatomic,strong,readonly)NSNumber *bufferProgress;
/*
 *  BY gitKong
 *
 *  播放代理
 */
@property (nonatomic,weak)id<FLAudioPlayerDelegate> delegate;

/*
 *  BY gitKong
 *
 *  播放地址，可传入本地文件url或者网络文件url
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
- (void)fl_seekToProgress:(CGFloat)progress complete:(void (^)(BOOL finished))complete;

- (void)fl_seekToProgress:(CGFloat)progress andStartImmediately:(BOOL)startImmediately complete:(void (^)(BOOL finished))complete;

@end

