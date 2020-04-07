//
//  UIApplication+TCHelper.h
//  TCKit
//
//  Created by dake on 16/9/28.
//  Copyright © 2016年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) && !defined(TARGET_IS_UI_EXTENSION)

#import <UIKit/UIKit.h>
#import <Availability.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kTCUIApplicationDelegateChangedNotification;

@interface UIApplication (TCHelper)

#ifndef __IPHONE_10_0
- (BOOL)openURL:(NSURL*)url __attribute__((deprecated("Please use openURL:options:completionHandler: instead")));
- (void)openURL:(NSURL*)url options:(NSDictionary<NSString *, id> *)options completionHandler:(void (^ __nullable)(BOOL success))completion;
#endif

@end

@interface UIViewController (UIApplication)

+ (CGFloat)statusBarHeight;
- (CGFloat)statusBarHeight;

@end

@interface NSString (UIApplication)

- (void)phoneCall:(void(^)(BOOL success))complete;

@end

NS_ASSUME_NONNULL_END

#endif
