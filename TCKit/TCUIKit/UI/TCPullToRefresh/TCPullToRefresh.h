//
//  TCPullToRefresh.h
//  TCKit
//
//  Created by dake on 15/4/26.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

// 数据刷新方式
typedef NS_ENUM(NSInteger, TCLoadDataType) {
    kTCRefreshPages = 0,
    kTCLoadNextPage = 1,
};

/**
 *	@brief	列表页刷新、翻页模式
 */
typedef NS_ENUM(NSInteger, TCPullRefreshMode) {
    kTCPullRefreshModeNone      = 0, /**< 无刷新、翻页，默认模式 */
    kTCPullRefreshModeRefresh   = 1 << 0, /**< 刷新模式 */
    kTCPullRefreshModeLoadMore  = 1 << 1, /**< 有动画翻页模式 */
    kTCPullRefreshModeLoadMore2 = 1 << 2, /**< 无动画翻页模式 */
    kTCPullRefreshModeAll       = (kTCPullRefreshModeRefresh | kTCPullRefreshModeLoadMore) /**< 全选 */
};


typedef NS_ENUM(NSInteger, TCPullRefreshState) {
    kTCPullRefreshPulling = 0,
    kTCPullRefreshNormal,
    kTCPullRefreshLoading,
};


@protocol TCRefreshHeaderViewDelegate;

@protocol TCRefreshHeaderInterface <NSObject>

@required
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, weak) id<TCRefreshHeaderViewDelegate> delegate;

- (void)showRefreshView:(UIScrollView *)scrollView;
- (void)tcRefreshScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)tcRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView;
- (void)tcRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView;

- (void)refreshLastUpdatedDate;

@end

@protocol TCRefreshHeaderViewDelegate <NSObject>

@required
- (void)tcRefreshHeaderDidTriggerRefresh:(UIView<TCRefreshHeaderInterface> *)view;
- (BOOL)tcRefreshHeaderDataSourceIsLoading:(UIView<TCRefreshHeaderInterface> *)view;
@optional
- (NSDate *)tcRefreshHeaderDataSourceLastUpdated:(UIView<TCRefreshHeaderInterface> *)view;

@end

@protocol TCPullToRefresh <NSObject>

@required
- (void)registerHeaderClass:(Class<TCRefreshHeaderInterface>)headerClass;

- (void)reloadViewDataSource:(BOOL)animated;
- (void)doneLoadingViewData;

- (void)loadMoreViewDataSource;
- (void)doneLoadMoreViewData;

- (void)loadingDismissWithBlock:(void (^)(void))block;

@end


@protocol TCPullToRefreshDelegate <NSObject>

@optional
- (BOOL)canLoadMore;
- (BOOL)reloadViewDataSource:(TCLoadDataType)loadType;
- (BOOL)loadMoreViewDataSource:(TCLoadDataType)loadType;

@end
