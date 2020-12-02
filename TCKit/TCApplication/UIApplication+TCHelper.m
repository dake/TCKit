//
//  UIApplication+TCHelper.m
//  TCKit
//
//  Created by dake on 16/9/28.
//  Copyright © 2016年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) && !defined(TARGET_IS_UI_EXTENSION)

#import "UIApplication+TCHelper.h"
#import <objc/runtime.h>
#import "NSObject+TCUtilities.h"


NSString *const kTCUIApplicationDelegateChangedNotification = @"TCUIApplicationDelegateChangedNotification";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation UIApplication (TCHelper)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0
        if (@available(iOS 10, *)) {
            
        } else {
            SEL sel = @selector(openURL:options:completionHandler:);
            Method m1 = class_getInstanceMethod(self, sel);
            
            if (NULL != sel && NULL == m1) {
                IMP handler = imp_implementationWithBlock(^(UIApplication *app, NSURL *url, NSDictionary<NSString *, id> *options, void (^ __nullable completion)(BOOL success)) {
                    //        #pragma clang diagnostic push
                    //        #pragma clang diagnostic ignored "-Wdeprecated"
                    BOOL ret = [app openURL:url];
                    //        #pragma clang diagnostic pop
                    if (nil != completion) {
                        if (NSThread.isMainThread) {
                            completion(ret);
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completion(ret);
                            });
                        }
                    }
                });
                
                if (!class_addMethod(self, sel, handler, "v40@0:8@16@24@?32")) {
                    NSCAssert(false, @"add %@ failed", NSStringFromSelector(sel));
                }
            }
        }
#endif
        [self tc_swizzle:@selector(setDelegate:)];
    });
}

#pragma clang diagnostic pop

- (void)tc_setDelegate:(id<UIApplicationDelegate>)delegate
{
    [self tc_setDelegate:delegate];
    
    if (nil != delegate) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [NSNotificationCenter.defaultCenter postNotificationName:kTCUIApplicationDelegateChangedNotification object:delegate];
        });
    }
}

@end


@implementation UIViewController (UIApplication)

+ (CGFloat)statusBarHeight
{
    // Landscape mode on iPad, UIApplication.sharedApplication.statusBarFrame.size.height is bigger, so we get the smaller
    CGSize size = UIApplication.sharedApplication.statusBarFrame.size;
    return MIN(size.width, size.height);
}

+ (UIInterfaceOrientation)statusBarOrientation
{
    return UIApplication.sharedApplication.statusBarOrientation;
}

@end


@implementation NSString (UIApplication)

- (void)phoneCall:(void (^)(BOOL success))complete
{
    if (self.length > 1) {
        NSURL *phoneNumber = [NSURL URLWithString:[NSString stringWithFormat:@"tel%s://%@", "prompt", self]];
        if ([UIApplication.sharedApplication canOpenURL:phoneNumber]) {
            [UIApplication.sharedApplication openURL:phoneNumber options:@{} completionHandler:complete];
        }
    }
}

@end

#endif
