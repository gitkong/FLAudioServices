/*
 * author 孔凡列
 *
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 喜欢就给个like 和 star 喔~
 */

#import <Foundation/Foundation.h>

@interface FLTimer : NSObject
/**
 *  @author 孔凡列, 16-10-11 07:10:28
 *
 *  创建定时器，主线程执行block，注意block强引用问题
 *
 *  @param interval 执行间隔
 *  @param handler  block回调
 *  @param repeat   是否重复执行block回调
 *
 *  @return 返回时间对象
 */
+ (instancetype)fl_timer:(NSTimeInterval)interval handel:(void(^)(FLTimer *timer))handler repeat:(BOOL)repeat;
/**
 *  @author 孔凡列, 16-10-11 07:10:37
 *
 *  创建定时器，自定义线程执行block，注意block强引用问题
 *
 *  @param interval 执行间隔
 *  @param queue    自定义县城
 *  @param handler  block回调
 *  @param repeat   是否重复执行回调
 *
 *  @return 返回时间对象
 */
+ (instancetype)fl_timer:(NSTimeInterval)interval queue:(dispatch_queue_t)queue handel:(void(^)(FLTimer *timer))handler repeat:(BOOL)repeat;
/**
 *  @author 孔凡列, 16-10-11 07:10:38
 *
 *  销毁定时器
 */
- (void)fl_invalidate;

@end
