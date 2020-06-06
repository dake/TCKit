//
//  TCHTTPRequestCenter+Private.h
//  TCKit
//
//  Created by dake on 16/3/27.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface TCHTTPRequestCenter (Private)

- (void)loadResumeData:(void (^)(NSData *data))finish forPolicy:(TCHTTPStreamPolicy *)policy;
- (void)clearCachedResumeDataForRequest:(id<TCHTTPReqAgentDelegate>)request;


#pragma mark - Making HTTP Requests

//
// request method below, will not auto start
//
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method apiUrl:(NSString *)apiUrl host:(nullable NSString *)host;
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method cachePolicy:(nullable TCHTTPCachePolicy *)policy apiUrl:(nullable NSString *)apiUrl host:(nullable NSString *)host;
- (nullable id<TCHTTPRequest>)requestForDownload:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy cachePolicy:(nullable TCHTTPCachePolicy *)cachePolicy;
- (nullable id<TCHTTPRequest>)requestForUploadTo:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy;
- (nullable id<TCHTTPRequest>)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests;

@end

NS_ASSUME_NONNULL_END
