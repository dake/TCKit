//
//  UIScrollView+TCPullToRefresh.m
//  TCKit
//
//  Created by dake on 15/4/26.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import "UIScrollView+TCPullToRefresh.h"
#import <objc/runtime.h>
#import "TCProxyDelegate.h"
#import "NSObject+TCUtilities.h"


@interface TCScrollViewDelegateProxy : TCProxyDelegate <UIScrollViewDelegate>

@end

@implementation TCScrollViewDelegateProxy


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    __strong typeof(scrollView.delegate) delegate = scrollView.delegate;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate scrollViewDidScroll:scrollView];
    }
    
    [scrollView tc_scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    __strong typeof(scrollView.delegate) delegate = scrollView.delegate;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate scrollViewDidEndDecelerating:scrollView];
    }
    
    [scrollView tc_scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    __strong typeof(scrollView.delegate) delegate = scrollView.delegate;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    
    [scrollView tc_scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}


@end


#pragma mark - UIScrollView+TCPullToRefresh


static NSInteger const kHeaderTag = 84211 + 2;
static NSInteger const kFooterTag = 84211 + 3;

static char const kPullRefreshDelegateKey;
static char const kLoadTypeKey;
static char const kRefreshEnabledKey;
static char const kLoadMoreEnabledKey;
static char const kReloadingKey;
static char const kLoadingMoreKey;
static char const kListModeKey;

static char const kHeaderClassKey;


@implementation UIScrollView (TCPullToRefresh)

@dynamic loadType;
@dynamic listMode;

@dynamic refreshEnabled;
@dynamic loadMoreEnabled;
@dynamic reloading;
@dynamic loadingMore;

@dynamic refreshHeaderView;
@dynamic pullRefreshDelegate;


+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(delegate) to:@selector(pullrefresh_delegate)];
        [self tc_swizzle:@selector(setDelegate:) to:@selector(setPullrefresh_delegate:)];
    });
}


// !!!: fix none weak delegate crash < iOS9
- (void *)pullrefresh_delegate
{
    if (self.listMode == kTCPullRefreshModeNone) {
        return self.pullrefresh_delegate;
    } else {
        TCScrollViewDelegateProxy *proxy = objc_getAssociatedObject(self, @selector(delegateProxy));
        if (nil == proxy.target) {
            objc_setAssociatedObject(self, @selector(delegateProxy), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return (__bridge void *)proxy.target;
    }
}

- (void)setPullrefresh_delegate:(id<UIScrollViewDelegate>)delegate
{
    if (self.listMode == kTCPullRefreshModeNone) {
        [self setPullrefresh_delegate:delegate];
        objc_setAssociatedObject(self, @selector(delegateProxy), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        if (nil != delegate) {
            self.delegateProxy.target = delegate;
            [self setPullrefresh_delegate:self.delegateProxy];
        } else {
            [self setPullrefresh_delegate:nil];
            objc_setAssociatedObject(self, @selector(delegateProxy), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (TCScrollViewDelegateProxy *)delegateProxy
{
    TCScrollViewDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (nil == proxy) {
        if (nil != self.pullrefresh_delegate) {
            proxy = [TCScrollViewDelegateProxy proxyWithTarget:self.pullrefresh_delegate];
            objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    } else if (nil == proxy.target) {
        [self setPullrefresh_delegate:nil];
        objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return proxy;
}


- (UIView *)loadMoreView
{
    UIView *view = [self viewWithTag:kFooterTag];
    return self == view ? nil : view;
}

- (UIView *)refreshHeaderView
{
    UIView *view = [self viewWithTag:kHeaderTag];
    if ([view conformsToProtocol:@protocol(TCRefreshHeaderInterface)]) {
        return view;
    }
    return nil;
}


- (TCLoadDataType)loadType
{
    return [objc_getAssociatedObject(self, &kLoadTypeKey) integerValue];
}

- (void)setLoadType:(TCLoadDataType)loadType
{
    objc_setAssociatedObject(self, &kLoadTypeKey, @(loadType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)refreshEnabled
{
    return [objc_getAssociatedObject(self, &kRefreshEnabledKey) boolValue];
}

- (void)setRefreshEnabled:(BOOL)refreshEnabled
{
    objc_setAssociatedObject(self, &kRefreshEnabledKey, @(refreshEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)loadMoreEnabled
{
    return [objc_getAssociatedObject(self, &kLoadMoreEnabledKey) boolValue];
}

- (void)setLoadMoreEnabled:(BOOL)loadMoreEnabled
{
    objc_setAssociatedObject(self, &kLoadMoreEnabledKey, @(loadMoreEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)reloading
{
    return [objc_getAssociatedObject(self, &kReloadingKey) boolValue];
}

- (void)setReloading:(BOOL)reloading
{
    objc_setAssociatedObject(self, &kReloadingKey, @(reloading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)loadingMore
{
    return [objc_getAssociatedObject(self, &kLoadingMoreKey) boolValue];
}

- (void)setLoadingMore:(BOOL)loadingMore
{
    objc_setAssociatedObject(self, &kLoadingMoreKey, @(loadingMore), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (id<TCPullToRefreshDelegate>)pullRefreshDelegate
{
    return objc_getAssociatedObject(self, &kPullRefreshDelegateKey);
}

- (void)setPullRefreshDelegate:(id<TCPullToRefreshDelegate>)pullRefreshDelegate
{
    objc_setAssociatedObject(self, &kPullRefreshDelegateKey, pullRefreshDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (CGFloat)priorContentOffsetY
{
    return (CGFloat)[objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setPriorContentOffsetY:(CGFloat)priorContentOffsetY
{
    objc_setAssociatedObject(self, @selector(priorContentOffsetY), @(priorContentOffsetY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (TCPullRefreshMode)listMode
{
    return [objc_getAssociatedObject(self, &kListModeKey) integerValue];
}

- (void)setListMode:(TCPullRefreshMode)listMode
{
    if (listMode == self.listMode) {
        return;
    }
    
    objc_setAssociatedObject(self, &kListModeKey, @(listMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (listMode != kTCPullRefreshModeNone && nil != self.delegateProxy) {
        [self setPullrefresh_delegate:self.delegateProxy];
    }
    
    switch ((NSInteger)listMode) {
        case kTCPullRefreshModeNone:
            [self clearRefreshOrReloadView];
            break;
            
        case kTCPullRefreshModeRefresh | kTCPullRefreshModeLoadMore2:
            self.loadMoreEnabled = YES;
            
        case kTCPullRefreshModeRefresh: {
            
            if (nil != self.loadMoreView) {
                [self.loadMoreView removeFromSuperview];
            }
            
            [self setUpRefreshHeaderView];
            break;
        }
            
        case kTCPullRefreshModeLoadMore:
            if (nil != self.refreshHeaderView) {
                [self.refreshHeaderView removeFromSuperview];
            }
            
            [self setUpLoadMoreHeaderView];
            break;
            
        case kTCPullRefreshModeLoadMore2:
            self.loadMoreEnabled = YES;
            break;
            
        case kTCPullRefreshModeAll:
            [self setUpRefreshHeaderView];
            [self setUpLoadMoreHeaderView];
            break;
            
        default:
            [self clearRefreshOrReloadView];
            break;
    } // end of switch
}


#pragma mark - views

// 初始化顶部刷新view
- (void)setUpRefreshHeaderView
{
    if (Nil == self.headerClass) {
        return;
    }
    
    self.refreshEnabled = YES;
    
    UIView<TCRefreshHeaderInterface> *refreshHeaderView = self.refreshHeaderView;
    if (nil == refreshHeaderView) {
        CGRect frame = self.bounds;
        frame.origin.y = -frame.size.height;
        refreshHeaderView = [[self.headerClass alloc] initWithFrame:frame];
        refreshHeaderView.delegate = self;
        refreshHeaderView.contentInset = self.contentInset;
        refreshHeaderView.tag = kHeaderTag;
        [self addSubview:refreshHeaderView];
        
        //  update the last update date
        [refreshHeaderView refreshLastUpdatedDate];
    }
}

- (void)setUpLoadMoreHeaderView
{
    self.loadMoreEnabled = YES;
    
    if (nil == self.loadMoreView) {
        CGRect frame = self.bounds;
        frame.origin.y = frame.size.height;
        UIView *loadMoreView = [[UIView alloc] initWithFrame:frame];
        loadMoreView.tag = kFooterTag;
        //        _loadMoreView.delegate = self;
        loadMoreView.hidden = YES;
        [self addSubview:loadMoreView];
    }
}


- (void)clearRefreshOrReloadView
{
    if (nil != self.refreshHeaderView) {
        [self.refreshHeaderView removeFromSuperview];
    }
    
    if (nil != self.loadMoreView) {
        [self.loadMoreView removeFromSuperview];
    }
    
    self.refreshEnabled = NO;
    self.loadMoreEnabled = NO;
}


#pragma mark - TCPullToRefresh

- (Class)headerClass
{
    return objc_getAssociatedObject(self, &kHeaderClassKey);
}

- (void)registerHeaderClass:(Class<TCRefreshHeaderInterface>)headerClass
{
    objc_setAssociatedObject(self, &kHeaderClassKey, headerClass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)reloadViewDataSource:(BOOL)animated
{
    self.reloading = YES;
    self.loadType = kTCRefreshPages;
    
    if (nil != self.refreshHeaderView && self.refreshEnabled) {
        if (animated) {
            self.refreshHeaderView.contentInset = self.contentInset;
            [self.refreshHeaderView showRefreshView:self];
        }
    }
}

- (void)doneLoadingViewData
{
    if (self.reloading) {
        if (nil != self.refreshHeaderView && self.refreshEnabled) {
            if (!self.refreshHeaderView.hidden) {
                [self.refreshHeaderView tcRefreshScrollViewDataSourceDidFinishedLoading:self];
            }
        }
    }
    
    // 更新翻页状态
    if (nil != self.loadMoreView && self.loadMoreEnabled && (self.listMode & kTCPullRefreshModeLoadMore)) {
        //        [_loadMoreView updateMoreViewState:self.collectionView];
    }
    
    self.reloading = NO;
}

- (void)loadMoreViewDataSource
{
    self.loadingMore = YES;
    self.loadType = kTCLoadNextPage;
}

- (void)doneLoadMoreViewData
{
    if (nil != self.loadMoreView
        && self.loadMoreEnabled && (self.listMode & kTCPullRefreshModeLoadMore)) {
        //        [_loadMoreView tcLoadMoreScrollViewDataSourceDidFinishedLoading:self.collectionView];
    }
    
    self.loadingMore = NO;
}

- (void)loadingDismissWithBlock:(void (^)(void))block
{
    if (kTCRefreshPages == self.loadType) {
        if (nil != block) {
            block();
        }
        [self doneLoadingViewData];
    } else if (kTCLoadNextPage == self.loadType) {
        if (nil != block) {
            block();
        }
        [self layoutIfNeeded];
        [self doneLoadMoreViewData];
    }
    
    self.reloading = NO;
    self.loadingMore = NO;
}


- (BOOL)tc_triggerReload:(BOOL)animated
{
    if (nil != self.pullRefreshDelegate && [self.pullRefreshDelegate respondsToSelector:@selector(reloadViewDataSource:)]) {
        if ([self.pullRefreshDelegate reloadViewDataSource:kTCRefreshPages]) {
            self.loadingMore = NO;
            [self reloadViewDataSource:animated];
            return YES;
        }
        return NO;
    } else {
        self.loadingMore = NO;
        [self reloadViewDataSource:animated];
        return YES;
    }
}

- (BOOL)tc_triggerLoadMore
{
    if (nil != self.pullRefreshDelegate && [self.pullRefreshDelegate respondsToSelector:@selector(loadMoreViewDataSource:)]) {
        if ([self.pullRefreshDelegate loadMoreViewDataSource:kTCLoadNextPage]) {
            self.reloading = NO;
            [self loadMoreViewDataSource];
            return YES;
        }
        return NO;
    } else {
        self.reloading = NO;
        [self loadMoreViewDataSource];
        return YES;
    }
}


#pragma mark - TCRefreshTableHeaderDelegate

- (void)tcRefreshHeaderDidTriggerRefresh:(UIView<TCRefreshHeaderInterface> *)view
{
    [self tc_triggerReload:YES];
}

- (BOOL)tcRefreshHeaderDataSourceIsLoading:(UIView<TCRefreshHeaderInterface> *)view
{
    return self.reloading;
}

- (NSDate *)tcRefreshHeaderDataSourceLastUpdated:(UIView<TCRefreshHeaderInterface> *)view
{
    return NSDate.date;
}


#pragma mark - TCLoadMoreViewDelegate Methods

//- (void)tcLoadMoreViewDidTriggerload:(TCLoadMoreView *)view
//{
//    [self loadMoreTableViewDataSource];
//}
//
//- (BOOL)tcLoadMoreViewDataSourceIsLoading:(TCLoadMoreView *)view
//{
//    return _loadingMore;
//}
//
//- (BOOL)tcLoadMoreViewDataSourceCanLoadMore:(TCLoadMoreView *)view
//{
//    return _canLoadMore;
//}


#pragma mark - UIScrollViewDelegate

- (BOOL)canLoadMore
{
    if (nil != self.pullRefreshDelegate && [self.pullRefreshDelegate respondsToSelector:@selector(canLoadMore)]) {
        return [self.pullRefreshDelegate canLoadMore];
    }
    
    return YES;
}


- (void)tc_scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 刷新操作
    if (self.refreshEnabled && nil != self.refreshHeaderView) {
        [self.refreshHeaderView tcRefreshScrollViewDidScroll:scrollView];
    }
    
//    if (nil != self.loadMoreView && self.loadMoreEnabled && !_scrollDecelerating) { // 翻页操作
//        //        [_loadMoreView tcLoadMoreScrollViewDidScroll:scrollView];
//    }
    
    if (scrollView.contentSize.height < scrollView.bounds.size.height) {
        return;
    }

    // 向上滚动
    CGFloat yVelocity = [scrollView.panGestureRecognizer velocityInView:scrollView].y;
    
    if (yVelocity < 0.0f && !self.reloading && ((self.listMode & kTCPullRefreshModeLoadMore2) == kTCPullRefreshModeLoadMore2)
        && self.loadMoreEnabled && !self.loadingMore && self.canLoadMore) {
        if (scrollView.contentOffset.y - self.priorContentOffsetY >= scrollView.bounds.size.height / 2) {
            self.priorContentOffsetY = scrollView.contentOffset.y;
            [self tc_triggerLoadMore];
        }
    }
}

- (void)tc_scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.priorContentOffsetY = scrollView.contentOffset.y;
    
    if (!self.reloading && ((self.listMode & kTCPullRefreshModeLoadMore2) == kTCPullRefreshModeLoadMore2)
        && self.loadMoreEnabled && !self.loadingMore && self.canLoadMore) {
        
        CGFloat offset_y = scrollView.contentSize.height - scrollView.contentOffset.y;
        
        static CGFloat const kDeltaY = 200.0f; // 离 bottom 200 point
        BOOL reachBottom = (scrollView.contentOffset.y > 10.0f) && (offset_y <= scrollView.bounds.size.height + kDeltaY);
        if (reachBottom) {
            [self tc_triggerLoadMore];
        }
    }
}

- (void)tc_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // 刷新操作
    if (!self.reloading && !self.loadingMore && nil != self.refreshHeaderView && self.refreshEnabled) {
        [self.refreshHeaderView tcRefreshScrollViewDidEndDragging:scrollView];
    }
    
//    if (!self.reloading && !self.loadingMore && nil != self.loadMoreView && self.loadMoreEnabled) { // 翻页操作
        //        [_loadMoreView tcLoadMoreScrollViewDidEndDragging:scrollView];
//    }
}


@end

#endif
