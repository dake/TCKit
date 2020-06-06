//
//  TCHTTPRequestCenter.h
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestAgent.h"
#import "TCHTTPRequestUrlFilter.h"
#import "TCHTTPCachePolicy.h"
#import "TCHTTPStreamPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@class AFSecurityPolicy;
@class AFHTTPSessionManager;
NS_CLASS_AVAILABLE_IOS(7_0) @interface TCHTTPRequestCenter : NSObject <TCHTTPRequestAgent>

@property (nonatomic, strong) NSURL *baseURL;

@property (nonatomic, assign, readonly) BOOL networkReachable;
// default: 0, use Max(TCHTTPRequestCenter.timeoutInterval, TCHTTPRequest.timeoutInterval)
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong, nullable) NSSet<NSString *> *acceptableContentTypes;

@property (nonatomic, copy, readonly) NSURLSessionConfiguration *sessionConfiguration;
@property (nullable, nonatomic, strong) AFHTTPSessionManager *requestManager;
@property (nonatomic, weak, nullable) id<TCHTTPRequestUrlFilter> urlFilter;


+ (instancetype)defaultCenter;
- (instancetype)initWithSession:(nullable AFHTTPSessionManager *)mng;
- (instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration;
- (AFSecurityPolicy *)securityPolicy;

- (BOOL)addRequest:(id<TCHTTPRequest>)request error:(NSError * _Nullable __strong * _Nullable)error;

- (void)removeRequestObserver:(__unsafe_unretained id)observer forIdentifier:(nullable id<NSCoding>)identifier;
- (void)removeRequestObserver:(__unsafe_unretained id)observer;
- (void)removeAllRequests;

- (NSString *)cachePathForResponse;
- (NSString *)cacheDomainForResponse;
- (void)removeAllCachedResponses;

- (void)registerResponseValidatorClass:(Class)validatorClass;


#pragma mark - Cache 

- (void)storeCachedResponse:(id)response forCachePolicy:(TCHTTPCachePolicy *)cachePolicy finish:(dispatch_block_t)block;
- (void)cachedResponseForRequest:(id<TCHTTPRequest>)request result:(void (^)(id response))result;


#pragma mark - Custom value in HTTP Head

- (nullable NSDictionary<NSString *, NSString *> *)customHeaderValueForRequest:(id<TCHTTPRequest>)request;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a basic authentication value with Base64-encoded username and password. 
 This overwrites any existing value for this header.
 */
@property (nonatomic, copy, nullable) NSString *authorizationUsername;
@property (nonatomic, copy, nullable) NSString *authorizationPassword;

@end


@interface TCHTTPRequestCenter (TCHTTPRequest)

//
// request method below, will not auto start
//
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method apiUrl:(nullable NSString *)apiUrl host:(nullable NSString *)host;
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method cachePolicy:(nullable TCHTTPCachePolicy *)policy apiUrl:(NSString *)apiUrl host:(nullable NSString *)host;
- (nullable id<TCHTTPRequest>)requestForDownload:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy cachePolicy:(nullable TCHTTPCachePolicy *)cachePolicy;
- (nullable id<TCHTTPRequest>)requestForUploadTo:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy;
- (nullable id<TCHTTPRequest>)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests;

@end

NS_ASSUME_NONNULL_END
