//
//  TCHTTPRequestProtocol.h
//  TCKit
//
//  Created by dake on 16/3/18.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRespValidator.h"
#import "TCHTTPTimerPolicy.h"


typedef NS_ENUM(NSInteger, TCRequestState) {
    kTCRequestUnFire = 0,
    kTCRequestNetwork,
    kTCRequestFinished,
};

typedef NS_ENUM(NSInteger, TCCachedRespState) {
    kTCCachedRespNone = 0,
    kTCCachedRespValid,
    kTCCachedRespExpired,
};

typedef NS_ENUM(NSInteger, TCHTTPMethod) {
    kTCHTTPMethodUnknown = 0,
    
    kTCHTTPMethodGet,
    kTCHTTPMethodPost, // form-data, url-encoded
    kTCHTTPMethodPostJSON, // application/json
    kTCHTTPMethodHead,
    kTCHTTPMethodPut,
    kTCHTTPMethodDelete,
    kTCHTTPMethodPatch,
    kTCHTTPMethodDownload,
};


@class TCHTTPCachePolicy;
@class TCHTTPStreamPolicy;
@protocol TCHTTPRequestDelegate;


NS_ASSUME_NONNULL_BEGIN

@protocol TCHTTPRequest <NSObject>

@required

#pragma mark - callback

@property (nonatomic, weak, nullable) id<TCHTTPRequestDelegate> delegate;
@property (nonatomic, copy, nullable) void (^resultBlock)(id<TCHTTPRequest> request, BOOL success);

@property (nonatomic, strong, nullable) id<TCHTTPRespValidator> responseValidator;


@property (nonatomic, copy) NSString *identifier;
- (BOOL)hasIdentifier;

@property (nonatomic, strong, nullable) NSDictionary *userInfo;
@property (atomic, assign) TCRequestState state;

@property (nonatomic, weak, nullable) id observer;
@property (atomic, assign, readonly) BOOL isCancelled;

/**
 @brief	start a http request with checking available cache,
 if cache is available, no request will be fired.
 
 @param error [OUT] param invalid, etc...
 
 */
- (BOOL)start:(NSError * _Nullable __strong * _Nullable)error;
- (BOOL)startWithResult:(void (^)(id<TCHTTPRequest> request, BOOL success))resultBlock error:(NSError * _Nullable __strong * _Nullable)error;

- (BOOL)canStart:(NSError * _Nullable __strong * _Nullable)error;
// delegate, resulteBlock always called, even if request was cancelled.
- (void)cancel;

- (BOOL)isRequestingNetwork;


#pragma mark - build request

@property (nonatomic, copy, nullable) NSString *apiUrl; // "getUserInfo/"
@property (nonatomic, copy, nullable) NSString *baseUrl; // "http://eet/oo/"

// Auto convert to query string, if requestMethod is GET
@property (nonatomic, strong, nullable) id parameters;
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // default: 30s
@property (nonatomic, assign) TCHTTPMethod method;

@property (nonatomic, assign) BOOL overrideIfImpact; // default: YES, NO: abandon current request, if a same one existed
@property (nonatomic, assign) BOOL ignoreParamFilter;

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *customHeaders;


- (nullable id)responseObject;


#pragma mark - timer

@property (nonatomic, strong, nullable) TCHTTPTimerPolicy *timerPolicy;


#pragma mark - Upload / download

@property (nonatomic, strong, nullable) TCHTTPStreamPolicy *streamPolicy;


#pragma mark - Custom

// set nonull to ignore requestUrl, argument, requestMethod, serializerType
@property (nonatomic, strong, nullable) NSURLRequest *customUrlRequest;



@optional


#pragma mark - Cache

@property (nonatomic, strong, nullable, readonly) TCHTTPCachePolicy *cachePolicy;
@property (nonatomic, assign) BOOL isForceStart;

/**
 @brief	fire a request regardless of cache available
 if cache is available, callback then fire a request.
 
 @param error [OUT] <#error description#>
 
 @return <#return value description#>
 */
- (BOOL)forceStart:(NSError * _Nullable __strong * _Nullable)error;

- (void)cachedResponseByForce:(BOOL)force result:(void (^)(id _Nullable response, TCCachedRespState state))result;


#pragma mark - Batch

@property (nonatomic, copy, readonly) NSArray<id<TCHTTPRequest>> *batchRequests;
@property (nonatomic, assign) BOOL continueAfterSubRequestFailed;

@end



@protocol TCHTTPRequestDelegate <NSObject>

@optional
+ (void)processRequest:(id<TCHTTPRequest>)request success:(BOOL)success;
- (void)processRequest:(id<TCHTTPRequest>)request success:(BOOL)success;

@end

NS_ASSUME_NONNULL_END
