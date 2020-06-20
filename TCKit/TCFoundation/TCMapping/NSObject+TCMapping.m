//
//  NSObject+TCMapping.m
//  TCKit
//
//  Created by dake on 13-12-29.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import "NSObject+TCMapping.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIGeometry.h>

#import "TCMappingMeta.h"
#import "UIColor+TCUtilities.h"
#import "NSString+TCHelper.h"


#if ! __has_feature(objc_arc)
#error this file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


#pragma mark -

static NSDateFormatter *tc_mapping_date_write_fmter(void)
{
    static NSDateFormatter *s_fmt = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_fmt = [[NSDateFormatter alloc] init];
        s_fmt.dateStyle = NSDateFormatterNoStyle;
        s_fmt.timeStyle = NSDateFormatterNoStyle;
    });
    
    return s_fmt;
}

NSNumberFormatter *tc_mapping_number_fmter(void)
{
    static NSNumberFormatter *s_fmt = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_fmt = [[NSNumberFormatter alloc] init];
        s_fmt.numberStyle = NSNumberFormatterDecimalStyle;
    });
    
    return s_fmt;
}


#pragma mark -

NS_INLINE Class classForType(id type, id value)
{
    if (nil == type) {
        return Nil;
    }
    
    if (class_isMetaClass(object_getClass(type))) {
        return type;
    } else if ([type isKindOfClass:NSString.class]) {
        return NSClassFromString(type);
    }
    
    return Nil;
}

NS_INLINE NSDictionary<NSString *, NSString *> *nameMappingDicFor(NSDictionary *inputMappingDic, NSArray<NSString *> *sysWritableProperties)
{
    if (inputMappingDic.count < 1) {
        return [NSDictionary dictionaryWithObjects:sysWritableProperties forKeys:sysWritableProperties];
    }
    
    // filter out readonly property
    NSMutableDictionary *readOnlyInput = inputMappingDic.mutableCopy;
    [readOnlyInput removeObjectsForKeys:sysWritableProperties];
    NSDictionary *writableInput = nil;
    if (readOnlyInput.count > 0) {
        NSMutableDictionary *dic = inputMappingDic.mutableCopy;
        [dic removeObjectsForKeys:readOnlyInput.allKeys];
        writableInput = dic;
    } else {
        writableInput = inputMappingDic;
    }
    
    NSMutableDictionary *tmpDic = [NSMutableDictionary dictionaryWithObjects:sysWritableProperties forKeys:sysWritableProperties];
    [tmpDic addEntriesFromDictionary:writableInput];
    inputMappingDic = tmpDic;
    
    return inputMappingDic;
}

NS_INLINE NSValue *mappingNSValueWithString(NSString *value, __unsafe_unretained TCMappingMeta *meta)
{
    id ret = nil;
    
    switch (tc_typeForInfo(meta->_info)) {
        case kTCEncodingTypeCGPoint:
            // "{x,y}"
            ret = [NSValue valueWithCGPoint:CGPointFromString(value)];
            break;
            
        case kTCEncodingTypeCGVector:
            // "{dx, dy}"
            ret = [NSValue valueWithCGVector:CGVectorFromString(value)];
            break;
            
        case kTCEncodingTypeCGSize:
            // "{w, h}"
            ret = [NSValue valueWithCGSize:CGSizeFromString(value)];
            break;
            
        case kTCEncodingTypeCGRect:
            // "{{x,y},{w, h}}"
            ret = [NSValue valueWithCGRect:CGRectFromString(value)];
            break;
            
        case kTCEncodingTypeCGAffineTransform:
            // "{a, b, c, d, tx, ty}"
            ret = [NSValue valueWithCGAffineTransform:CGAffineTransformFromString(value)];
            break;
            
        case kTCEncodingTypeUIEdgeInsets:
            // "{top, left, bottom, right}"
            ret = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsFromString(value)];
            break;
            
        case kTCEncodingTypeUIOffset:
            // "{horizontal, vertical}"
            ret = [NSValue valueWithUIOffset:UIOffsetFromString(value)];
            break;
            
        case kTCEncodingTypeNSRange:
            // "{location, length}"
            ret = [NSValue valueWithRange:NSRangeFromString(value)];
            break;
            
        default:
            break;
    }
    
    NSCAssert(nil != ret, @"property type %@ doesn't match value type %@", meta->_typeName, NSStringFromClass(value.class));
    return ret;
}

//  UIColor <- {r:0~1, g:0~1, b:0~1, a:0~1}, {rgb:0x322834}, {rgba:0x12345678}, {argb:0x12345678}
NS_INLINE UIColor *valueForUIColor(NSDictionary *dic, Class klass)
{
    static NSString *const rgbKey = @"rgb";
    static NSString *const rgbaKey = @"rgba";
    static NSString *const argbKey = @"argb";
    
    static NSString *const rKey = @"r";
    static NSString *const gKey = @"g";
    static NSString *const bKey = @"b";
    static NSString *const aKey = @"a";
    
    NSArray *keys = dic.allKeys;
    
    if ([keys containsObject:rgbKey]) {
        NSNumber *rgb = [dic valueForKeyExceptNull:rgbKey];
        return nil != rgb ? RGBHex(rgb.unsignedIntValue) : nil;
        
    } else if ([keys containsObject:rgbaKey]) {
        NSNumber *rgba = [dic valueForKeyExceptNull:rgbaKey];
        return nil != rgba ? RGBHex(rgba.unsignedIntValue) : nil;
        
    } else if ([keys containsObject:argbKey]) {
        NSNumber *argb = [dic valueForKeyExceptNull:argbKey];
        return nil != argb ? RGBHex(argb.unsignedIntValue) : nil;
        
    } else {
        NSNumber *r = [dic valueForKeyExceptNull:rKey];
        NSNumber *g = [dic valueForKeyExceptNull:gKey];
        NSNumber *b = [dic valueForKeyExceptNull:bKey];
        NSNumber *a = [dic valueForKeyExceptNull:aKey];
        
        if (nil != r ||
            nil != g ||
            nil != b ||
            nil != a) {
            
            return [UIColor colorWithRed:(CGFloat)r.doubleValue green:(CGFloat)g.doubleValue blue:(CGFloat)b.doubleValue alpha:nil != a ? (CGFloat)a.doubleValue : 1.0f];
        }
    }
    
    return nil;
}

static id valueForBaseTypeOfProperty(id value, TCMappingMeta *meta, TCMappingOption *option, Class curClass)
{
    if (nil == meta) {
        return value;
    }
    
    id ret = nil;
    TCEncodingType type = tc_typeForInfo(meta->_info);
    if (tc_isObjForInfo(meta->_info)) {
        __unsafe_unretained Class klass = meta->_typeClass;
        
        switch (type) {
            case kTCEncodingTypeNSString: { // NSString <- non NSString
                if ([value isKindOfClass:NSString.class]) {
                    if ([value isKindOfClass:klass]) {
                        ret = value;
                    } else {
                        ret = [klass stringWithString:value];
                    }
                } else {
                    NSCAssert(nil == option || option.ignoreUndefineMapping, @"property %@ type %@ doesn't match value type %@", meta->_propertyName, meta->_typeName, NSStringFromClass([value class]));
                    ret = [klass stringWithFormat:@"%@", value];
                }
            
                break;
            }
                
            case kTCEncodingTypeNSDecimalNumber:
            case kTCEncodingTypeNSNumber: { // NSNumber <- NSString
                if ([value isKindOfClass:NSNumber.class]) {
                    if (type == kTCEncodingTypeNSDecimalNumber) {
                        if ([value isKindOfClass:klass]) {
                            ret = value;
                        } else {
                            ret = [klass decimalNumberWithDecimal:((NSNumber *)value).decimalValue];
                        }
                    } else if ([value isKindOfClass:klass]) {
                        ret = value;
                    }
                } else {
                    NSCAssert(nil == option || option.ignoreUndefineMapping, @"property %@ type %@ doesn't match value type %@", meta->_propertyName, meta->_typeName, NSStringFromClass([value class]));
                    if ([value isKindOfClass:NSString.class] && ((NSString *)value).length > 0) {
                        if (type == kTCEncodingTypeNSNumber) {
                            ret = [tc_mapping_number_fmter() numberFromString:(NSString *)value];
                        } else {
                            ret = [NSDecimalNumber decimalNumberWithString:value];
                        }
                    }
                }
                
                break;
            }
                
            case kTCEncodingTypeNSDate: { // NSDate <- NSString
                if ([value isKindOfClass:NSString.class] && ((NSString *)value).length > 0) { // NSDate <- NSString
                    NSString *fmtStr = (NSString *)option.typeMapping[meta->_propertyName];
                    if (nil != fmtStr && (id)kCFNull != fmtStr && [fmtStr isKindOfClass:NSString.class] && fmtStr.length > 0) {
                        NSDateFormatter *fmt = tc_mapping_date_write_fmter();
                        fmt.dateFormat = fmtStr;
                        if (nil != option.setUpDateFormatter) {
                            option.setUpDateFormatter(NSSelectorFromString(meta->_propertyName), fmt);
                        }
                        
                        ret = [fmt dateFromString:value];
                        fmt.timeZone = nil;
                        fmt.dateFormat = nil;
                    } else if ([(NSString *)value rangeOfString:@"T"].location != NSNotFound) {
                        ret = [tcISODateFormatter() dateFromString:value];
                        if (nil == ret) {
                            NSDateFormatter *fmt = tc_mapping_date_write_fmter();
                            fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
                            ret = [fmt dateFromString:value];
                            fmt.timeZone = nil;
                            fmt.dateFormat = nil;
                        }

                    } else {
                        goto DATE_NUMBER;
                    }
                } else if ([value isKindOfClass:NSNumber.class])
                    DATE_NUMBER:
                { // NSDate <- timestamp
                    NSTimeInterval timestamp = ((NSNumber *)value).doubleValue;
                    BOOL ignore = timestamp <= 0;
                    if (!ignore && nil != option.secondSince1970) {
                        timestamp = option.secondSince1970(NSSelectorFromString(meta->_propertyName), timestamp, &ignore);
                    }
                    if (!ignore) {
                        ret = [klass dateWithTimeIntervalSince1970:timestamp];
                    }
                } else if ([value isKindOfClass:klass]) {
                    ret = value;
                }
                
                break;
            }
                
            case kTCEncodingTypeNSURL: { // NSURL <- NSString
                if ([value isKindOfClass:NSString.class]) {
                    if (((NSString *)value).length > 0) {
                        NSString *str = value;
                        if ([str hasPrefix:@"/"] || [str hasInCasePrefix:@"file://"]) {
                            ret = [klass fileURLWithPath:str];
                        } else {
                            ret = [klass URLWithString:str];
                        }
                        
                        if (nil == ret) {
                            str = [str stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
                            if ([str hasPrefix:@"/"] || [str hasInCasePrefix:@"file://"]) {
                                ret = [klass fileURLWithPath:str];
                            }
                            if (nil == ret) {
                                ret = [klass URLWithString:str];
                            }
                        }
     
                        NSCParameterAssert(ret);
                    }
                } else if ([value isKindOfClass:NSURL.class]) {
                    ret = value;
                }
                
                break;
            }
                
            case kTCEncodingTypeNSData: { // NSData <- NSString
                if ([value isKindOfClass:NSString.class]) {
                    if (((NSString *)value).length > 0) {
                        if ([curClass respondsToSelector:@selector(tc_transformDataFromString:)]) {
                            ret = [curClass tc_transformDataFromString:value];
                        } else {
                            ret = [[klass alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                        }
                    }
                } else if ([value isKindOfClass:NSData.class]) {
                    if ([value isKindOfClass:klass]) {
                        ret = value;
                    } else {
                        ret = [klass dataWithData:value];
                    }
                }
                
                break;
            }
                
            case kTCEncodingTypeNSValue: {
                if ([value isKindOfClass:klass] || tc_isTypeNeedSerialization(type)) {
                    ret = value;
                }

                break;
            }
                
            case kTCEncodingTypeNSAttributedString: {
                if ([value isKindOfClass:klass]) {
                    ret = value;
                } else if ([value isKindOfClass:NSString.class] && ((NSString *)value).length > 0) {
                    ret = [[klass alloc] initWithString:value];
                }
                
                NSCAssert(nil != ret, @"property %@ type %@ doesn't match value type %@", meta->_propertyName, meta->_typeName, nil == value ? nil : NSStringFromClass([value class]));
                break;
            }
                
            case kTCEncodingTypeBlock: {
                if ([value isKindOfClass:meta->_typeClass]) {
                    ret = value;
                }
                
                NSCAssert(nil != ret, @"property %@ type %@ doesn't match value type %@", meta->_propertyName, meta->_typeName, nil == value ? nil : NSStringFromClass([value class]));
                break;
            }
                
            case kTCEncodingTypeClass: {
                if (class_isMetaClass(object_getClass(value))) {
                    ret = value;
                } else if ([value isKindOfClass:NSString.class]) {
                    ret = NSClassFromString(value);
                }
                
                NSCAssert(nil != ret, @"property %@ type %@ doesn't match value type %@", meta->_propertyName, meta->_typeName, nil == value ? nil : NSStringFromClass([value class]));
                break;
            }
                
            case kTCEncodingTypeUIColor: {
                if ([value isKindOfClass:meta->_typeClass]) {
                    ret = value;
                } else if ([value isKindOfClass:NSString.class]) { // "0xff65ce00" or "#0xff65ce00"
                    if ([curClass respondsToSelector:@selector(tc_transformColorFromString:)]) {
                        ret = [curClass tc_transformColorFromString:value];
                    }
                } else if ([value isKindOfClass:NSNumber.class]) {
                    if ([curClass respondsToSelector:@selector(tc_transformColorFromHex:)]) {
                        ret = [curClass tc_transformColorFromHex:((NSNumber *)value).unsignedIntValue];
                    }
                }
                break;
            }
                
            case kTCEncodingTypeUIImage: {
                if ([value isKindOfClass:meta->_typeClass]) {
                    ret = value;
                } else if ([value isKindOfClass:NSString.class]) { // base64 string
                    if ([curClass respondsToSelector:@selector(tc_transformImageFromBase64String:)]) {
                        ret = [curClass tc_transformImageFromBase64String:value];
                    }
                } else if ([value isKindOfClass:NSData.class]) {
                    if ([curClass respondsToSelector:@selector(tc_transformImageFromData:)]) {
                        ret = [curClass tc_transformImageFromData:value];
                    }
                }
                break;
            }
                
            default:
                ret = value;
                break;
        }
    
    } else if (tc_isStructForInfo(meta->_info)) { // NSValue <- NSString
        NSValue *tmpValue = nil;
        if ([value isKindOfClass:NSValue.class]) {
            tmpValue = value;
        } else if (type != kTCEncodingTypeCommonStruct && type != kTCEncodingTypeBitStruct) {
            if ([value isKindOfClass:NSString.class] && ((NSString *)value).length > 0) {
                tmpValue = mappingNSValueWithString(value ,meta);
            }
        }
        
        if (nil != tmpValue && strcmp(tmpValue.objCType, meta->_typeName.UTF8String) == 0) {
            ret = tmpValue;
        }
        
        if (nil == ret) {
            ret = value;
        }
    } else {
        ret = value;
    }
    
    return ret;
}


#pragma mark - TCMapping

static id tc_mappingWithDictionary(NSDictionary *dataDic,
                                   TCMappingOption *opt,
                                   id<TCMappingPersistentContext> context,
                                   id target,
                                   Class curClass);


static NSArray *mappingArray(NSArray *value, NSString *property, Class curClass, TCMappingOption *option, Class klass, TCMappingOption *childOption, id<TCMappingPersistentContext> context)
{
    if (Nil == klass) {
        return nil;
    }
    NSMutableArray *arry = NSMutableArray.array;
    
    for (NSDictionary *dic in value) {
        if ([dic isKindOfClass:klass]) {
            [arry addObject:dic];
            
        } else if ([dic isKindOfClass:NSDictionary.class]) {
            
            id obj = tc_mappingWithDictionary(dic, childOption, context, nil, klass);
            if (nil != obj) {
                [arry addObject:obj];
            }
        } else {
            TCMappingMeta *meta = [TCMappingMeta metaForNSClass:klass];
            if (nil == meta) {
                break;
            }
            meta->_propertyName = property;
            id obj = valueForBaseTypeOfProperty(dic, meta, option, curClass);
            if (nil != obj) {
                [arry addObject:obj];
            }
        }
    }
    
    return (value.count > 0 && arry.count < 1) ? nil : arry.copy;
}

static id databaseInstanceWithValue(NSDictionary *value, NSDictionary *primaryKey, NSDictionary *nameDic, id<TCMappingPersistentContext> context, Class klass)
{
    // fill in primary keys
    NSMutableDictionary *pKeys = primaryKey.mutableCopy;
    for (NSString *pKey in pKeys) {
        id tmpValue = value[nameDic[pKey]];
        if (nil != tmpValue && tmpValue != (id)kCFNull) {
            pKeys[pKey] = tmpValue;
        }
        
        if (pKeys[pKey] == (id)kCFNull) {
            pKeys = nil;
            break;
        }
    }
    
    return [context instanceForPrimaryKey:pKeys class:klass];
}


@implementation NSObject (TCMapping)

+ (instancetype)valueForBaseTypeOfProperty:(id)value option:(TCMappingOption *)option
{
    Class curClass = self.class;
    return valueForBaseTypeOfProperty(value, [TCMappingMeta metaForNSClass:curClass], option, curClass);
}

+ (NSMutableArray *)tc_mappingWithArray:(NSArray *)arry
{
    return [self tc_mappingWithArray:arry context:nil];
}

+ (NSMutableArray *)tc_mappingWithArray:(NSArray *)arry context:(id<TCMappingPersistentContext>)context
{
    if (nil == arry || ![arry isKindOfClass:NSArray.class] || arry.count < 1) {
        return nil;
    }
    
    NSMutableArray *outArry = NSMutableArray.array;
    for (NSDictionary *dic in arry) {
        @autoreleasepool {
            id obj = tc_mappingWithDictionary(dic, nil, context, nil, self);
            if (nil != obj) {
                [outArry addObject:obj];
            }
        }
    }
    
    return outArry.count > 0 ? outArry : nil;
}

+ (instancetype)tc_mappingWithDictionary:(NSDictionary *)dic
{
    return tc_mappingWithDictionary(dic, nil, nil, nil, self);
}

+ (instancetype)tc_mappingWithDictionary:(NSDictionary<NSString *, id> *)dic option:(TCMappingOption *)option
{
    return tc_mappingWithDictionary(dic, option, nil, nil, self);
}

+ (instancetype)tc_mappingWithDictionary:(NSDictionary *)dic context:(id<TCMappingPersistentContext>)context
{
    return tc_mappingWithDictionary(dic, nil, context, nil, self);
}

- (void)tc_mappingWithDictionary:(NSDictionary *)dic
{
    tc_mappingWithDictionary(dic, nil, nil, self, self.class);
}

- (void)tc_mappingWithDictionary:(NSDictionary<NSString *, id> *)dic option:(TCMappingOption *)option
{
    tc_mappingWithDictionary(dic, option, nil, self, self.class);
}


#pragma mark - JSON file

+ (instancetype)tc_mappingWithDictionaryOfJSONFile:(NSString *)path error:(NSError * _Nullable __strong * _Nullable)error
{
    NSCParameterAssert(path);
    if (nil == path) {
        return nil;
    }
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path];
    if (nil == stream) {
        return nil;
    }
    [stream scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
    [stream open];
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithStream:stream
                                                          options:kNilOptions
                                                            error:&err];
    [stream close];
    if (NULL != error) {
        *error = err;
    }
    
    if ([dic isKindOfClass:NSDictionary.class] && [self isSubclassOfClass:NSDictionary.class]) {
        if ([self isSubclassOfClass:NSMutableDictionary.class]) {
            __unsafe_unretained Class klass = self;
            return [klass dictionaryWithDictionary:dic];
        }
        return dic;
    }
    
    return [self tc_mappingWithDictionary:dic];
}

+ (NSMutableArray *)tc_mappingWithArrayOfJSONFile:(NSString *)path error:(NSError * _Nullable __strong * _Nullable)error
{
    NSCParameterAssert(path);
    if (nil == path) {
        return nil;
    }
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path];
    if (nil == stream) {
        return nil;
    }
    [stream scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
    [stream open];
    NSError *err = nil;
    NSArray *arry = [NSJSONSerialization JSONObjectWithStream:stream
                                                      options:kNilOptions
                                                        error:&err];
    [stream close];
    if (NULL != error) {
        *error = err;
    }
    
    if ([arry isKindOfClass:NSArray.class] && [self isSubclassOfClass:NSArray.class]) {
        __unsafe_unretained Class klass = self;
        return [klass arrayWithArray:arry];
    }
    
    return [self tc_mappingWithArray:arry];
}


#pragma mark - async

NS_INLINE dispatch_queue_t tc_mappingQueue(void)
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}


+ (void)tc_asyncMappingWithArray:(NSArray *)arry finish:(void (^)(NSMutableArray *dataList))finish
{
    [self tc_asyncMappingWithArray:arry context:nil inQueue:nil finish:finish];
}

+ (void)tc_asyncMappingWithDictionary:(NSDictionary *)dic finish:(void (^)(__kindof NSObject * __nullable data))finish
{
    [self tc_asyncMappingWithDictionary:dic context:nil inQueue:nil finish:finish];
}

+ (void)tc_asyncMappingWithArray:(NSArray *)arry inQueue:(dispatch_queue_t)queue finish:(void (^)(NSMutableArray *dataList))finish
{
    [self tc_asyncMappingWithArray:arry context:nil inQueue:queue finish:finish];
}

+ (void)tc_asyncMappingWithDictionary:(NSDictionary<NSString *, id> *)dic inQueue:(dispatch_queue_t)queue finish:(void (^)(__kindof NSObject * __nullable data))finish
{
    [self tc_asyncMappingWithDictionary:dic context:nil inQueue:queue finish:finish];
}


+ (void)tc_asyncMappingWithDictionary:(NSDictionary *)dic context:(id<TCMappingPersistentContext>)context inQueue:(dispatch_queue_t)queue finish:(void (^)(__kindof NSObject * __nullable data))finish
{
    if (nil == finish) {
        return;
    }
    
    dispatch_async(queue ?: tc_mappingQueue(), ^{
        @autoreleasepool {
            id data = [self tc_mappingWithDictionary:dic context:context];
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(data);
            });
        }
    });
}

+ (void)tc_asyncMappingWithArray:(NSArray *)arry context:(id<TCMappingPersistentContext>)context inQueue:(dispatch_queue_t)queue finish:(void (^)(NSMutableArray *dataList))finish
{
    if (nil == finish) {
        return;
    }
    
    dispatch_async(queue ?: tc_mappingQueue(), ^{
        @autoreleasepool {
            NSMutableArray *dataList = [self tc_mappingWithArray:arry context:context];
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(dataList);
            });
        }
    });
}


- (void)tc_merge:(__kindof NSObject *)obj map:(id (^)(SEL prop, id left, id right))map
{
    NSCParameterAssert(obj);
    NSCParameterAssert(map);
    NSCAssert([obj isKindOfClass:self.class], @"obj must be kindof self class");
    
    __unsafe_unretained Class curClass = self.class;
    if (nil == obj || nil == map || ![obj isKindOfClass:curClass]) {
        return;
    }
    
    TCMappingOption *opt = [curClass respondsToSelector:@selector(tc_mappingOption)] ? [curClass tc_mappingOption] : nil;
    __unsafe_unretained NSDictionary<NSString *, TCMappingMeta *> *metaDic = tc_propertiesUntilRootClass(curClass, nil != opt ? opt.autoMapUntilRoot : YES);
    for (NSString *key in metaDic) {
        __unsafe_unretained TCMappingMeta *meta = metaDic[key];
        if (NULL == meta->_setter || NULL == meta->_getter) {
            continue;
        }
        
        id left = [self valueForKey:key meta:meta ignoreNSNull:NO];
        id right = [obj valueForKey:key meta:meta ignoreNSNull:NO];
        id value = map(meta->_getter, left, right);
        
        if (value != left) {
            [self setValue:value forKey:key meta:meta forPersistent:NO];
        }
    }
}

@end


static id tc_mappingWithDictionary(NSDictionary *dataDic,
                                   TCMappingOption *opt,
                                   id<TCMappingPersistentContext> context,
                                   id target,
                                   Class curClass)
{
    if (nil == dataDic || ![dataDic isKindOfClass:NSDictionary.class] || dataDic.count < 1) {
        return nil;
    }
    
    TCMappingOption *option = opt ?: ([curClass respondsToSelector:@selector(tc_mappingOption)] ? [curClass tc_mappingOption] : nil);
    __unsafe_unretained NSDictionary<NSString *, TCMappingMeta *> *const metaDic = tc_propertiesUntilRootClass(curClass, nil != opt ? opt.autoMapUntilRoot : YES);
    NSDictionary<NSString *, id> *const nameDic = nameMappingDicFor(option.nameMapping, metaDic.allKeys);
    
    NSObject *obj = target;
    BOOL const isNSNullValid = option.shouldMappingNSNull;
    NSDictionary *const typeDic = option.typeMapping;

    
    for (__unsafe_unretained NSString *property in nameDic) {
        if (nil == property || (id)kCFNull == property || (id)kCFNull == nameDic[property]) {
            continue;
        }
        
        __unsafe_unretained TCMappingMeta *meta = metaDic[property];
        if (tc_ignoreMappingForInfo(meta->_info) || NULL == meta->_setter) {
            continue;
        }
        
        NSObject *value = nil;
        id const mapProp = nameDic[property];
        TCMappingOption *propOpt = nil;
        if ([mapProp isKindOfClass:TCMappingOption.class]) {
            propOpt = mapProp;
        } else {
            value = dataDic[mapProp];
        }
        if (nil == value) {
            value = dataDic[property];
        }
        
        if (nil == value || ((id)kCFNull == value && !isNSNullValid)) {
            continue;
        }
        
        if ([value isKindOfClass:NSSet.class]) {
            value = ((NSSet *)value).allObjects;
        } else if ([value isKindOfClass:NSOrderedSet.class]) {
            value = ((NSOrderedSet *)value).array;
        } else if ([value isKindOfClass:NSHashTable.class]) {
            value = ((NSHashTable *)value).setRepresentation.allObjects;
        } else if ([value isKindOfClass:NSMapTable.class]) {
            value = ((NSMapTable *)value).dictionaryRepresentation;
        } 
        
        NSObject *const rawValue = value;
        
        TCEncodingType const type = tc_typeForInfo(meta->_info);
        BOOL const emptyCollectionToNSNull = option.mappingEmptyCollectionToNSNull;
        BOOL const mappingEmptyCollection = option.mappingEmptyCollection;
        
        if ([rawValue isKindOfClass:NSDictionary.class]) {
            __unsafe_unretained NSDictionary *const valueDic = (typeof(valueDic))rawValue;
            
            if (valueDic.count > 0) {
                if (type == kTCEncodingTypeNSDictionary) {
                    __unsafe_unretained Class dicItemClass = classForType(typeDic[property], valueDic);
                    if (Nil != dicItemClass) {
                        NSMutableDictionary *tmpDic = NSMutableDictionary.dictionary;
                        TCMappingMeta *valueMeta = nil;
                        for (id dicKey in valueDic) {
                            id tmpValue = nil;
                            id value = valueDic[dicKey];
                            if ([value isKindOfClass:NSDictionary.class]) {
                                tmpValue = tc_mappingWithDictionary(value, propOpt, context, nil, dicItemClass);
                            } else {
                                if (nil == valueMeta) {
                                    valueMeta = [TCMappingMeta metaForNSClass:dicItemClass];
                                    if (nil == valueMeta) {
                                        break;
                                    }
                                }
     
                                tmpValue = valueForBaseTypeOfProperty(value, valueMeta, propOpt, dicItemClass);
                            }

                            if (nil != tmpValue) {
                                tmpDic[dicKey] = tmpValue;
                            }
                        }
                        
                        value = tmpDic.count > 0 ? [meta->_typeClass dictionaryWithDictionary:tmpDic] : valueDic;
                        
                    } else if (nil != typeDic[property] && [TCMappingMeta isBlock:typeDic[property]]) {
                        TCValueMappingBlock block = typeDic[property];
                        value = block(value);
                        
                    } else if (valueDic.class != meta->_typeClass) {
                        value = [meta->_typeClass dictionaryWithDictionary:valueDic];
                    }
                    
                } else {
                    __unsafe_unretained Class klass = meta->_typeClass;
                    if (Nil == klass) {
                        klass = classForType(typeDic[property], valueDic);
                    }
                    
                    if ([klass isSubclassOfClass:UIColor.class]) {
                        value = valueForUIColor(valueDic, klass);
                    } else if ([TCMappingMeta isNSTypeForClass:klass]) {
                        value = nil;
                    } else {
                        value = tc_mappingWithDictionary(valueDic, propOpt, context, (nil == obj ? nil : [obj valueForKey:property]), klass);
                    }
                }
            } else if (!mappingEmptyCollection) {
                value = emptyCollectionToNSNull ? (id)kCFNull : nil;
            }
            
        } else if ([rawValue isKindOfClass:NSArray.class]) {
            __unsafe_unretained NSArray *const valueArry = (typeof(valueArry))rawValue;
            
            if (valueArry.count > 0) {
                if (Nil == meta->_typeClass || (type != kTCEncodingTypeNSArray && type != kTCEncodingTypeNSSet && type != kTCEncodingTypeNSOrderedSet)) {
                    value = nil;
                    
                } else {
                    TCValueMappingBlock typeBlock = nil;
                    __unsafe_unretained Class arryItemType = Nil;
                    
                    id properyType = typeDic[property];
                    if (nil != properyType) {
                        if (![TCMappingMeta isBlock:properyType]) {
                            arryItemType = classForType(properyType, nil);
                        } else {
                            typeBlock = properyType;
                        }
                    }
                    
                    if (nil != typeBlock) {
                        value = typeBlock(valueArry);
                    } else if (Nil != arryItemType) {
                        value = mappingArray(valueArry, property, curClass, option, arryItemType, propOpt, context);
                    }
                    
                    if (nil != value) {
                        if (type == kTCEncodingTypeNSArray) {
                            if (![value isKindOfClass:meta->_typeClass]) {
                                value = [meta->_typeClass arrayWithArray:(NSArray *)value];
                            }
                        } else if (type == kTCEncodingTypeNSSet){
                            value = [meta->_typeClass setWithArray:(NSArray *)value];
                        } else if (type == kTCEncodingTypeNSOrderedSet){
                            value = [meta->_typeClass orderedSetWithArray:(NSArray *)value];
                        }
                    }
                }
            } else if (!mappingEmptyCollection) {
                value = emptyCollectionToNSNull ? (id)kCFNull : nil;
            }
            
        } else if (rawValue != (id)kCFNull) {
            value = valueForBaseTypeOfProperty(rawValue, meta, option, curClass);
        }
        
        if (nil == value) {
            // undefineMapping
            TCValueMappingBlock block = option.undefineMapping[property];
            if (nil != block) {
                value = block(rawValue);
                if (nil == value) {
                    continue;
                }
            } else {
#ifdef DEBUG
                NSLog(@"undefine mapping for property:%@, value:%@\n try to fix it or impl `-[TCMappingOption undefineMapping]`", property, rawValue);
#endif
                continue;
            }
        }

        if (nil == obj && nil != value) {
            if (nil == context || ![context respondsToSelector:@selector(instanceForPrimaryKey:class:)]) {
                obj = [[curClass alloc] init];
            } else {
                obj = databaseInstanceWithValue(dataDic, option.primaryKey, nameDic, context, curClass);
            }
        }
        
        if (value == (id)kCFNull) {
            value = nil;
        }
        [obj setValue:value forKey:property meta:meta forPersistent:NO];
    }
    
    if (nil == obj || nil == option.mappingValidate) {
        return obj;
    }
    
    return option.mappingValidate(obj) ? obj : nil;
}


#pragma mark - NSDictionary+TCMapping

@implementation NSDictionary (TCMapping)

- (id)valueForKeyExceptNull:(NSString *)key
{
    NSCParameterAssert(key);
    id obj = self[key];
    return (id)kCFNull == obj ? nil : obj;
}

@end


#pragma mark - NSString+TC_NSNumber

@implementation NSString (TC_NSNumber)


- (char)charValue
{
    return (char)self.intValue;
}

- (unsigned char)unsignedCharValue
{
    return (unsigned char)self.intValue;
}

- (short)shortValue
{
    return (short)self.intValue;
}

- (unsigned short)unsignedShortValue
{
    return (unsigned short)self.intValue;
}

- (unsigned int)unsignedIntValue
{
    return (unsigned int)self.longLongValue;
}

- (long)longValue
{
    return (long)self.longLongValue;
}

- (unsigned long)unsignedLongValue
{
    return (unsigned long)self.longLongValue;
}

- (unsigned long long)unsignedLongLongValue
{
    return (unsigned long long)self.longLongValue;
}


@end
