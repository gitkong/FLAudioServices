//
//  NSObject+Model.m
//  OC_Demo
//
//  Created by clarence on 16/8/30.
//  Copyright © 2016年 clarence. All rights reserved.
//

#import "NSObject+Model.h"
#import <objc/runtime.h>

@implementation NSObject (Model)
/**
 *  自动生成属性申明Code
 *
 *  @param dict 传入的字典
 */
+ (void)fl_propertyCodeWithDictionary:(NSDictionary *)dict{
    NSMutableString *strM = [NSMutableString string];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        NSString *str;
        
        NSLog(@"%@",[obj class]);
        if ([obj isKindOfClass:NSClassFromString(@"__NSCFString")] || [obj isKindOfClass:NSClassFromString(@"NSTaggedPointerString")] || [obj isKindOfClass:NSClassFromString(@"__NSCFConstantString")]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, copy) NSString *%@;",key];
        }
        if ([obj isKindOfClass:NSClassFromString(@"__NSCFNumber")]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, assign) int %@;",key];
        }
        if ([obj isKindOfClass:NSClassFromString(@"__NSCFArray")]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, copy) NSArray *%@;",key];
        }
        if ([obj isKindOfClass:NSClassFromString(@"__NSCFDictionary")]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, copy) NSDictionary *%@;",key];
        }
        if ([obj isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
            str = [NSString stringWithFormat:@"@property (nonatomic, assign) BOOL %@;",key];
        }
        
        [strM appendFormat:@"\n%@\n",str];
    }];
    
    NSLog(@"%@",strM);
}

+ (void)fl_printAllProperties {
    unsigned  int count = 0;
    unsigned int propertyCount = 0;
    Ivar *members = class_copyIvarList(self,&count);
    
    objc_property_t * properties = class_copyPropertyList(self, &propertyCount);
    
    NSMutableArray * propertyNames = [NSMutableArray array];
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char * propertyName = property_getName(property);
        [propertyNames addObject:[NSString stringWithUTF8String:propertyName]];
    }
    
    
    for (int i = 0; i < count; i++)
    {
        Ivar var = members[i];
        const char *memberName = ivar_getName(var);
        
        const char *memberType = ivar_getTypeEncoding(var);
        
        NSString *nolineName = [[NSString stringWithUTF8String:memberName] stringByReplacingOccurrencesOfString:@"_" withString:@""];
        for (NSString *propertyName in propertyNames) {
            if ([propertyName isEqualToString:nolineName]) {
                memberName = [nolineName UTF8String];
            }
        }
        NSLog(@"name = %@ ; type = %@",[NSString stringWithUTF8String:memberName],[NSString stringWithUTF8String:memberType]);
    }
    
    free(properties);
    free(members);
}


+ (instancetype)fl_modelWithDict:(NSDictionary *)dict
{
    // 思路：遍历模型中所有属性-》使用运行时
    
    // 0.创建对应的对象
    id objc = [[self alloc] init];
    
    // 1.利用runtime给对象中的成员属性赋值
    
    // class_copyIvarList:获取类中的所有成员属性
    // Ivar：成员属性的意思
    // 第一个参数：表示获取哪个类中的成员属性
    // 第二个参数：表示这个类有多少成员属性，传入一个Int变量地址，会自动给这个变量赋值
    // 返回值Ivar *：指的是一个ivar数组，会把所有成员属性放在一个数组中，通过返回的数组就能全部获取到。
    /* 类似下面这种写法
     
     Ivar ivar;
     Ivar ivar1;
     Ivar ivar2;
     // 定义一个ivar的数组a
     Ivar a[] = {ivar,ivar1,ivar2};
     
     // 用一个Ivar *指针指向数组第一个元素
     Ivar *ivarList = a;
     
     // 根据指针访问数组第一个元素
     ivarList[0];
     
     */
    unsigned int count;
    
    // 获取类中的所有成员属性
    Ivar *ivarList = class_copyIvarList(self, &count);
    
    for (int i = 0; i < count; i++) {
        // 根据角标，从数组取出对应的成员属性
        Ivar ivar = ivarList[i];
        
        // 获取成员属性名
        NSString *name = [NSString stringWithUTF8String:ivar_getName(ivar)];
        
        // 处理成员属性名->字典中的key
        // 从第一个角标开始截取
        NSString *key = [name substringFromIndex:1];
        
        // 根据成员属性名去字典中查找对应的value
        id value = dict[key];
        
        // 二级转换:如果字典中还有字典，也需要把对应的字典转换成模型
        // 判断下value是否是字典
        if ([value isKindOfClass:[NSDictionary class]]) {
            // 字典转模型
            // 获取模型的类对象，调用modelWithDict
            // 模型的类名已知，就是成员属性的类型
            
            // 获取成员属性类型
            NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
            // 生成的是这种@"@\"User\"" 类型 -》 @"User"  在OC字符串中 \" -> "，\是转义的意思，不占用字符
            // 裁剪类型字符串
            NSRange range = [type rangeOfString:@"\""];
            
            type = [type substringFromIndex:range.location + range.length];
            
            range = [type rangeOfString:@"\""];
            
            // 裁剪到哪个角标，不包括当前角标
            type = [type substringToIndex:range.location];
            
            
            // 根据字符串类名生成类对象
            Class modelClass = NSClassFromString(type);
            
            
            if (modelClass) { // 有对应的模型才需要转
                
                // 把字典转模型
                value  =  [modelClass fl_modelWithDict:value];
            }
            
            
        }
        
        // 三级转换：NSArray中也是字典，把数组中的字典转换成模型.
        // 判断值是否是数组
        if ([value isKindOfClass:[NSArray class]]) {
            // 判断对应类有没有实现字典数组转模型数组的协议
            if ([self respondsToSelector:@selector(arrayContainModelClass)]) {
                
                // 转换成id类型，就能调用任何对象的方法
                id idSelf = self;
                
                // 获取数组中字典对应的模型
                NSString *type =  [idSelf arrayContainModelClass][key];
                
                // 生成模型
                Class classModel = NSClassFromString(type);
                NSMutableArray *arrM = [NSMutableArray array];
                // 遍历字典数组，生成模型数组
                for (NSDictionary *dict in value) {
                    // 字典转模型
                    id model =  [classModel fl_modelWithDict:dict];
                    [arrM addObject:model];
                }
                
                // 把模型数组赋值给value
                value = arrM;
                
            }
        }
        
        
        if (value) { // 有值，才需要给模型的属性赋值
            // 利用KVC给模型中的属性赋值
            [objc setValue:value forKey:key];
        }
        
    }
    
    return objc;
}

+ (id)arrayContainModelClass {
    
    NSMutableDictionary *dictM = [[NSMutableDictionary alloc] init];
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for(int i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        
        NSString *key = [NSString stringWithFormat:@"%s", property_getName(property)];
        NSString *value = [NSString stringWithFormat:@"%s", property_getAttributes(property)];
        
        // 裁剪
        NSRange range = [value rangeOfString:@"\""];
        value = [value substringFromIndex:range.location + range.length];
        range = [value rangeOfString:@"\""];
        value = [value substringToIndex:range.location];
        
        [dictM setValue:value forKey:key];
        
    }
    free(properties);
    return dictM;
}


@end
