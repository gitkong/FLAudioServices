//
//  FLSlider.m
//  FLSliderDemo
//
//  Created by clarence on 16/12/8.
//  Copyright © 2016年 gitKong. All rights reserved.
//

#import "FLSlider.h"
static CGFloat fl_sliderButton_hegiht = 16.0f;
static CGFloat fl_slider_hegiht = 3.0f;

@interface FLSlider ()
/**
 *  @author gitKong
 *
 *  已播放进度条
 */
@property (nonatomic,strong)UIView *minimumTrackView;
/**
 *  @author gitKong
 *
 *  总进度条
 */
@property (nonatomic,strong)UIView *maximumTrackView;
/**
 *  @author gitKong
 *
 *  总进度条
 */
@property (nonatomic,strong)UIView *cacheTrackView;
/**
 *  @author gitKong
 *
 *  滑动按钮
 */
@property (nonatomic,strong)FLSliderButton *sliderButton;

@property (nonatomic,assign)CGFloat minimumTrackViewWidth;
@property (nonatomic,assign)CGFloat cacheTrackViewWidth;
@property (nonatomic,assign)CGFloat sliderButtonCenterX;

@end

@implementation FLSlider{
    CGPoint _lastPoint;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews{
    [self addSubview:self.maximumTrackView];
    [self addSubview:self.cacheTrackView];
    [self addSubview:self.minimumTrackView];
    
    [self addSubview:self.sliderButton];
    
    [self defaultSetting];
    
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self initFrame];
}

- (void)defaultSetting{
    self.value = 0.0f;
    self.minimumValue = 0.0f;
    self.maximumValue = 1.0f;
    self.backgroundColor = [UIColor clearColor];
    self.minimumTrackView.backgroundColor = [UIColor colorWithRed:58 / 256.0 green:142 / 256.0 blue:245 / 256.0 alpha:1];
    self.maximumTrackView.backgroundColor = [UIColor whiteColor];
    self.cacheTrackView.backgroundColor = [UIColor orangeColor];
}

- (void)initFrame{
    CGFloat trackViewX = fl_sliderButton_hegiht * 0.5;
    CGFloat trackViewY = (self.frame.size.height - fl_slider_hegiht ) / 2;
    CGFloat trackViewWidth = self.frame.size.width - fl_sliderButton_hegiht;
    self.maximumTrackView.frame = CGRectMake(trackViewX, trackViewY, trackViewWidth, fl_slider_hegiht);
    self.minimumTrackView.frame = CGRectMake(trackViewX, trackViewY, self.minimumTrackViewWidth, fl_slider_hegiht);
    self.cacheTrackView.frame = CGRectMake(trackViewX, trackViewY, self.cacheTrackViewWidth, fl_slider_hegiht);
    self.sliderButton.frame = CGRectMake(0, trackViewY, self.frame.size.height, self.frame.size.height);
    CGPoint center = self.sliderButton.center;
    center.x = self.sliderButtonCenterX ? self.sliderButtonCenterX : self.maximumTrackView.frame.origin.x;
    center.y = self.minimumTrackView.center.y;
    self.sliderButton.center = center;
    _lastPoint = center;
}


- (void) dragMoving: (UIButton *)btn withEvent:(UIEvent *)event{
    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
    CGFloat offsetX = point.x - _lastPoint.x;
    CGPoint tempPoint = CGPointMake(btn.center.x + offsetX, btn.center.y);
    
    // 得到进度值
    CGFloat progressValue = (tempPoint.x - self.maximumTrackView.frame.origin.x) * 1.0f / self.maximumTrackView.frame.size.width;
    
    [self setValue:progressValue animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(sliding:slider:)]) {
        [self.delegate sliding:self.sliderButton slider:self];
    }
    
    
}

// 开始拖动
- (void)beiginSliderScrubbing{
    NSLog(@"begin");
    if ([self.delegate respondsToSelector:@selector(beginSlide:slider:)]) {
        [self.delegate beginSlide:self.sliderButton slider:self];
    }
}
// 结束拖动
- (void)endSliderScrubbing{
    NSLog(@"end");
    if ([self.delegate respondsToSelector:@selector(endSlide:slider:)]) {
        [self.delegate endSlide:self.sliderButton slider:self];
    }
}

- (void)setValue:(float)value animated:(BOOL)animated{
    _value = value;
    [self layoutSubviews];
    CGFloat finishValue = self.maximumTrackView.frame.size.width * value;
    CGPoint tempPoint = self.sliderButton.center;
    tempPoint.x =  self.maximumTrackView.frame.origin.x + finishValue;
    
    if (tempPoint.x >= self.maximumTrackView.frame.origin.x &&
        tempPoint.x <= (self.frame.size.width - (fl_sliderButton_hegiht * 0.5))){
        _lastPoint = tempPoint;
        // 记录
        self.sliderButtonCenterX = tempPoint.x;
        self.minimumTrackViewWidth = tempPoint.x;
        // 重新布局
        [self layoutSubviews];
    }
    if (tempPoint.x <= self.maximumTrackView.frame.origin.x) {
        if (_minimumValue) {
            _value = _minimumValue;
        }
        else{
            _value = 0.0;
        }
    }
    else if(tempPoint.x >= self.frame.size.width - (fl_sliderButton_hegiht * 0.5)){
        if (_maximumValue) {
            _value = _maximumValue;
        }
        else{
            _value = 1.0;
        }
    }
}

- (void)setThumbImage:(nullable UIImage *)image forState:(UIControlState)state{
    _thumbImage = image;
    self.sliderButton.iconImageView.image = image;
}



#pragma mark -- Setter & Getter

- (void)setValue:(float)value{
    [self setValue:value animated:NO];
}

- (void)setCacheValue:(float)cacheValue{
    _cacheValue = cacheValue;
    [self layoutSubviews];
    self.cacheTrackViewWidth = self.maximumTrackView.frame.size.width * cacheValue;
    [self layoutSubviews];
}

- (void)setThumbImage:(UIImage *)thumbImage{
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
}

- (void)setMinimumValue:(float)minimumValue{
    _minimumValue = minimumValue;
}

- (void)setMaximumValue:(float)maximumValue{
    _maximumValue = maximumValue;
}

- (void)setCacheTrackTintColor:(UIColor *)cacheTrackTintColor{
    _cacheTrackTintColor = cacheTrackTintColor;
    self.cacheTrackView.backgroundColor = cacheTrackTintColor;
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor{
    _minimumTrackTintColor = minimumTrackTintColor;
    self.minimumTrackView.backgroundColor = minimumTrackTintColor;
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor{
    _maximumTrackTintColor = maximumTrackTintColor;
    self.maximumTrackView.backgroundColor = maximumTrackTintColor;
}

- (UIView *)minimumTrackView{
    if (_minimumTrackView == nil) {
        _minimumTrackView = [[UIView alloc] init];
    }
    return _minimumTrackView;
}

- (UIView *)maximumTrackView{
    if (_maximumTrackView == nil) {
        _maximumTrackView = [[UIView alloc] init];
    }
    return _maximumTrackView;
}

- (UIView *)cacheTrackView{
    if (_cacheTrackView == nil) {
        _cacheTrackView = [[UIView alloc] init];
    }
    return _cacheTrackView;
}

- (UIButton *)sliderButton{
    if (_sliderButton == nil) {
        _sliderButton = [[FLSliderButton alloc] init];
        [_sliderButton addTarget:self action:@selector(beiginSliderScrubbing) forControlEvents:UIControlEventTouchDown];
        [_sliderButton addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchCancel];
        [_sliderButton addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [_sliderButton addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpInside];
        [_sliderButton addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _sliderButton;
}

@end


@implementation FLSliderButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initImageView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initImageView];
    }
    return self;
}

- (void)initImageView{
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.backgroundColor = [UIColor whiteColor];
    _iconImageView.layer.cornerRadius = fl_sliderButton_hegiht * 0.5;
    _iconImageView.layer.masksToBounds = YES;
    [self addSubview:_iconImageView];
    
    [self layoutSubviews];
    
    
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _iconImageView.frame = CGRectMake((self.frame.size.width - fl_sliderButton_hegiht) * 0.5,
                                      0.5 * (self.frame.size.height - fl_sliderButton_hegiht),
                                      fl_sliderButton_hegiht, fl_sliderButton_hegiht);
}

@end
