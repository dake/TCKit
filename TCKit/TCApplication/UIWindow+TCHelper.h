//
//  UIWindow+TCHelper.h
//  TCKit
//
//  Created by dake on 15-7-29.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#ifndef TARGET_IS_EXTENSION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (TCHelper)

+ (nullable __kindof UIViewController *)hostWindowTopController;

- (nullable __kindof UIViewController *)topMostViewController;

#ifdef __IPHONE_7_0
- (nullable __kindof UIViewController *)viewControllerForStatusBarStyle;
- (nullable __kindof UIViewController *)viewControllerForStatusBarHidden;
#endif

@end

NS_ASSUME_NONNULL_END

#endif

