//
//  TCHTTPCachePolicy.m
//  TCKit
//
//  Created by dake on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPCachePolicy.h"
#import "TCHTTPRequestHelper.h"
#import "TCHTTPStreamPolicy.h"
#import <sys/stat.h>


NSInteger const kTCHTTPRequestCacheNeverExpired = -1;


@implementation TCHTTPCachePolicy
{
@private
    NSDictionary *_parametersForCachePathFilter;
    id _sensitiveDataForCachePathFilter;
    NSString *_cacheFileName;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldCacheResponse = YES;
        _shouldCacheEmptyResponse = YES;
    }
    return self;
}


- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(NSObject<NSCopying> *)sensitiveData;
{
    _parametersForCachePathFilter = parameters.copy;
    _sensitiveDataForCachePathFilter = sensitiveData.copy;
}

- (NSString *)cacheFileName
{
    if (nil != _cacheFileName) {
        return _cacheFileName;
    }
    
    NSString *requestUrl = nil;
    if (nil != _request.requestAgent && [_request.requestAgent respondsToSelector:@selector(buildRequestUrlForRequest:)]) {
        requestUrl = [_request.requestAgent buildRequestUrlForRequest:_request].absoluteString;
    } else {
        requestUrl = _request.apiUrl;
    }
    NSCParameterAssert(requestUrl);
    
    static NSString *const s_fmt = @"Method:%@ RequestUrl:%@ Parames:%@ Sensitive:%@";
    NSString *cacheKey = [NSString stringWithFormat:s_fmt, @(_request.method), requestUrl, _parametersForCachePathFilter, _sensitiveDataForCachePathFilter];
    _parametersForCachePathFilter = nil;
    _sensitiveDataForCachePathFilter = nil;
    _cacheFileName = [TCHTTPRequestHelper MD5_32:cacheKey];
    
    return _cacheFileName;
}

- (NSURL *)cacheFilePath
{
    if (_request.method == kTCHTTPMethodDownload) {
        return _request.streamPolicy.downloadDestinationPath;
    }
    
    NSURL *url = nil;
    if (nil != _request.requestAgent && [_request.requestAgent respondsToSelector:@selector(cachePathForResponse)]) {
        url = _request.requestAgent.cachePathForResponse;
    }
    
    NSCParameterAssert(url);
    
    if (nil == url) {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TCHTTPCache.TCNetwork.TCKit"];
        if (nil != path) {
            url = [NSURL fileURLWithPath:path];
        }
    }
    if ([self createDiretoryForCachePath:url]) {
        return [url URLByAppendingPathComponent:self.cacheFileName];
    }
    
    return nil;
}


- (BOOL)validateResponseObjectForCache
{
    id responseObject = _request.responseObject;
    if (nil == responseObject || (NSNull *)responseObject == NSNull.null) {
        return NO;
    }
    
    if (!self.shouldCacheEmptyResponse) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            return [(NSDictionary *)responseObject count] > 0;
        } else if ([responseObject isKindOfClass:NSArray.class]) {
            return [(NSArray *)responseObject count] > 0;
        } else if ([responseObject isKindOfClass:NSString.class]) {
            return [(NSString *)responseObject length] > 0;
        } else if ([responseObject isKindOfClass:NSURL.class]) {
            return YES;
        }
    }
    
    return YES;
}

- (BOOL)shouldWriteToCache
{
    return _request.method != kTCHTTPMethodDownload &&
    self.shouldCacheResponse &&
    self.cacheTimeoutInterval != 0 &&
    self.validateResponseObjectForCache;
}

- (TCCachedRespState)cacheState
{
    NSURL *url = self.cacheFilePath;
    if (nil == url) {
        return kTCCachedRespNone;
    }
    
    BOOL isDir = NO;
    NSFileManager *fileMngr = NSFileManager.defaultManager;
    if (![fileMngr fileExistsAtPath:url.path isDirectory:&isDir] || isDir) {
        return kTCCachedRespNone;
    }
    
    struct stat statbuf;
    if (stat(url.fileSystemRepresentation, &statbuf) != 0) {
        return kTCCachedRespExpired;
    }
    NSDate *modificationDate = [NSDate dateWithTimeIntervalSince1970:statbuf.st_mtime];
    NSTimeInterval timeIntervalSinceNow = modificationDate.timeIntervalSinceNow;
    if (timeIntervalSinceNow >= 0) { // deal with wrong system time
        return kTCCachedRespExpired;
    }
    
    NSTimeInterval cacheTimeoutInterval = self.cacheTimeoutInterval;
    if (cacheTimeoutInterval < 0 || -timeIntervalSinceNow < cacheTimeoutInterval) {
        if (_request.method == kTCHTTPMethodDownload) {
            if (![fileMngr fileExistsAtPath:url.path]) {
                return kTCCachedRespNone;
            }
        }
        
        return kTCCachedRespValid;
    }
    
    return kTCCachedRespExpired;
}

- (BOOL)isCacheValid
{
    return self.cacheState == kTCCachedRespValid;
}

- (NSDate *)cacheDate
{
    TCCachedRespState state = self.cacheState;
    if (kTCCachedRespExpired == state || kTCCachedRespValid == state) {
        struct stat statbuf;
        if (stat(self.cacheFilePath.fileSystemRepresentation, &statbuf) != 0) {
            return nil;
        }
        NSDate *modificationDate = [NSDate dateWithTimeIntervalSince1970:statbuf.st_mtime];
        return modificationDate;
    }
    
    return nil;
}

- (BOOL)isDataFromCache
{
    return nil != _cachedResponse;
}


#pragma mark -

- (BOOL)createDiretoryForCachePath:(NSURL *)url
{
    if (nil == url) {
        return NO;
    }
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:url.path isDirectory:&isDir]) {
        if (isDir) {
            return YES;
        } else {
            [fileManager removeItemAtURL:url error:NULL];
        }
    }
    
    if ([fileManager createDirectoryAtURL:url
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:NULL]) {
        
        [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:NULL];
        return YES;
    }
    
    return NO;
}

@end
