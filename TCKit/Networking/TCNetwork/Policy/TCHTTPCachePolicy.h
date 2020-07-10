//
//  TCHTTPCachePolicy.h
//  TCKit
//
//  Created by dake on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestProtocol.h"
#import "TCHTTPReqAgentDelegate.h"


NS_ASSUME_NONNULL_BEGIN

extern NSInteger const kTCHTTPRequestCacheNeverExpired;


@interface TCHTTPCachePolicy : NSObject

@property (nonatomic, weak) id<TCHTTPRequest, TCHTTPReqAgentDelegate> request;
@property (nonatomic, strong, nullable) id cachedResponse;


@property (nonatomic, assign) BOOL shouldIgnoreCache; // default: NO
@property (nonatomic, assign) BOOL shouldCacheResponse; // default: YES
@property (nonatomic, assign) BOOL shouldCacheEmptyResponse; // default: YES, empty means: empty string, array, dictionary
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval; // default: 0, expired anytime, < 0: never expired

// should return expired cache or not
@property (nonatomic, assign) BOOL shouldExpiredCacheValid; // default: NO

- (BOOL)isCacheValid;
- (BOOL)isDataFromCache;
- (nullable NSDate *)cacheDate;
- (TCCachedRespState)cacheState;


// default: parameters = nil, sensitiveData = nil
- (void)setCachePathFilterWithRequestParameters:(nullable NSDictionary *)parameters
                                  sensitiveData:(nullable id)sensitiveData;


- (NSString *)cacheFileName;
- (nullable NSURL *)cacheFilePath;
- (BOOL)shouldWriteToCache;

@end

NS_ASSUME_NONNULL_END
