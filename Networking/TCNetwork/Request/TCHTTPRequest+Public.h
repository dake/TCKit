//
//  TCHTTPRequest+Public.h
//  TCKit
//
//  Created by dake on 15/3/30.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface TCHTTPRequest (Public)

+ (instancetype)requestWithMethod:(TCHTTPMethod)method;
+ (instancetype)cacheRequestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy;
+ (instancetype)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests;

@end

NS_ASSUME_NONNULL_END
