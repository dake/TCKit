//
//  TCHTTPRequestAgent.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@protocol TCHTTPRequestAgent <NSObject>

@required
- (void)addRequestToPool:(id<TCHTTPRequest>)request;
- (void)removeRequestFromPool:(id<TCHTTPRequest>)request;

- (BOOL)canAddRequest:(id<TCHTTPRequest>)request error:(NSError * _Nullable __strong * _Nullable)error;
- (BOOL)addRequest:(id<TCHTTPRequest>)request error:(NSError * _Nullable __strong * _Nullable)error;
- (NSURL *)buildRequestUrlForRequest:(id<TCHTTPRequest>)request;

// cache 
- (NSString *)cachePathForResponse;

- (void)storeCachedResponse:(id)response forCachePolicy:(TCHTTPCachePolicy *)cachePolicy finish:(dispatch_block_t)block;
- (void)cachedResponseForRequest:(id<TCHTTPRequest>)request result:(void (^)(id _Nullable response))result;

- (id<TCHTTPRespValidator>)responseValidatorForRequest:(id<TCHTTPRequest>)request;

@optional
- (nullable NSArray<id<TCHTTPRequest>> *)requestsForObserver:(id _Nullable)observer;
- (nullable id<TCHTTPRequest>)requestForObserver:(id _Nullable)observer forIdentifier:(id)identifier;

@end

NS_ASSUME_NONNULL_END
