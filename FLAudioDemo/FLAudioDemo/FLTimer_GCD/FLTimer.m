//
//  FLTimer.m
//  FLTimerDemo
//
//  Created by clarence on 16/10/11.
//  Copyright © 2016年 clarence. All rights reserved.
//

#import "FLTimer.h"

@interface FLTimer ()
/**
 *  @author 孔凡列, 16-09-21 08:09:06
 *
 *  保存timer对象
 */
@property (nonatomic,weak)dispatch_source_t timer;
@end

@implementation FLTimer

+ (instancetype)fl_timer:(NSTimeInterval)interval queue:(dispatch_queue_t)queue handel:(void(^)(FLTimer *timer))handler repeat:(BOOL)repeat{
    FLTimer *fl_timer = [[self alloc] init];
    // 创建定时器对象
    __block dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    /**
     *  @author 孔凡列, 16-09-21 08:09:06
     *
     *  internal和leeway参数分别表示Timer的间隔时间和精度。类型都是uint64_t。间隔时间的单位竟然是纳秒。可以借助预定义的NSEC_PER_SEC宏，比如如果间隔时间是两秒的话，那interval参数就是：2 * NSEC_PER_SEC。leeway就是精度参数，代表系统可以延时的时间间隔，最高精度当然就传0。
     */
    
    // 内部计数器
    __block NSTimeInterval counter;
    // 设置时间间隔
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, 0);
    // 定时器回调
    dispatch_source_set_event_handler(timer, ^{
        /**
         *  @author 孔凡列, 16-09-21 08:09:06
         *
         *  关键一步：block强引用fl_timer,避免ARC情况下提前释放
         */
        fl_timer.timer = timer;
        // 实现重复执行回调
        if (!repeat){
            if (counter >= interval) {
                dispatch_source_cancel(timer);
                timer = nil;
            }
            else{
                counter ++;
                handler(fl_timer);
            }
        }
        else{
            handler(fl_timer);
        }
    });
    if (timer) {
        // 开启定时任务
        dispatch_resume(timer);
    }
    return fl_timer;

}

+ (instancetype)fl_timer:(NSTimeInterval)interval handel:(void(^)(FLTimer *timer))handler repeat:(BOOL)repeat{
    return [self fl_timer:interval queue:dispatch_get_main_queue() handel:handler repeat:repeat];
}

- (void)fl_invalidate{
    if(self.timer) {
        // 挂起任务
        dispatch_suspend(self.timer);
        // 取消任务
        dispatch_source_cancel(self.timer);
        // 防止野指针
        self.timer = nil;
    }
}

@end
