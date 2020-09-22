//
//  WKWebView+TCWKWebView.m
//  TCKit
//
//  Created by jia on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import "WKWebView+TCWKWebView.h"
#import <objc/runtime.h>
#import "UIView+TCWKWebView.h"

#import "TCDefines.h"
#import "NSObject+TCUtilities.h"
#import "TCDebug.h"

@interface _LocalURLFixer : NSObject

@property (nonatomic, strong) NSURL *orgUrl;

@end


@implementation _LocalURLFixer
{
@private
    NSURL *_tmpPath;
}

- (void)dealloc
{
    if (nil != _tmpPath) {
        [NSFileManager.defaultManager removeItemAtURL:_tmpPath error:NULL];
    }
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
- (NSURL *)moveToTmp:(NSURL *)url
{
    _orgUrl = url;
    
    if (nil != _tmpPath) {
        if (![NSFileManager.defaultManager fileExistsAtPath:_tmpPath.path]) {
            _tmpPath = nil;
        }
    }
    
    if (nil == _tmpPath) {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        NSURL *tmpUrl = [NSURL fileURLWithPath:path];
        if ([NSFileManager.defaultManager copyItemAtURL:url.URLByDeletingLastPathComponent toURL:tmpUrl error:NULL]) {
            _tmpPath = tmpUrl;
        }
    }
    
    NSURL *dstUrl = url;
    if (nil != _tmpPath) {
        dstUrl = [_tmpPath URLByAppendingPathComponent:url.lastPathComponent];
    }

    return dstUrl;
}
#endif

@end


/* fix non-public api

@interface _WKWebViewExtra : NSObject
{
    @public
    NSArray<__kindof UIView *> *_kvoSubviews;
}

@property (nonatomic, weak) UIView *headerView;

@end


@implementation _WKWebViewExtra

- (void)dealloc
{
    self.kvoSubviews = nil;
}

- (void)setKvoSubviews:(NSArray<__kindof UIView *> *)kvoSubviews
{
    if (_kvoSubviews == kvoSubviews) {
        return;
    }
    
    for (UIView *subView in _kvoSubviews) {
        [subView removeObserver:self forKeyPath:PropertySTR(frame)];
    }
    
    _kvoSubviews = kvoSubviews;
    for (UIView *subView in _kvoSubviews) {
        [subView addObserver:self forKeyPath:PropertySTR(frame) options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)updateKVO:(WKWebView *)webView
{
    NSMutableArray *arry = NSMutableArray.array;
    for (UIView *subView in webView.scrollView.subviews) {
        if (CGSizeEqualToSize(subView.frame.size, CGSizeZero)) {
            [arry addObject:subView];
        } else {
            // [subView isKindOfClass:NSClassFromString(@"WKContentView")]
            NSString *name = NSStringFromClass(subView.class);
            if (name.length == 13 && [name hasSuffix:@"View"] && [name containsString:@"Content"] && [name hasPrefix:@"W"]) {
                [arry addObject:subView];
            }
        }
    }
    self.kvoSubviews = arry.copy;
}

- (void)fixKVOViews
{
    CGFloat h = CGRectGetMaxY(self.headerView.frame);
    for (UIView *subView in _kvoSubviews) {
        CGRect rect = subView.frame;
        if (ABS(CGRectGetMinY(rect) - h) > 0.001f) {
            rect.origin.y = h;
            subView.frame = rect;
        }
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context
{
    if ([_kvoSubviews containsObject:object] && [keyPath isEqualToString:PropertySTR(frame)]) { // bug fix for iOS9
        NSValue *value = change[NSKeyValueChangeNewKey];
        if ([value isKindOfClass:NSValue.class]) {
            CGRect frame = value.CGRectValue;
            CGFloat head = CGRectGetMaxY(_headerView.frame);
            if (ABS(CGRectGetMinY(frame) - head) > 0.001f) {
                frame.origin.y = head;
                ((UIView *)object).frame = frame;
            }
        }
    }
}


@end
 
 */


@implementation WKWebView (TCWKWebView)

//@dynamic dataDetectorTypes;

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(loadRequest:)];
        [self tc_swizzle:@selector(canPerformAction:withSender:)];
        
        // fix non-public api
        //    [self tc_swizzle:@selector(layoutSubviews)];
    });
}

- (BOOL)tc_canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(selectAll:)) {
        return YES;
    }
    return [self tc_canPerformAction:action withSender:sender];
}

- (nullable id)tc_loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    return [self loadHTMLString:string baseURL:baseURL];
}

- (void)tc_reload
{
    [self reload];
}

+ (NSString *)tc_systemUserAgent
{
    static NSString *s_userAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 12_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148";
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_block_t block = ^{
            __block WKWebView *view = [[self alloc] init];
            [view evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString * _Nullable result, NSError * _Nullable error) {
                if (nil != result) {
                    s_userAgent = result;
                }
                view = nil;
            }];
        };
        
        if (NSThread.isMainThread) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    });
    
    return s_userAgent;
}

- (id)tc_goBack
{
    return [self goBack];
}

- (id<WKNavigationDelegate, WKUIDelegate>)delegate
{
    id delegate = self.navigationDelegate ?: (id)self.UIDelegate;
    return (id<WKNavigationDelegate, WKUIDelegate>)delegate;
}

- (void)setDelegate:(id<WKNavigationDelegate, WKUIDelegate>)delegate
{
    self.navigationDelegate = delegate;
    self.UIDelegate = delegate;
}

- (BOOL)scalesPageToFit
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setScalesPageToFit:(BOOL)scalesPageToFit
{
    if (scalesPageToFit == self.scalesPageToFit) {
        return;
    }
    
    static NSString *const jScript = @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
    
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    
    if (scalesPageToFit) {
        [self.configuration.userContentController addUserScript:wkUScript];
    } else {
        NSMutableArray *userScripts = self.configuration.userContentController.userScripts.mutableCopy;
        NSUInteger index = NSNotFound;
        for (WKUserScript *script in userScripts) {
            if ([script.source isEqualToString:jScript]) {
                index = [userScripts indexOfObject:script];
                break;
            }
        }
        
        if (index != NSNotFound) {
            [userScripts removeObjectAtIndex:index];
        }
        
        for (WKUserScript *script in userScripts) {
            [self.configuration.userContentController addUserScript:script];
        }
    }

    objc_setAssociatedObject(self, @selector(scalesPageToFit), @(scalesPageToFit), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable WKNavigation *)tc_loadRequest:(NSURLRequest *)request
{
    // load local request on iOS8, must move files to tmp
    typeof(request) req = request;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
    if (@available(iOS 9, *)) {
    } else if (nil != req.URL && req.URL.isFileURL &&
        ![req.URL.path hasPrefix:NSTemporaryDirectory()]) {
        
        _LocalURLFixer *fixer = objc_getAssociatedObject(self, _cmd);
        if (nil != fixer && ![fixer.orgUrl isEqual:req.URL]) {
            objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        if (nil == fixer) {
            fixer = [[_LocalURLFixer alloc] init];
            objc_setAssociatedObject(self, _cmd, fixer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        NSMutableURLRequest *mReq = req.mutableCopy;
        mReq.URL = [fixer moveToTmp:req.URL];
        req = mReq.copy;
    }
#endif
    
    self.originalRequest = req;
    return [self tc_loadRequest:req];
}

/*
- (void)setDataDetectorTypes:(NSUInteger)dataDetectorTypes
{
    return;
}

- (NSUInteger)dataDetectorTypes
{
    return 0; // UIDataDetectorTypeNone
}
 */

- (void)clearCookies
{
    if (Nil != WKWebsiteDataStore.class) {
        WKWebsiteDataStore *dateStore = [WKWebsiteDataStore defaultDataStore];
        [dateStore fetchDataRecordsOfTypes:WKWebsiteDataStore.allWebsiteDataTypes completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
            for (WKWebsiteDataRecord *record in records) {
                NSRange range = [record.displayName rangeOfString:self.originalRequest.URL.host];
                if (range.location != NSNotFound) {
                    [dateStore removeDataOfTypes:record.dataTypes
                                  forDataRecords:@[record]
                               completionHandler:^{
                                   DLog(@"Cookies for %@ deleted successfully",record.displayName);
                               }];
                }
            }
        }];
        
    } else {
        NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        NSString *cookiesPath = [libraryPath stringByAppendingPathComponent:@"Cookies"];
        [NSFileManager.defaultManager removeItemAtPath:cookiesPath error:NULL];
    }
}

/* fix non-public api
#pragma mark -

- (void)tc_layoutSubviews
{
    [self tc_layoutSubviews];
    
    // bug fix for iOS9
    [self.obsvrExtra fixKVOViews];
}

- (_WKWebViewExtra *)obsvrExtra
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setObsvrExtra:(_WKWebViewExtra *)obsvrExtra
{
    objc_setAssociatedObject(self, @selector(obsvrExtra), obsvrExtra, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)webHeaderView
{
    return self.obsvrExtra.headerView;
}

- (void)setWebHeaderView:(UIView *)webHeaderView
{
    _WKWebViewExtra *extra = self.obsvrExtra;
    
    BOOL needUpdateKVO = NO;
    
    if (nil == webHeaderView) {
        self.obsvrExtra = nil;
    } else if (nil == extra) {
        extra = [[_WKWebViewExtra alloc] init];
        self.obsvrExtra = extra;
        needUpdateKVO = YES;
    }

    BOOL needUpdate = NO;
    UIScrollView *scrollView = self.scrollView;
    
    UIView *headerView = self.webHeaderView;
    needUpdateKVO = needUpdateKVO || (headerView != webHeaderView);
    if (needUpdateKVO) {
        [extra updateKVO:self];
    }
    
    if (nil == headerView) {
        if (nil != webHeaderView) {
            needUpdate = YES;
            headerView = webHeaderView;
        }
    } else {
        needUpdate = YES;
        
        if (headerView != webHeaderView) {
            needUpdate = YES;
            [headerView removeFromSuperview];
            headerView = webHeaderView;
        }
    }
    
    CGRect frame = CGRectZero;
    if (nil != headerView) {
        frame = headerView.frame;
        frame.origin = CGPointZero;
        headerView.frame = frame;
        
        if (headerView.superview == nil) {
            [scrollView addSubview:headerView];
            headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
            extra.headerView = headerView;
        }
        
        NSCParameterAssert(headerView.superview == scrollView);
    }
    
    if (needUpdate) {
        [extra fixKVOViews];
    }
}

@end


@implementation UIScrollView (HeaderView)

+ (void)load
{
    if (Nil != WKWebView.class) {
        [self tc_swizzle:@selector(setContentSize:)];
    }
}

- (void)tc_setContentSize:(CGSize)contentSize
{
    // [self isKindOfClass:NSClassFromString(@"WKScrollView")]
    NSString *name = NSStringFromClass(self.class);
    if (name.length == 13 && [name hasSuffix:@"ScrollView"] && [name hasPrefix:@"WKS"]) {
        
        CGFloat height = 0.0f;
        for (UIView *view in self.subviews) {
            CGFloat h = CGRectGetMaxY(view.frame);
            if (h > height) {
                height = h;
            }
        }
        
        if (contentSize.height < height) {
            contentSize.height = height;
        }
    }
    
    [self tc_setContentSize:contentSize];
}
 */


@end
 
#endif

