//
//  NSObject+Model.h
//  OC_Demo
//
//  Created by clarence on 16/8/30.
//  Copyright © 2016年 clarence. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Model)

/**
 *  自动生成属性申明Code
 *
 *  @param dict 传入的字典
 */
//+ (void)fl_propertyCodeWithDictionary:(NSDictionary *)dict;

// 打印所有属性以及其类型
/**
 *  @author 孔凡列, 16-08-28 01:08:48
 *
 *  只适合UIKit 框架的 类，NS开头的不行
 */
+ (void)fl_printAllProperties;

/**
 *  @author 孔凡列, 16-08-30 01:08:21
 *
 *  字典转模型
 *
 *  @param dict dict description
 *
 *  @return return value description
 */
+ (instancetype)fl_modelWithDict:(NSDictionary *)dict;

@end
