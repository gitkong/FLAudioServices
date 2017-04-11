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

NSString *FL_COVERTTIME(CGFloat second);

typedef NS_ENUM(NSInteger,FLAudioRecorderStatus){
    Recorder_Recording,// 正在录音
    Recorder_Pausing,// 暂停录音
    Recorder_Stoping// 停止录音
};

typedef NS_ENUM(NSInteger,FLAudioPlayerStatus){
    Player_Playing,// 正在播放
    Player_Pausing,//暂停播放
    Player_Stoping// 停止播放
};
@class FLAudioRecorder;
@protocol FLAudioRecorderDelegate <NSObject>
@optional
/**
 首次开始录音调用，注意：pause后start不会调用，stop后start悔调用

 @param recorder 当前录音器
 @param url 录音回放地址
 */
- (void)fl_audioRecorder:(FLAudioRecorder *)recorder beginRecordingToUrl:(NSString *)url;

/**
 正在录音调用

 @param recorder 当前录音器
 @param currentTime 当前录音的秒数，单位秒，最多小数点后两位
 */
- (void)fl_audioRecorder:(FLAudioRecorder *)recorder recordingWithCurrentTime:(NSNumber *)currentTime;

/**
 结束录音调用

 @param recorder 当前录音器
 @param totalTime 总录音的秒数，单位秒，最多小数点后两位
 @param url 当前录音文件路径
 */
- (void)fl_audioRecorder:(FLAudioRecorder *)recorder finishRecordingWithTotalTime:(NSNumber *)totalTime toUrl:(NSString *)url;

/**
 录音出现错误调用

 @param recorder 当前录音器
 @param error 错误类型，其中code： 1000：录音器未初始化
                                                     1001：录音器准备播放失败
                                                     1002：录音器编码失败，此时会停止录音
                                                     1003：录音被打断,此时会暂停录音，结束后自动重启
                                                     1004：应用进入后台，此时会暂停录音，进入前台自动重启
                                                     1005:  未知错误
 */
- (void)fl_audioRecorder:(FLAudioRecorder *)recorder didFailureWithError:(NSError *)error;

@end

@interface FLAudioRecorder : NSObject

/**
 音频格式,Default is kAudioFormatAppleIMA4
 */
@property (nonatomic,assign)AudioFormatID audioFromatId;

/**
 录音采样率（Hz）Default is 44100
 */
@property (nonatomic,assign)NSInteger sampleRate;

/**
 音频通道数,Default is 2
 */
@property (nonatomic,assign)NSInteger channels;

/**
 线性音频的量化精度(位深度)（当进行频率采样时，较高的量化精度可以提供更多可能性的振幅值，从而产生更为大的振动范围，更高的信噪比，提高保真度） Default is 16
 */
@property (nonatomic,assign)NSInteger bitDepthHint;

/**
 录音的质量,Defalut is AVAudioQualityHigh
 */
@property (nonatomic,assign)AVAudioQuality audioQuality;

/**
 音频编码的比特率(传输的速率) 单位bps Default is 128000
 */
@property (nonatomic,assign)NSInteger bitRate;
/**
 录音结束时间，最多设置两位小数，默认MAXFLOAT
 */
@property (nonatomic,assign)CGFloat endTime;
/**
 代理
 */
@property (nonatomic,weak)id<FLAudioRecorderDelegate> delegate;

/**
 录音状态，默认是Recorder_NotPrepare
 */
@property (nonatomic,assign,readonly)FLAudioRecorderStatus recorderStatus;

/**
 准备录音，设置参数后调用才生效，注意：使用默认参数（不重新设置参数），可以不需要调用
 */
- (void)fl_prepare;
/**
 开始录音
 */
- (void)fl_start;

/**
 暂停录音
 */
- (void)fl_pause;

/**
 结束录音，url 为默认录音文件路径

 @param complete 完成回调
 */
- (void)fl_stop:(void(^)(NSString *url))complete;

@end

@class FLAudioPlayer;
@protocol FLAudioPlayerDelegate <NSObject>
@optional

/**
 当开始播放时会调用，对应一个音频url只会调用一次

 @param audioPlayer 当前播放器
 @param currentUrl 当前播放url地址
 @param totalTime 当前播放url的总时间，单位秒
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer beginPlaying:(NSString *)currentUrl withTotalTime:(NSNumber *)totalTime;

/**
 正在播放会调用，多次执行，不建议在此代理方法处理复杂操作

 @param audioPlayer 当前播放器
 @param progress 当前的播放进度
 @param bufferProgress 当前的缓冲进度(备用字段，获取缓冲进度请通过cacheToCurrentBufferProgress方法)
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer playingToCurrentProgress:(NSNumber *)progress withBufferProgress:(NSNumber *)bufferProgress;

/**
 当前播放缓冲进度

 @param audioPlayer 当前播放器
 @param bufferProgress 当前缓冲进度（0.0-1.0）
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer cacheToCurrentBufferProgress:(NSNumber *)bufferProgress;

/**
 正常结束播放调用，对应一个音频url只会调用一次（废弃！！！）
 如果要播放多条，可通过initWithUrl方法传入url数组,考虑到最新url通过异步请求获得
 无法准确传入，因此暂时废弃，待优化
 
 @param audioPlayer 当前播放器
 @param nextUrl 下一条要播放的url，nil表示不自动放下一条，默认nil
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFinishAndPlayNext:(NSString * __autoreleasing *)nextUrl;//废弃

/**
 正常结束播放调用，对应一个音频url只会调用一次

 @param audioPlayer 当前播放器
 @param isFinishAll 是否全部播放完毕
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFinishWithFlag:(NSNumber *)isFinishAll;

/**
 错误代理回调，注意：耳机拔出也会调用

 @param audioPlayer 当前播放器
 @param error 错误类型，其中code：  1000：耳机拔出
                                 1001：播放器不能播放当前URL
                                 1002：不能正常播放到结束位置
                                 1003：进入后台，此时会暂停播放，进入前台后自动播放
                                 1004:  播放器未初始化
                                 1005:  未知错误
 */
- (void)fl_audioPlayer:(FLAudioPlayer *)audioPlayer didFailureWithError:(NSError *)error;

@end


@interface FLAudioPlayer : NSObject
/**
 表示当前可播放的url数组
 */
@property (nonatomic,strong,readonly)NSMutableArray<NSString *> *valiableUrls;

/**
 剩下可播放的url地址数
 */
@property (nonatomic,assign,readonly)NSInteger lastTotalItemsCount;

/**
 当前播放的音量大小（0.0-1.0）,注意，播放音频的时候设置才生效
 */
@property (nonatomic,assign)CGFloat currentVolum;

/**
 播放状态，默认状态为：Player_Stoping
 */
@property (nonatomic,assign,readonly)FLAudioPlayerStatus playerStatus;

/**
 播放总时间,自带转换字符串方法 FL_COVERTTIME(second)
 */
@property (nonatomic,strong,readonly)NSNumber *totalTime;

/**
 当前播放时间,自带转换字符串方法 FL_COVERTTIME(second)
 */
@property (nonatomic,strong,readonly)NSNumber *currentTime;

/**
 当前缓冲进度，默认为@0.0f（备用字段，永远为@0.0f）
 */
@property (nonatomic,strong,readonly)NSNumber *bufferProgress;

/**
 播放代理
 */
@property (nonatomic,weak)id<FLAudioPlayerDelegate> delegate;

/**
 播放地址

 @param url 本地文件url或者网络文件url，可传数组和字符串
 @return 返回当前播放对象
 */
- (instancetype)initWithUrl:(id)url;

/**
 添加新的播放地址

 @param url 新的播放地址，可传数组和字符串地址
 */
- (void)fl_addUrl:(id)url;

/**
 移动播放点到下一条，意味着从下一条开始继续往下播放，默认自动开始播放
 */
- (void)fl_moveToNext;
/**
 移动播放点到上一条，意味着从上一条开始继续往下播放，默认自动开始播放
 */
- (void)fl_moveToPrevious;

/**
 移动播放点到指定位置

 @param index 指点位置
 @param startImmediately 是否马上播放
 */
- (void)fl_moveToIndex:(NSInteger)index andStartImmediately:(BOOL)startImmediately;

/**
 开始播放当前url地址，fl_playerStatus为Player_Playing
 如果调用前fl_playerStatus为Player_Pausing，则继续播放
 如果调用前fl_playerStatus为Player_Stoping，则重新播放
 */
- (void)fl_start;

/**
 暂停播放，此时对应 fl_playerStatus 为 Player_Pausing
 可通过 fl_start 方法继续播放
 */
- (void)fl_pause;

/**
 停止播放，此时进度会重置为0，此时对应 fl_playerStatus 为 Player_Stoping
 */
- (void)fl_stop;


/**
 设置当前的播放进度，此方法会在seek完毕后会立即播放

 @param progress seek进度百分比（0-1）
 @param complete 完成回调，seek后执行
 */
- (void)fl_seekToProgress:(CGFloat)progress complete:(void (^)(BOOL finished))complete;

/**
 设置当前的播放进度

 @param progress progress seek进度百分比（0-1）
 @param startImmediately 是否seek完毕后进行播放
 @param complete 完成回调，seek完毕后执行
 */
- (void)fl_seekToProgress:(CGFloat)progress andStartImmediately:(BOOL)startImmediately complete:(void (^)(BOOL finished))complete;

@end

