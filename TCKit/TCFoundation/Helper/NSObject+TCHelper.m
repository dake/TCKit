//
//  NSObject+TCHelper.m
//  TCKit
//
//  Created by dake on 14-5-4.
//  Copyright (c) 2014年 dake. All rights reserved.
//

#import "NSObject+TCHelper.h"
#import <objc/runtime.h>

static NSString const *kDefaultDomain = @"TCKit";

@implementation NSObject (TCHelper)

@dynamic humanDescription;

+ (NSURL *)defaultPersistentDirectoryInDomain:(NSString *)domain create:(BOOL)create
{
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:domain?:kDefaultDomain];
    //#if TARGET_OS_SIMULATOR
    //    path = [path stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    //#endif
    
    if (create && ![NSFileManager.defaultManager createDirectoryAtPath:dir
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:NULL]) {
        NSCAssert(false, @"create directory failed.");
        dir = nil;
    }
    
    return nil == dir ? nil : [NSURL fileURLWithPath:dir];
}

+ (NSURL *)defaultCacheDirectoryInDomain:(NSString *)domain create:(BOOL)create
{
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:domain ?: kDefaultDomain];
    
    if (create && ![NSFileManager.defaultManager createDirectoryAtPath:dir
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:NULL]) {
        NSCAssert(false, @"create directory failed.");
        dir = nil;
    }
    return nil == dir ? nil : [NSURL fileURLWithPath:dir];
}

+ (NSURL *)defaultTmpDirectoryInDomain:(NSString *)domain create:(BOOL)create;
{
    NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:domain ?: kDefaultDomain];
    if (create && ![NSFileManager.defaultManager createDirectoryAtPath:dir
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:NULL]) {
        NSCAssert(false, @"create directory failed.");
        dir = nil;
    }
    
    return nil == dir ? nil : [NSURL fileURLWithPath:dir];
}


+ (NSString *)humanDescription
{
    return nil;
}

- (NSString *)humanDescription
{
    NSString *str = objc_getAssociatedObject(self, @selector(setHumanDescription:));
    return str ?: self.class.humanDescription;
}

- (void)setHumanDescription:(NSString *)humanDescription
{
    objc_setAssociatedObject(self, _cmd, humanDescription, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end


// MARK: _TCEndian_readf

//#define HOST_ENDIANESS BYTE_ORDER
//#if __LITTLE_ENDIAN__
//#define HOST_ENDIANESS CG_ENDIAN_LITTLE
//#else
//#define HOST_ENDIANESS CG_ENDIAN_BIG
//#endif

static void _TCEndian_swap(void *buffer, size_t size) {
    char tmp = '\0';
    char *src = (char *)buffer;
    char *dst = (char *)buffer + size - 1;
    while (src < dst) {
        tmp = *src;
        *src = *dst;
        *dst = tmp;
        ++src; --dst;
    }
}

static void _TCEndian_swapArray(void *buffer, size_t size, size_t count) {
    for (size_t c = 0; c < count; ++c) {
        _TCEndian_swap((char *)buffer + c * size, size);
    }
}

size_t _TCEndian_readf(FILE *stream, const char *format, ...)
{
    const char *c = format;
    bool cont = true;
    size_t items = 0;
    
    va_list args;
    va_start(args, format);
    
    while (cont && *c) {
        void *buffer = NULL;
        int order = LITTLE_ENDIAN;
        size_t size = 0, count = 0;
        size_t read = 0;
        
        while (isspace((unsigned char)*c)) {
            ++c;
        }
        
        /* extract optional repetition count */
        if (isdigit((unsigned char)*c)) {
            count = 0;
            
            while (isdigit((unsigned char)*c)) {
                count *= 10;
                count += (size_t)(*c - '0');
                ++c;
            }
            
            while (isspace((unsigned char)*c))
                ++c;
            
        } else {
            count = 1;
        }
        
        assert(*c != 0);
        
        /* extract field size and byte order */
        switch (*c++) {
            case 'b':
                size  = 1;
                order = LITTLE_ENDIAN;
                break;
                
            case 'B':
                size  = 1;
                order = BIG_ENDIAN;
                break;
                
            case 'w':
                size  = 2;
                order = LITTLE_ENDIAN;
                break;
                
            case 'W':
                size  = 2;
                order = BIG_ENDIAN;
                break;
                
            case 'd':
                size  = 4;
                order = LITTLE_ENDIAN;
                break;
                
            case 'D':
                size  = 4;
                order = BIG_ENDIAN;
                break;
                
            case 'q':
                size  = 8;
                order = LITTLE_ENDIAN;
                break;
                
            case 'Q':
                size  = 8;
                order = BIG_ENDIAN;
                break;
                
            default:
                return 0;
        }
        
        buffer = va_arg(args, void *);
        
        if (NULL != buffer) {
            read = fread(buffer, size, count, stream);
            items += read;
            
            if ((size > 1) && (order != BYTE_ORDER)) {
                _TCEndian_swapArray(buffer, size, read);
            }
            
            cont = read == count;
            
        } else {
            items += count;
            cont = fseek(stream, (long)(count * size), SEEK_CUR) != -1;
        }
    }
    
    va_end(args);
    
    return items;
}


//@implementation NSJSONSerialization (TCHelper)
//
//+ (void)load
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [self tc_swizzle:@selector(JSONObjectWithData:options:error:)];
//    });
//}
//
//+ (nullable id)tc_JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error
//{
//    NSUInteger len = data.length;
//    NSError *serializationError = nil;
//    id responseObject = [self tc_JSONObjectWithData:data options:opt error:&serializationError];
//    if (nil == responseObject && [serializationError.domain isEqualToString:NSCocoaErrorDomain] && serializationError.code == NSPropertyListReadCorruptError) {
//        NSMutableData *tmpData = NSMutableData.data;
//        const char *bytes = (typeof(bytes))data.bytes;
//        for (NSUInteger i = 0; i < len; ++i) {
//            if (0 == iscntrl(bytes[i])) {
//                [tmpData appendBytes:bytes + i length:1];
//            }
//        }
//        if (tmpData.length > 0 && tmpData.length < len) {
//            NSError *err = serializationError;
//            serializationError = nil;
//            responseObject = [NSJSONSerialization JSONObjectWithData:tmpData options:opt error:&serializationError];
//            if (nil == responseObject) {
//                serializationError = err;
//            }
//        }
//    }
//
//    if (NULL != error && nil != serializationError) {
//        *error = serializationError;
//    }
//
//    return responseObject;
//}
//
//@end
