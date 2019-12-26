//
//  UIWebView+TCWKWebView.m
//  TCKit
//
//  Created by jia on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#if !defined(__IPHONE_13_0) && (!defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION))

#import "UIWebView+TCWKWebView.h"
#import "UIView+TCWKWebView.h"
#import "NSObject+TCUtilities.h"

@implementation UIWebView (TCWKWebView)


+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(loadRequest:)];
    });
}

+ (NSString *)tc_systemUserAgent
{
    static NSString *s_userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_block_t block = ^{
            s_userAgent = [[[self alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        };
        NSCParameterAssert(NSThread.isMainThread);
        if (NSThread.isMainThread) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    });
    
    return s_userAgent;
}

- (void)clearCookies
{
    for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
        NSRange domainRange = [cookie.domain rangeOfString:self.request.URL.host];
        if (domainRange.location != NSNotFound) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSString *string = [self stringByEvaluatingJavaScriptFromString:javaScriptString];
    if (nil != completionHandler) {
        completionHandler(string, nil);
    }
}


- (void)tc_loadRequest:(NSURLRequest *)request
{
    self.originalRequest = request;
    [self tc_loadRequest:request];
}

- (id)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL
{
    [self loadData:[NSData dataWithContentsOfAlwaysMappedURL:URL] MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:readAccessURL];
    return URL;
}

- (nullable id)tc_loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    [self loadHTMLString:string baseURL:baseURL];
    return string;
}

- (void)tc_reload
{
    [self reload];
}

- (id)tc_goBack
{
    [self goBack];
    return @YES;
}


/* fix non-public api
 
#pragma mark -

- (UIView *)webHeaderView
{
    return [self bk_associatedValueForKey:_cmd];
}

- (void)setWebHeaderView:(UIView *)webHeaderView
{
    BOOL needResetTopInsets = NO;
    UIScrollView *scrollView = self.scrollView;
    
    UIView *headerView = self.webHeaderView;
    if (nil == headerView) {
        if (nil != webHeaderView) {
            needResetTopInsets = YES;
            headerView = webHeaderView;
        }
    } else {
        needResetTopInsets = YES;
        
        if (headerView != webHeaderView) {
            needResetTopInsets = YES;
            [headerView removeFromSuperview];
            headerView = webHeaderView;
        } else if (nil == webHeaderView) {
            [self bk_weaklyAssociateValue:nil withKey:@selector(webHeaderView)];
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
            [self bk_weaklyAssociateValue:headerView withKey:@selector(webHeaderView)];
        }
        
        NSCParameterAssert(headerView.superview == scrollView);
    }
    
    if (needResetTopInsets) {
        for (UIView *subView in scrollView.subviews) {
            // http://blog.csdn.net/hursing/article/details/8781386
            NSString *name = NSStringFromClass(subView.class);
            // [subView isKindOfClass:NSClassFromString(@"UIWebBrowserView")]
            if (name.length == 17 && [name containsString:@"Browser"] && [name hasSuffix:@"View"] && [name containsString:@"Web"]) {
                CGRect rect = subView.frame;
                rect.origin.y = CGRectGetMaxY(frame);
                subView.frame = rect;
                break;
            }
        }
    }
}
 
 */

@end

#endif
