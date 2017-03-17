//
//  ViewController.m
//  FLAudioDemo
//
//  Created by clarence on 17/1/12.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "FLAudioServices.h"
#import "DemoViewController.h"

@interface ViewController ()
@property (nonatomic,strong)FLAudioRecorder *recoder;
@property (strong, nonatomic) FLAudioPlayer *player;//播放器对象
@end

@implementation ViewController

/**
 *  @author gitKong
 *
 *  开始前先定义一个结构体，管理音频队列
 */

//static const int fl_NumberBuffers = 3;// 缓冲区个数，官方建议三个最好
//struct FLPlayerState {
//    // 音频数据格式
//    AudioStreamBasicDescription   fl_DataFormat;
//    // 音频队列对象
//    AudioQueueRef                 fl_Queue;
//    // 存储音频队列缓冲区的数组对象
//    AudioQueueBufferRef           fl_Buffers[fl_NumberBuffers];
//    // 要播放的音频文件对象
//    AudioFileID                   fl_AudioFile;
//    // 缓冲区的大小
//    UInt32                        fl_bufferByteSize;
//    // 数据包索引
//    SInt64                        fl_CurrentPacket;
//    // 回调时需要读取的数据包数
//    UInt32                        fl_NumPacketsToRead;
//    // 对于VBR音频数据，正在播放的文件的数据包描述数组。 对于CBR数据，此字段的值为NULL。
//    AudioStreamPacketDescription  *fl_PacketDescs;
//    // 音频队列是否正在运行
//    bool                          fl_IsRunning;
//};
//
///**
// *  @author gitKong
// *
// *  回调函数
// */
//static void fl_handleOutputBuffer (
//                                // 上面自定义的结构体
//                                void                *aqData,
//                                // 管理这个回调的缓冲队列
//                                AudioQueueRef       inAQ,
//                                // 存储音频队列缓冲区的数组对象
//                                AudioQueueBufferRef inBuffer
//                                ) {
//    struct FLPlayerState *pAqData = aqData;        // 1
//    if (pAqData->fl_IsRunning == 0) return;                     // 2
//    UInt32 numBytesReadFromFile;                              // 3
//    UInt32 numPackets = pAqData->fl_NumPacketsToRead;           // 4
//    AudioFileReadPackets (
//                          pAqData->fl_AudioFile,
//                          false,
//                          &numBytesReadFromFile,
//                          pAqData->fl_PacketDescs,
//                          pAqData->fl_CurrentPacket,
//                          &numPackets,
//                          inBuffer->mAudioData
//                          );
//    if (numPackets > 0) {                                     // 5
//        inBuffer->mAudioDataByteSize = numBytesReadFromFile;  // 6
//        AudioQueueEnqueueBuffer (
//                                 pAqData->fl_Queue,
//                                 inBuffer,
//                                 (pAqData->fl_PacketDescs ? numPackets : 0),
//                                 pAqData->fl_PacketDescs
//                                 );
//        pAqData->fl_CurrentPacket += numPackets;                // 7
//    } else {
//        AudioQueueStop (
//                        pAqData->fl_Queue,
//                        false
//                        );
//        pAqData->fl_IsRunning = false;
//    }
//}

/**
 *  @author gitKong
 *
 *  自定义结构体
 */
static const int kNumberBuffers = 3;                              // 1
struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
    AudioFileID                   mAudioFile;                     // 5
    UInt32                        bufferByteSize;                 // 6
    SInt64                        mCurrentPacket;                 // 7
    UInt32                        mNumPacketsToRead;              // 8
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
    bool                          mIsRunning;                     // 10
    struct OpaqueAudioFileStreamID       *outAudioFileStream;
};
/**
 *  @author gitKong
 *
 *  回调函数
 */
static void HandleOutputBuffer (
                                void                *aqData,
                                AudioQueueRef       inAQ,
                                AudioQueueBufferRef inBuffer
                                ) {
#warning AQPlayerState
//    AQPlayerState *pAqData = (AQPlayerState *) aqData;        // 1
    struct AQPlayerState *pAqData = aqData;                     // 1
    if (pAqData->mIsRunning == 0) return;                     // 2
    UInt32 numBytesReadFromFile;                              // 3
    UInt32 numPackets = pAqData->mNumPacketsToRead;           // 4
    AudioFileReadPackets (
                          pAqData->mAudioFile,
                          false,
                          &numBytesReadFromFile,
                          pAqData->mPacketDescs,
                          pAqData->mCurrentPacket,
                          &numPackets,
                          inBuffer->mAudioData
                          );
    if (numPackets > 0) {                                     // 5
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;  // 6
        AudioQueueEnqueueBuffer (
                                 pAqData->mQueue,
                                 inBuffer,
                                 (pAqData->mPacketDescs ? numPackets : 0),
                                 pAqData->mPacketDescs
                                 );
        pAqData->mCurrentPacket += numPackets;                // 7 
    } else {
        AudioQueueStop (
                        pAqData->mQueue,
                        false
                        );
        pAqData->mIsRunning = false; 
    }
}

/**
 *  @author gitKong
 *
 *  获取播放音频队列缓冲区的大小
 */
void DeriveBufferSize (
#warning ASBDesc
                       AudioStreamBasicDescription ASBDesc,                            // 1
                       UInt32                      maxPacketSize,                       // 2
                       Float64                     seconds,                             // 3
                       UInt32                      *outBufferSize,                      // 4
                       UInt32                      *outNumPacketsToRead                 // 5
) {
    static const int maxBufferSize = 0x50000;                        // 6
    static const int minBufferSize = 0x4000;                         // 7
    
    if (ASBDesc.mFramesPerPacket != 0) {                             // 8
        Float64 numPacketsForTime =
        ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {                                                         // 9
        *outBufferSize =
        maxBufferSize > maxPacketSize ?
        maxBufferSize : maxPacketSize;
    }
    
    if (                                                             // 10
        *outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize
        )
        *outBufferSize = maxBufferSize;
    else {                                                           // 11
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;           // 12
}


void fl_AudioFileStream_PropertyListenerProc (
                            void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            AudioFileStreamPropertyFlags *	ioFlags){
    NSLog(@"hello world");
}

void fl_AudioFileStream_PacketsProc(
                                    void *							inClientData,
                                    UInt32							inNumberBytes,
                                    UInt32							inNumberPackets,
                                    const void *					inInputData,
                                    AudioStreamPacketDescription	*inPacketDescriptions){
    NSLog(@"fl_AudioFileStream_PacketsProc");
}


- (void)fl_openAudioFile:(NSString *)filePath{
    CFStringRef strRef = (__bridge CFStringRef)filePath;
#warning CFURLCreateFromFileSystemRepresentation 官方文档写这个 
    // CFURLPathStyle 不建议使用kCFURLHFSPathStyle。 使用HFS样式路径的Carbon文件管理器已被弃用。 HFS样式路径不可靠，因为它们可以随意引用多个卷（如果这些卷具有相同的卷名称）。 您应该尽可能使用kCFURLPOSIXPathStyle。
    CFURLRef audioFileURL =
    CFURLCreateWithFileSystemPath(NULL,
                                  strRef,
                                  kCFURLPOSIXPathStyle,
                                  YES
                                  );
    
    
//    CFURLRef audioFileURL = CFURLCreateWithString(NULL, strRef, NULL);
    
    struct AQPlayerState aqData;
    
    
    

    OSStatus result = AudioFileStreamOpen(&aqData, fl_AudioFileStream_PropertyListenerProc, fl_AudioFileStream_PacketsProc, 0, &aqData.outAudioFileStream);
    
    if (result == noErr) {
        NSLog(@"打开文件成功");
    }
    else{
        NSLog(@"打开文件失败");
        CFRelease (audioFileURL);
        return;
    }
    
    
    // 文件权限
    AudioFilePermissions fsRdPerm = kAudioFileReadWritePermission;
    result =
    AudioFileOpenURL (                                  // 2
                      audioFileURL,                                   // 3
                      fsRdPerm,                                       // 4
                      0,                                              // 5
                      &aqData.mAudioFile                              // 6
                      );
    
    if (result == noErr) {
        NSLog(@"打开文件成功");
    }
    else{
        NSLog(@"打开文件失败");
        CFRelease (audioFileURL);
        return;
    }
    
    CFRelease (audioFileURL);
    
    
    /**
     *  @author gitKong
     *
     *  获取文件的音频数据格式
     */
    UInt32 dataFormatSize = sizeof (aqData.mDataFormat);    // 1
    
    AudioFileGetProperty (                                  // 2
                          aqData.mAudioFile,                                  // 3
                          kAudioFilePropertyDataFormat,                       // 4
                          &dataFormatSize,                                    // 5
                          &aqData.mDataFormat                                 // 6
                          );
    
    /**
     *  @author gitKong
     *
     *  创建播放音频队列
     */
    AudioQueueNewOutput (                                // 1
                         &aqData.mDataFormat,                             // 2
                         HandleOutputBuffer,                              // 3
                         &aqData,                                         // 4
                         CFRunLoopGetCurrent (),                          // 5
                         kCFRunLoopCommonModes,                           // 6
                         0,                                               // 7
                         &aqData.mQueue                                   // 8
                         );
    
    
    /**
     *  @author gitKong
     *
     *  设置缓冲区大小和要读取的数据包数
     */
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    AudioFileGetProperty (                               // 1
                          aqData.mAudioFile,                               // 2
                          kAudioFilePropertyPacketSizeUpperBound,          // 3
                          &propertySize,                                   // 4
                          &maxPacketSize                                   // 5
                          );
    
    DeriveBufferSize (                                   // 6
                      aqData.mDataFormat,                              // 7
                      maxPacketSize,                                   // 8
                      0.5,                                             // 9
                      &aqData.bufferByteSize,                          // 10
                      &aqData.mNumPacketsToRead                        // 11
                      );
    
    /**
     *  @author gitKong
     *
     *  为包描述数组分配内存
     */
    bool isFormatVBR = (                                       // 1
                        aqData.mDataFormat.mBytesPerPacket == 0 ||
                        aqData.mDataFormat.mFramesPerPacket == 0
                        );
    
    if (isFormatVBR) {                                         // 2
        aqData.mPacketDescs =
        (AudioStreamPacketDescription*) malloc (
                                                aqData.mNumPacketsToRead * sizeof (AudioStreamPacketDescription)
                                                );
    } else {                                                   // 3
        aqData.mPacketDescs = NULL;
    }
    
    /**
     *  @author gitKong
     *
     *  设置回放音频队列的magic cookie
     */
    UInt32 cookieSize = sizeof (UInt32);                   // 1
    bool couldNotGetProperty =                             // 2
    AudioFileGetPropertyInfo (                         // 3
                              aqData.mAudioFile,                             // 4
                              kAudioFilePropertyMagicCookieData,             // 5
                              &cookieSize,                                   // 6
                              NULL                                           // 7
                              );
    
    if (!couldNotGetProperty && cookieSize) {              // 8
        char* magicCookie =
        (char *) malloc (cookieSize);
        
        AudioFileGetProperty (                             // 9
                              aqData.mAudioFile,                             // 10
                              kAudioFilePropertyMagicCookieData,             // 11
                              &cookieSize,                                   // 12
                              magicCookie                                    // 13
                              );
        
        AudioQueueSetProperty (                            // 14
                               aqData.mQueue,                                 // 15
                               kAudioQueueProperty_MagicCookie,               // 16
                               magicCookie,                                   // 17
                               cookieSize                                     // 18
                               );
        
        free (magicCookie);                                // 19
    }
    
    /**
     *  @author gitKong
     *
     *  分配和填充音频队列缓冲区
     */
    aqData.mCurrentPacket = 0;                                // 1
    
    for (int i = 0; i < kNumberBuffers; ++i) {                // 2
        AudioQueueAllocateBuffer (                            // 3
                                  aqData.mQueue,                                    // 4
                                  aqData.bufferByteSize,                            // 5
                                  &aqData.mBuffers[i]                               // 6
                                  );
        
        HandleOutputBuffer (                                  // 7
                            &aqData,                                          // 8
                            aqData.mQueue,                                    // 9
                            aqData.mBuffers[i]                                // 10
                            );
    }
    
    
    /**
     *  @author gitKong
     *
     *  设置音频队列回放增益
     */
    Float32 gain = 1.0;                                       // 1
    // Optionally, allow user to override gain setting here
    AudioQueueSetParameter (                                  // 2
                            aqData.mQueue,                                        // 3
                            kAudioQueueParam_Volume,                              // 4
                            gain                                                  // 5
                            );
    
    /**
     *  @author gitKong
     *
     *  开启并运行音频队列
     */
    
    aqData.mIsRunning = true;                          // 1
    
    AudioQueueStart (                                  // 2
                     aqData.mQueue,                                 // 3
                     NULL                                           // 4
                     );
    
    do {                                               // 5
        CFRunLoopRunInMode (                           // 6
                            kCFRunLoopDefaultMode,                     // 7
                            0.25,                                      // 8
                            false                                      // 9
                            );
    } while (aqData.mIsRunning);
    
    CFRunLoopRunInMode (                               // 10
                        kCFRunLoopDefaultMode,
                        1,
                        false
                        );
}


//- (void)viewDidLoad{
//    [super viewDidLoad];
//
//}
//
//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"MP3Sample" ofType:@"mp3"];
////    NSString *path = @"http://www.yaragroovy.cn/html/MP3Sample.mp3";
//    [self fl_openAudioFile:path];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.recoder = [[FLAudioRecorder alloc] init];
    [self.recoder fl_prepareToRecord];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.recoder fl_start:^{
        NSLog(@"start");
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recoder fl_stop:^(NSData *data) {
            NSLog(@"stop:%@",data);
            
        }];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.player = [[FLAudioPlayer alloc] initWithUrl:@"hTtp://ws.stream.qqmusic.qq.com/M500001VfvsJ21xFqb.mp3?guid=ffffffff82def4af4b12b3cd9337d5e7&uin=346897220&vkey=6292F51E1E384E061FF02C31F716658E5C81F5594D561F2E88B854E81CAAB7806D5E4F103E55D33C16F3FAC506D1AB172DE8600B37E43FAD&fromtag=46"];
        
        [self.player fl_start:nil];
    });
    
}

- (NSString *)fl_filePath{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"voice.caf"];
}


@end
