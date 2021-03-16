//
//  NSURLSessionTask+TCResumeDownload.m
//  TCKit
//
//  Created by dake on 16/1/9.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSURLSessionTask+TCResumeDownload.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

#ifndef __TCKit__
#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGAffineTransform.h>
#import <UIKit/UIGeometry.h>
#endif


static NSString *const kNSURLSessionResumeInfoTempFileName = @"NSURLSessionResumeInfoTempFileName";
static NSString *const kNSURLSessionResumeInfoLocalPath = @"NSURLSessionResumeInfoLocalPath";


static NSString *tc_md5_32(NSString *str)
{
    if (str.length < 1) {
        return nil;
    }
    
    const char *value = str.UTF8String;
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; ++count) {
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}


@implementation NSObject (TCResumeDownload)

- (BOOL)tc_makePersistentResumeCapable
{
    if (![self isKindOfClass:NSURLSessionDownloadTask.class] ||
        ![self respondsToSelector:@selector(cancelByProducingResumeData:)]) {
        return NO;
    }
    
    static NSMutableSet<Class> *enabledClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        enabledClasses = NSMutableSet.set;
    });
    
    @synchronized(enabledClasses) {
        Class klass = self.class;
        if (![enabledClasses containsObject:klass]) {
            [klass tc_swizzle:@selector(cancelByProducingResumeData:)];
            [enabledClasses addObject:klass];
        }
    }
    
    return YES;
}

- (NSString *)tc_resumeIdentifier
{
    NSString *identifier = objc_getAssociatedObject(self, _cmd);
    if (identifier.length < 1) {
        identifier = tc_md5_32(((NSURLSessionTask *)self).originalRequest.URL.absoluteString);
        if (identifier.length > 0) {
            [self setTc_resumeIdentifier:identifier];
        }
    }
    return identifier;
}

- (void)setTc_resumeIdentifier:(NSString *)tc_resumeIdentifier
{
    objc_setAssociatedObject(self, @selector(tc_resumeIdentifier), tc_resumeIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSURL *)tc_resumeCacheDirectory
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setTc_resumeCacheDirectory:(NSURL *)tc_resumeCacheDirectory
{
    objc_setAssociatedObject(self, @selector(tc_resumeCacheDirectory), tc_resumeCacheDirectory, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)tc_purgeResumeData
{
    [NSURLSessionTask tc_purgeResumeDataWithIdentifier:self.tc_resumeIdentifier inDirectory:self.tc_resumeCacheDirectory];
}

- (void)tc_cancelByProducingResumeData:(void (^)(NSData * __nullable resumeData))completionHandler
{
    if (nil == self.tc_resumeCacheDirectory) {
        [self tc_cancelByProducingResumeData:completionHandler];
        return;
    }
    
    __weak typeof(self) wSelf = self;
    [self tc_cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        if (nil == wSelf) {
            if (nil != completionHandler) {
                completionHandler(resumeData);
            }
            return;
        }
        
        __strong typeof(wSelf) sSelf = wSelf;
        dispatch_block_t block = ^{
            @autoreleasepool {
                if (nil != resumeData) {
                    if ([resumeData writeToURL:sSelf.tc_resumeCachePath atomically:YES] &&
                        ![NSURLSessionTask tc_isTmpResumeCache:sSelf.tc_resumeCacheDirectory]) {
                        NSURL *tmpDownloadFile = [sSelf.class tc_resumeInfoTempFileNameFor:resumeData];
                        if (nil != tmpDownloadFile) {
                            NSError *error = nil;
                            NSURL *cachePath = [sSelf.tc_resumeCacheDirectory URLByAppendingPathComponent:tmpDownloadFile.lastPathComponent];
                            [NSFileManager.defaultManager removeItemAtURL:cachePath error:NULL];
                            [NSFileManager.defaultManager moveItemAtURL:tmpDownloadFile toURL:cachePath error:&error];
                            NSCAssert(nil == error, @"%@", error);
                        }
                    }
                }
                
                if (nil != completionHandler) {
                    completionHandler(resumeData);
                }
            }
        };
        
        if (NSThread.isMainThread) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
        } else {
            block();
        }
    }];
}


#pragma mark -

+ (NSURL *)tc_resumeInfoTempFileNameFor:(NSData *)data
{
    if (nil == data) {
        return nil;
    }
    
    NSDictionary *dic = nil;
    @try {
        dic = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:NULL];
    } @catch (NSException *exception) {
        
    } @finally {
        NSString *fileName = nil;
        if (nil != dic) {
            fileName = dic[kNSURLSessionResumeInfoTempFileName];
            if (nil == fileName) {
                fileName = [dic[kNSURLSessionResumeInfoLocalPath] lastPathComponent];
            }
            
            if (nil != fileName) {
                return [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:fileName];
            }
        }
        
        return nil;
    }
}

+ (NSURL *)tc_resumeCachePathWithDirectory:(NSURL *)subpath identifier:(NSString *)indentifier
{
    return [subpath URLByAppendingPathComponent:tc_md5_32(indentifier)];
}

+ (BOOL)tc_isTmpResumeCache:(NSURL *)resumeDirectory
{
    NSString *path = resumeDirectory.path;
    NSString *tmp = NSTemporaryDirectory();
    return [path hasPrefix:tmp]
    || [path.stringByStandardizingPath hasPrefix:tmp]
    || [path hasPrefix:tmp.stringByStandardizingPath];
}

- (NSURL *)tc_resumeCachePath
{
    return [self.class tc_resumeCachePathWithDirectory:self.tc_resumeCacheDirectory identifier:self.tc_resumeIdentifier];
}


#ifndef __TCKit__
#pragma mark - helper

+ (BOOL)tc_swizzle:(SEL)aSelector
{
    Method m1 = class_getInstanceMethod(self, aSelector);
    if (NULL == m1) {
        return NO;
    }
    
    SEL bSelector = NSSelectorFromString([NSString stringWithFormat:@"tc_%@", NSStringFromSelector(aSelector)]);
    Method m2 = class_getInstanceMethod(self, bSelector);

    if (class_addMethod(self, aSelector, method_getImplementation(m2), method_getTypeEncoding(m2))) {
        class_replaceMethod(self, bSelector, method_getImplementation(m1), method_getTypeEncoding(m1));
    } else {
        method_exchangeImplementations(m1, m2);
    }
    
    return YES;
}
#endif

@end


#pragma mark - NSURLSessionTask

@implementation NSURLSessionTask (TCResumeDownload)

- (BOOL)tc_makePersistentResumeCapable
{
    return [super tc_makePersistentResumeCapable];
}

- (NSString *)tc_resumeIdentifier
{
    return [super tc_resumeIdentifier];
}

- (void)setTc_resumeIdentifier:(NSString *)tc_resumeIdentifier
{
    [super setTc_resumeIdentifier:tc_resumeIdentifier];
}

- (NSURL *)tc_resumeCacheDirectory
{
    return [super tc_resumeCacheDirectory];
}

- (void)setTc_resumeCacheDirectory:(NSURL *)tc_resumeCacheDirectory
{
    [super setTc_resumeCacheDirectory:tc_resumeCacheDirectory];
}


#pragma mark -

+ (nullable NSData *)tc_resumeDataWithIdentifier:(NSString *)identifier inDirectory:(nullable NSURL *)subpath
{
    // FIXME: huge file with GBs
    NSData *data = [NSData dataWithContentsOfURL:[self tc_resumeCachePathWithDirectory:subpath identifier:identifier] options:NSDataReadingUncached|NSDataReadingMappedAlways error:NULL];
    if (nil == data) {
        return nil;
    }
    NSURL *tmpDownloadFile = [self tc_resumeInfoTempFileNameFor:data];
    if (nil != tmpDownloadFile) {
        if (![self tc_isTmpResumeCache:subpath]) {
            NSError *error = nil;
            [NSFileManager.defaultManager removeItemAtURL:tmpDownloadFile error:NULL];
            [NSFileManager.defaultManager copyItemAtURL:[subpath URLByAppendingPathComponent:tmpDownloadFile.lastPathComponent] toURL:tmpDownloadFile error:&error];
            NSCAssert(nil == error, @"%@", error);
        }
        
        if (![NSFileManager.defaultManager fileExistsAtPath:tmpDownloadFile.path]) {
            if (nil != subpath) {
                [NSFileManager.defaultManager removeItemAtURL:[subpath URLByAppendingPathComponent:tmpDownloadFile.lastPathComponent] error:NULL];
            }
            data = nil;
        }
    }
    
    return data;
}

+ (void)tc_purgeResumeDataWithIdentifier:(NSString *)identifier inDirectory:(nullable NSURL *)subpath
{
    NSURL *url = [self tc_resumeCachePathWithDirectory:subpath identifier:identifier];
    if (![NSFileManager.defaultManager fileExistsAtPath:url.path]) {
        return;
    }
    
    // rm tmp files
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached|NSDataReadingMappedAlways error:NULL];
    NSURL *tmpDownloadFile = [self tc_resumeInfoTempFileNameFor:data];
    if (nil != tmpDownloadFile) {
        [NSFileManager.defaultManager removeItemAtURL:tmpDownloadFile error:NULL];
        
        if (nil != subpath) {
            [NSFileManager.defaultManager removeItemAtURL:[subpath URLByAppendingPathComponent:tmpDownloadFile.lastPathComponent] error:NULL];
        }
    }
    
    [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
}

- (void)tc_purgeResumeData
{
    [super tc_purgeResumeData];
}

@end


