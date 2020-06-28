//
//  TCHTTPRequestCenter.m
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter.h"
#import "AFHTTPSessionManager.h"
#import "AFNetworkReachabilityManager.h"

#import "TCHTTPRequestHelper.h"
#import "TCBaseResponseValidator.h"
#import "NSURLSessionTask+TCResumeDownload.h"
#import "TCHTTPRequestCenter+Private.h"


@implementation TCHTTPRequestCenter
{
@private
    AFJSONRequestSerializer *_jsonSerializer;
    AFHTTPRequestSerializer *_httpSerializer;
    
    NSMapTable<id, NSMapTable<id<NSCoding>, id<TCHTTPRequest>> *> *_requestPool;
    NSRecursiveLock *_poolLock;
    
    NSString *_cachePathForResp;
    __unsafe_unretained Class _respValidorClass;
    
    NSURLSessionConfiguration *_sessionConfig;
    
    AFSecurityPolicy *_securityPolicy;
    NSCache *_memCache;

}

@synthesize requestManager = _requestManager;

+ (instancetype)defaultCenter
{
    static NSMapTable<Class, __kindof TCHTTPRequestCenter *> *centers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        centers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality
                                        valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality];
    });
    
    TCHTTPRequestCenter *obj = nil;
    @synchronized(centers) {
        obj = [centers objectForKey:self];
        if (nil == obj) {
            obj = [[self alloc] initWithSessionConfiguration:nil];
            if (nil != obj) {
                [centers setObject:obj forKey:self];
            }
        }
    }
    
    return obj;
}

- (void)setBaseURL:(NSURL *)baseURL
{
    if (baseURL != _baseURL) {
        _baseURL = baseURL;
        _requestManager = nil;
    }
}

- (AFJSONRequestSerializer *)jsonSerializer
{
    if (nil == _jsonSerializer) {
        _jsonSerializer = AFJSONRequestSerializer.serializer;
        _jsonSerializer.cachePolicy = _httpSerializer.cachePolicy;
        _jsonSerializer.allowsCellularAccess = _httpSerializer.allowsCellularAccess;
        _jsonSerializer.HTTPShouldHandleCookies = _httpSerializer.HTTPShouldHandleCookies;
        _jsonSerializer.HTTPShouldUsePipelining = _httpSerializer.HTTPShouldUsePipelining;
        _jsonSerializer.timeoutInterval = _httpSerializer.timeoutInterval;
        _jsonSerializer.networkServiceType = _httpSerializer.networkServiceType;
    }
    
    return _jsonSerializer;
}

- (Class)responseValidorClass
{
    return _respValidorClass ?: TCBaseResponseValidator.class;
}

- (void)registerResponseValidatorClass:(Class)validatorClass
{
    _respValidorClass = validatorClass;
}

- (BOOL)networkReachable
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

- (NSURLSessionConfiguration *)sessionConfiguration
{
    return self.requestManager.session.configuration;
}

- (nullable NSDictionary<NSString *, NSString *> *)customHeaderValueForRequest:(id<TCHTTPRequest>)request
{
    return request.customHeaders;
}


- (NSCache *)memCache
{
    if (nil == _memCache) {
        _memCache = [[NSCache alloc] init];
        _memCache.name = [NSString stringWithFormat:@"cache.%@.TCNetwork.TCKit", NSStringFromClass(self.class)];
    }
    
    return _memCache;
}

- (NSString *)cachePathForResponse
{
    if (nil == _cachePathForResp) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        _cachePathForResp = [path stringByAppendingPathComponent:@"TCHTTPRequestCache"];
        NSString *domain = self.cacheDomainForResponse;
        if (domain.length > 0) {
            _cachePathForResp = [_cachePathForResp stringByAppendingPathComponent:domain];
        }
    }
    
    return _cachePathForResp;
}

- (NSString *)cacheDomainForResponse
{
    return [self isMemberOfClass:TCHTTPRequestCenter.class] ? nil : NSStringFromClass(self.class);
}

- (AFSecurityPolicy *)securityPolicy
{
    return [AFSecurityPolicy defaultPolicy];
}

- (AFSecurityPolicy *)innerSecurityPolicy
{
    if (nil == _securityPolicy) {
        _securityPolicy = self.securityPolicy;
    }
    return _securityPolicy;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _poolLock = [[NSRecursiveLock alloc] init];
        _poolLock.name = @"requestPoolLock.TCNetwork.TCKit";
        _requestPool = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality
                                             valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        
        _memCache = [[NSCache alloc] init];
    }
    return self;
}

- (NSString *)requestManagerPrint
{
    NSUInteger policyHash = self.innerSecurityPolicy.hash;
    NSUInteger configurationHash = _sessionConfig.hash;
    
    NSUInteger contentTypeHash = 0;
    for (NSString *type in self.acceptableContentTypes) {
        contentTypeHash ^= type.hash;
    }
    if (policyHash == 0 && configurationHash == 0 && contentTypeHash == 0) {
        return @"default";
    }
    
    return [TCHTTPRequestHelper MD5_16:[@[@(policyHash), @(configurationHash), @(contentTypeHash)] componentsJoinedByString:@"_"]];
}

- (AFHTTPSessionManager *)dequeueRequestManagerWithIdentifier:(NSString *)identifier
{
    NSCParameterAssert(identifier);
    if (nil == identifier) {
        return nil;
    }
    
    static NSMapTable<NSString *, AFHTTPSessionManager *> *s_mngrPool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_mngrPool = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                           valueOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality];
    });
    
    AFHTTPSessionManager *reqMngr = nil;
    @synchronized(s_mngrPool) {
        reqMngr = [s_mngrPool objectForKey:identifier];
        if (nil == reqMngr) {
            reqMngr = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_sessionConfig];
            reqMngr.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
            AFSecurityPolicy *policy = self.innerSecurityPolicy;
            _httpSerializer = reqMngr.requestSerializer;
            if (nil != policy) {
                reqMngr.securityPolicy = policy;
            }
            
            if (nil != self.acceptableContentTypes) {
                NSMutableSet *set = reqMngr.responseSerializer.acceptableContentTypes.mutableCopy;
                [set unionSet:self.acceptableContentTypes];
                reqMngr.responseSerializer.acceptableContentTypes = set;
                self.acceptableContentTypes = nil;
            }
            
            if ([reqMngr.responseSerializer isKindOfClass:AFJSONResponseSerializer.class]
                && ((AFJSONResponseSerializer *)reqMngr.responseSerializer).readingOptions == 0) {
                ((AFJSONResponseSerializer *)reqMngr.responseSerializer).readingOptions = NSJSONReadingFragmentsAllowed;
            }
            [reqMngr.reachabilityManager startMonitoring];
            [s_mngrPool setObject:reqMngr forKey:identifier];
        }
    }
    
    _sessionConfig = nil;
    
    return reqMngr;
}

- (AFHTTPSessionManager *)requestManager
{
    if (nil == _requestManager) {
        _requestManager = [self dequeueRequestManagerWithIdentifier:self.requestManagerPrint];
    }
    
    return _requestManager;
}

- (void)setRequestManager:(AFHTTPSessionManager *)requestManager
{
    if ([requestManager.responseSerializer isKindOfClass:AFJSONResponseSerializer.class]
        && ((AFJSONResponseSerializer *)requestManager.responseSerializer).readingOptions == 0) {
        ((AFJSONResponseSerializer *)requestManager.responseSerializer).readingOptions = NSJSONReadingFragmentsAllowed;
    }
    
    _requestManager = requestManager;
}

- (instancetype)initWithSession:(nullable AFHTTPSessionManager *)mng
{
    self = [self initWithSessionConfiguration:nil];
    if (self) {
        _requestManager = mng;
    }
    return self;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [self init];
    if (self) {
        _sessionConfig = configuration;
    }
    return self;
}


- (BOOL)canAddRequest:(id<TCHTTPRequest>)request error:(NSError * _Nullable __strong * _Nullable)error
{
    NSCParameterAssert(request.observer);
    
    if (nil == request.observer) {
        if (NULL != error) {
            *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorUnknown
                                     userInfo:@{NSLocalizedFailureReasonErrorKey: @"Callback Error",
                                                NSLocalizedDescriptionKey: @"delegate or resultBlock of request must be set"}];
        }
        return NO;
    }
    
#ifdef DEBUG
    NSDictionary *headerFieldValueDic = [self customHeaderValueForRequest:request];
    for (NSString *httpHeaderField in headerFieldValueDic) {
        NSString *value = headerFieldValueDic[httpHeaderField];
        if (![httpHeaderField isKindOfClass:NSString.class] || ![value isKindOfClass:NSString.class]) {
            if (NULL != error) {
                *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorUnsupportedURL
                                         userInfo:@{NSLocalizedFailureReasonErrorKey: @"HTTP HEAD Error",
                                                    NSLocalizedDescriptionKey: @"class of key/value in headerFieldValueDictionary should be NSString."}];
            }
            
            return NO;
        }
    }
#endif // DEBUG
    
    return YES;
}

- (BOOL)addRequest:(id<TCHTTPRequest, TCHTTPReqAgentDelegate>)request error:(NSError * _Nullable __strong * _Nullable)error
{
    if (![self canAddRequest:request error:error]) {
        return NO;
    }
    
    BOOL polling = NO;
    if (nil != request.timerPolicy && nil != request.requestTask) {
        if (request.timerPolicy.isValid) {
            polling = YES;
            
        } else {
            return NO;
        }
    }
    
    AFHTTPSessionManager *requestMgr = self.requestManager;
    @synchronized(requestMgr) {
        if (polling) {
            [self generateTaskFor:request polling:YES];
            return YES;
        }
        
        BOOL rawJSON = kTCHTTPMethodPostJSON == request.method;
        if (rawJSON) {
            if (![requestMgr.requestSerializer isKindOfClass:AFJSONRequestSerializer.class ]) {
                _httpSerializer = requestMgr.requestSerializer;
                requestMgr.requestSerializer = self.jsonSerializer;
            }
        } else {
            if ([requestMgr.requestSerializer isKindOfClass:AFJSONRequestSerializer.class]) {
                if (nil == _httpSerializer) {
                    _httpSerializer = AFHTTPRequestSerializer.serializer;
                }
                requestMgr.requestSerializer = _httpSerializer;
            }
        }
        
        requestMgr.requestSerializer.timeoutInterval = MAX(self.timeoutInterval, request.timeoutInterval);
        
        // if api need server username and password
        if (self.authorizationUsername.length > 0) {
            [requestMgr.requestSerializer setAuthorizationHeaderFieldWithUsername:self.authorizationUsername password:self.authorizationPassword];
        } else {
            [requestMgr.requestSerializer clearAuthorizationHeader];
        }
        
        [self generateTaskFor:request polling:NO];
    }
    
    return YES;
}

- (void)fireDownloadTaskFor:(id<TCHTTPRequest, TCHTTPReqAgentDelegate>)request downloadUrl:(NSURL *)downloadUrl successBlock:(void (^)(NSURLSessionTask *task, id responseObject))successBlock failureBlock:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock
{
    NSCParameterAssert(request);
    NSCParameterAssert(downloadUrl);
    NSCParameterAssert(successBlock);
    NSCParameterAssert(failureBlock);
    
    __block NSURLSessionTask *task = nil;
    
    NSURL * (^destination)(NSURL *targetPath, NSURLResponse *response) = ^(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:request.streamPolicy.downloadDestinationPath];
    };
    
    __weak typeof(self) wSelf = self;
    void (^completionHandler)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (nil != error || nil == filePath) {
            if (request.streamPolicy.shouldResumeDownload && nil != error) {
                if ([error.domain isEqualToString:NSPOSIXErrorDomain] && ENOENT == error.code) {
                    [wSelf clearCachedResumeDataForRequest:request];
                }
            }
            failureBlock(task, error);
            
        } else {
            [wSelf clearCachedResumeDataForRequest:request];
            successBlock(task, filePath);
        }
    };
    
    AFHTTPSessionManager *requestMgr = self.requestManager;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:downloadUrl
                                                              cachePolicy:requestMgr.requestSerializer.cachePolicy
                                                          timeoutInterval:requestMgr.requestSerializer.timeoutInterval];
    NSDictionary *headers = [self customHeaderValueForRequest:request];
    for (NSString *key in headers) {
        [urlRequest setValue:[NSString stringWithFormat:@"%@", headers[key]] forHTTPHeaderField:key];
    }
    if (request.streamPolicy.shouldResumeDownload) {
        [self loadResumeData:^(NSData *data) {
            if (nil != data) {
                task = [requestMgr downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
                    request.streamPolicy.progress = downloadProgress;
                } destination:destination completionHandler:completionHandler];
            }
            
            if (nil == task) {
                task = [requestMgr downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
                    request.streamPolicy.progress = downloadProgress;
                } destination:destination completionHandler:completionHandler];
            }
            
            [task tc_makePersistentResumeCapable];
            task.tc_resumeIdentifier = request.streamPolicy.downloadIdentifier;
            task.tc_resumeCacheDirectory = request.streamPolicy.downloadResumeCacheDirectory;
            [wSelf addTask:task toRequest:request];
        } forPolicy:request.streamPolicy];
        
    } else {
        task = [requestMgr downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            request.streamPolicy.progress = downloadProgress;
        } destination:destination completionHandler:completionHandler];
        
        task.tc_resumeIdentifier = request.streamPolicy.downloadIdentifier;
        task.tc_resumeCacheDirectory = request.streamPolicy.downloadResumeCacheDirectory;
        [self addTask:task toRequest:request];
    }
}

- (void)generateTaskFor:(id<TCHTTPRequest, TCHTTPReqAgentDelegate>)request polling:(BOOL)polling
{
    __weak typeof(self) wSelf = self;
    void (^successBlock)(NSURLSessionTask *task, id responseObject) = ^(NSURLSessionTask *task, id responseObject) {
        NSCAssert(NSThread.isMainThread, @"not main thread");
        request.rawResponseObject = responseObject;
        [wSelf handleRequestResult:request success:YES error:nil];
    };
    void (^failureBlock)(NSURLSessionTask *task, NSError *error) = ^(NSURLSessionTask *task, NSError *error) {
        NSCAssert(NSThread.isMainThread, @"not main thread");
        [wSelf handleRequestResult:request success:NO error:error];
    };
    
    
    NSURLSessionTask *task = nil;
    AFHTTPSessionManager *requestMgr = self.requestManager;
    
    if (polling && nil != request.requestTask.originalRequest) {
        NSURLRequest *req = request.requestTask.originalRequest.copy;
        task = [requestMgr dataTaskWithRequest:req
                                uploadProgress:nil
                              downloadProgress:nil
                             completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                 if (nil != error) {
                                     failureBlock(task, error);
                                 } else {
                                     successBlock(task, responseObject);
                                 }
                             }];
        [self addTask:task toRequest:request];
        return;
    }
    
    // if api need add custom value to HTTPHeaderField
    if (request.method != kTCHTTPMethodDownload) {
        NSDictionary *headerFieldValueDic = [self customHeaderValueForRequest:request];
        for (NSString *httpHeaderField in headerFieldValueDic) {
            NSString *value = headerFieldValueDic[httpHeaderField];
            [requestMgr.requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    NSURL *url = [self buildRequestUrlForRequest:request];
    NSCParameterAssert(url);
    
    id param = request.parameters;
    if (!request.ignoreParamFilter && [self.urlFilter respondsToSelector:@selector(filteredParamForParam:)]) {
        param = [self.urlFilter filteredParamForParam:param];
    }
    
    switch (request.method) {
            
        case kTCHTTPMethodGet: {
            task = [requestMgr GET:url.absoluteString parameters:param progress:nil success:successBlock failure:failureBlock];
            break;
        }
            
        case kTCHTTPMethodPost:
        case kTCHTTPMethodPostJSON: {
            if (nil != request.streamPolicy.constructingBodyBlock) {
                task = [requestMgr POST:url.absoluteString parameters:param constructingBodyWithBlock:request.streamPolicy.constructingBodyBlock progress:^(NSProgress * _Nonnull uploadProgress) {
                    request.streamPolicy.progress = uploadProgress;
                } success:successBlock failure:failureBlock];
                request.streamPolicy.constructingBodyBlock = nil;
            } else {
                task = [requestMgr POST:url.absoluteString parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
                    request.streamPolicy.progress = uploadProgress;
                } success:successBlock failure:failureBlock];
            }
            break;
        }
            
        case kTCHTTPMethodPut: {
            task = [requestMgr PUT:url.absoluteString parameters:param success:successBlock failure:failureBlock];
            break;
        }
            
        case kTCHTTPMethodDownload: {
            NSCParameterAssert(request.streamPolicy.downloadDestinationPath);
            NSURL *downloadURL = [url appendParamIfNeed:param orderKey:nil];
            NSCParameterAssert(downloadURL);
            
            if (nil == downloadURL || request.streamPolicy.downloadDestinationPath.length < 1) {
                break; // !!!: break here, no return
            }
            
            [self fireDownloadTaskFor:request downloadUrl:downloadURL successBlock:successBlock failureBlock:failureBlock];
            return;
        }
            
        case kTCHTTPMethodHead: {
            task = [requestMgr HEAD:url.absoluteString parameters:param success:^(NSURLSessionDataTask * _Nonnull task) {
                successBlock(task, nil);
            } failure:failureBlock];
            break;
        }
            
        case kTCHTTPMethodDelete: {
            task = [requestMgr DELETE:url.absoluteString parameters:param success:successBlock failure:failureBlock];
            break;
        }
            
        case kTCHTTPMethodPatch: {
            task = [requestMgr PATCH:url.absoluteString parameters:param success:successBlock failure:failureBlock];
            break;
        }
            
        default: {
            // build custom url request
            NSURLRequest *customUrlRequest = request.customUrlRequest;
            if (nil != customUrlRequest) {
                task = [requestMgr dataTaskWithRequest:customUrlRequest
                                        uploadProgress:nil
                                      downloadProgress:nil
                                     completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                                         if (nil != error) {
                                             failureBlock(task, error);
                                         } else {
                                             successBlock(task, responseObject);
                                         }
                                     }];
            }
            break;
        }
    }
    
    [self addTask:task toRequest:request];
}

- (void)addTask:(NSURLSessionTask *)task toRequest:(id<TCHTTPRequest, TCHTTPReqAgentDelegate>)request
{
    AFHTTPSessionManager *requestMgr = self.requestManager;
    for (NSString *httpHeaderField in [self customHeaderValueForRequest:request]) {
        [requestMgr.requestSerializer setValue:nil forHTTPHeaderField:httpHeaderField];
    }
    
    if (nil != task) {
        request.rawResponseObject = nil;
        request.requestTask = task;
        request.state = kTCRequestNetwork;
        [self addRequestToPool:request];
        if (task.state == NSURLSessionTaskStateSuspended) {
            [task resume];
        }
    } else {
        id<TCHTTPRespValidator> validator = request.responseValidator;
        if (nil != validator) {
            [validator reset];
            validator.error = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorUnknown
                                              userInfo:@{NSLocalizedFailureReasonErrorKey: @"fire request error",
                                                         NSLocalizedDescriptionKey: @"generate NSURLSessionTask instances failed."}];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [request requestResponded:NO clean:YES];
        });
    }
}


#pragma mark - TCHTTPRequestAgent

- (void)addRequestToPool:(id<TCHTTPRequest>)request
{
    NSCParameterAssert(request);
    
    [_poolLock lock];
    NSMapTable<id<NSCoding>, id<TCHTTPRequest>> *map = [_requestPool objectForKey:request.observer];
    if (nil == map) {
        map = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
        [_requestPool setObject:map forKey:request.observer];
    }
    
    NSString *identifier = request.identifier;
    id<TCHTTPRequest> preRequest = [map objectForKey:identifier];
    if (request == preRequest) {
        [_poolLock unlock];
        return;
    }
    
    if (nil != preRequest) {
        if (!request.overrideIfImpact) {
            [_poolLock unlock];
            return;
        }
        [map removeObjectForKey:identifier];
        [preRequest cancel]; // !!!: may call [_poolLock lock];
    }
    
    [map setObject:request forKey:identifier];
    [_poolLock unlock];
}


- (void)removeRequestFromPool:(id<TCHTTPRequest>)request
{
    [self removeRequest:request forObserver:request.observer forIdentifier:request.identifier];
}

- (void)removeRequest:(id<TCHTTPRequest>)mRequest forObserver:(__unsafe_unretained id)observer forIdentifier:(id<NSCoding>)identifier
{
    [_poolLock lock];
    
    NSMapTable<id<NSCoding>, id<TCHTTPRequest>> *map = [_requestPool objectForKey:observer];
    
    if (nil == map) {
        [_poolLock unlock];
        return;
    }
    
    if (nil != identifier) {
        id<TCHTTPRequest> request = [map objectForKey:identifier];
        if (nil != mRequest && request != mRequest) {
            [_poolLock unlock];
            return;
        }
        
        if (nil != request) {
            [map removeObjectForKey:identifier];
            if (map.count < 1) {
                [_requestPool removeObjectForKey:observer];
            }
            
            [request cancel];
        }
    } else {
        [_requestPool removeObjectForKey:observer];
        [map.dictionaryRepresentation.allValues makeObjectsPerformSelector:@selector(cancel)];
    }
    
    [_poolLock unlock];
}

- (void)removeRequestObserver:(__unsafe_unretained id)observer forIdentifier:(id<NSCoding>)identifier
{
    [self removeRequest:nil forObserver:observer forIdentifier:identifier];
}

- (void)removeRequestObserver:(__unsafe_unretained id)observer
{
    [self removeRequestObserver:observer forIdentifier:nil];
}

- (void)removeAllRequests
{
    [_poolLock lock];
    NSMutableArray<id<TCHTTPRequest>> *arry = NSMutableArray.array;
    for (id key in _requestPool) {
        NSArray<id<TCHTTPRequest>> *requests = [_requestPool objectForKey:key].dictionaryRepresentation.allValues;
        if (nil != requests) {
            [arry addObjectsFromArray:requests];
        }
    }
    [arry makeObjectsPerformSelector:@selector(cancel)];
    [_requestPool removeAllObjects];
    [_poolLock unlock];
}

- (void)removeAllCachedResponses
{
    if (nil != _memCache) {
        @synchronized(_memCache) {
            [_memCache removeAllObjects];
        }
    }
    NSString *path = self.cachePathForResponse;
    if (nil != path) {
        [NSFileManager.defaultManager removeItemAtPath:path error:NULL];
    }
}


#pragma mark -

- (NSURL *)buildRequestUrlForRequest:(id<TCHTTPRequest>)request
{
    NSString *queryUrl = request.apiUrl;
    
    if (nil != self.urlFilter && [self.urlFilter respondsToSelector:@selector(filteredUrlForUrl:)]) {
        queryUrl = [self.urlFilter filteredUrlForUrl:queryUrl];
    }
    
    if (0 == [queryUrl rangeOfString:@"http" options:NSCaseInsensitiveSearch | NSAnchoredSearch].location) {
        return [NSURL URLWithString:queryUrl];
    }
    
    NSURL *baseUrl = nil;
    if (request.baseUrl.length > 0) {
        baseUrl = [NSURL URLWithString:request.baseUrl];
    } else {
        baseUrl = self.baseURL;
    }
    
    return [baseUrl URLByAppendingPathComponent:queryUrl];
}

- (id<TCHTTPRespValidator>)responseValidatorForRequest:(id<TCHTTPRequest>)request
{
    return [[self.responseValidorClass alloc] init];
}


#pragma mark - request callback

- (void)handleRequestResult:(id<TCHTTPRequest, TCHTTPReqAgentDelegate>)request success:(BOOL)success error:(NSError *)error
{
    dispatch_block_t block = ^{
        request.state = kTCRequestFinished;
        
        BOOL isValid = success;
        
        id<TCHTTPRespValidator> validator = request.responseValidator;
        if (nil != validator) {
            if ([validator respondsToSelector:@selector(validateHTTPResponse:fromCache:forRequest:error:)]) {
                isValid = [validator validateHTTPResponse:request.responseObject fromCache:NO forRequest:request error:error];
            } else {
                if (isValid) {
                    if ([validator respondsToSelector:@selector(validateHTTPResponse:fromCache:forRequest:)]) {
                        isValid = [validator validateHTTPResponse:request.responseObject fromCache:NO forRequest:request];
                    }
                } else {
                    [validator reset];
                    validator.error = error;
                }
            }
        }
        
        [request requestResponded:isValid clean:YES];
    };
    
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


#pragma mark - Cache

- (dispatch_queue_t)responseQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

- (void)storeCachedResponse:(id)response forCachePolicy:(TCHTTPCachePolicy *)cachePolicy finish:(dispatch_block_t)block
{
    @synchronized(self.memCache) {
        [self.memCache setObject:response forKey:cachePolicy.cacheFileName];
    }
    
    NSString *path = cachePolicy.cacheFilePath;
    
    dispatch_async(self.responseQueue, ^{
        @autoreleasepool {
            if (nil != path) {
                if (@available(iOS 11, *)) {
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response requiringSecureCoding:NO error:NULL];
                    if (nil == data || ![data writeToFile:path atomically:YES]) {
                        NSCAssert(false, @"write response failed.");
                    }
                } else {
                    if (![NSKeyedArchiver archiveRootObject:response toFile:path]) {
                        NSCAssert(false, @"write response failed.");
                    }
                }
            }

            if (nil != block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                });
            }
        }
    });
}

- (void)cachedResponseForRequest:(id<TCHTTPRequest>)request result:(void (^)(id response))result
{
    NSCParameterAssert(result);
    
    if (nil == result) {
        return;
    }
    
    TCHTTPCachePolicy *cachePolicy = request.cachePolicy;
    
    if (nil != cachePolicy.cachedResponse) {
        result(cachePolicy.cachedResponse);
        return;
    }
    
    NSString *path = cachePolicy.cacheFilePath;
    if (nil == path) {
        result(nil);
        return;
    }
    
    NSFileManager *fileMngr = NSFileManager.defaultManager;
    BOOL isDir = NO;
    if (![fileMngr fileExistsAtPath:path isDirectory:&isDir] || isDir) {
        result(nil);
        return;
    }
    
    if (request.method == kTCHTTPMethodDownload) {
        cachePolicy.cachedResponse = path;
        result(cachePolicy.cachedResponse);
    } else {
        @synchronized(self.memCache) {
            cachePolicy.cachedResponse = [self.memCache objectForKey:cachePolicy.cacheFileName];
        }
        if (nil != cachePolicy.cachedResponse) {
            result(cachePolicy.cachedResponse);
            return;
        }
        
        dispatch_async(self.responseQueue, ^{
            static NSSet<Class> *klasses = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                klasses = [NSSet setWithObjects:NSDictionary.class, NSArray.class, NSString.class, NSURL.class,
                           NSNumber.class, NSData.class, NSDate.class, NSError.class, NSNull.class, nil];
            });
            
            @autoreleasepool {
                id cachedResponse = nil;
                @try {
                    if (@available(iOS 11, *)) {
                        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways|NSDataReadingUncached error:NULL];
                        if (data.length > 0) {
                            cachedResponse = [NSKeyedUnarchiver unarchivedObjectOfClasses:klasses fromData:data error:NULL];
                        }
                        
                    } else {
                        cachedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
                    }
                }
                @catch (NSException *exception) {
                    cachedResponse = nil;
                    NSLog(@"%@", exception);
                }
                @finally {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cachePolicy.cachedResponse = cachedResponse;
                        result(cachedResponse);
                    });
                }
            }
        });
    }
}


@end
