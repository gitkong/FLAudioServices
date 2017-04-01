/*
 * author 孔凡列
 *
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 微信公众号 原创技术分享
 * 喜欢就给个like 和 star 喔~
 */

#import <UIKit/UIKit.h>
@class FLSlider,FLSliderButton;
@protocol FLSliderDelegate <NSObject>
@optional
/**
 *  @author gitKong
 *
 *  开始拖动
 */
- (void)beginSlide:(FLSliderButton *)sliderBtn slider:(FLSlider *)slider;
/**
 *  @author gitKong
 *
 *  正在拖动
 */
- (void)sliding:(FLSliderButton *)sliderBtn slider:(FLSlider *)slider;
/**
 *  @author gitKong
 *
 *  结束拖动
 */
- (void)endSlide:(FLSliderButton *)sliderBtn slider:(FLSlider *)slider;

@end

@interface FLSlider : UIControl
/**
 *  @author gitKong
 *
 *  代理
 */
@property (nonatomic,weak)id<FLSliderDelegate> delegate;
/**
 *  @author gitKong
 *
 *  当前进度
 */
@property(nonatomic) float value;
/**
 *  @author gitKong
 *
 *  最小值
 */
@property(nonatomic) float minimumValue;
/**
 *  @author gitKong
 *
 *  最大值
 */
@property(nonatomic) float maximumValue;
/**
 *  @author gitKong
 *
 *  缓存进度值
 */
@property(nonatomic) float cacheValue;

/**
 *  @author gitKong
 *
 *  当前进度条的颜色，有默认颜色
 */
@property(nonatomic,strong) UIColor *minimumTrackTintColor;
/**
 *  @author gitKong
 *
 *  缓存进度条的颜色，有默认颜色
 */
@property(nonatomic,strong) UIColor *cacheTrackTintColor;
/**
 *  @author gitKong
 *
 *  总进度条颜色，有默认颜色
 */
@property(nonatomic,strong) UIColor *maximumTrackTintColor;
/**
 *  @author gitKong
 *
 *  设置拖拽的Thumb图片
 */
@property(nonatomic,strong) UIImage *thumbImage;

@end

@interface FLSliderButton : UIButton

@property (nonatomic,strong)UIImageView *iconImageView;

@end
