//
//  UIWindow+TCHelper.m
//  TCKit
//
//  Created by dake on 15-7-29.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#ifndef TARGET_IS_EXTENSION

#import "UIWindow+TCHelper.h"

@implementation UIWindow (TCHelper)

+ (UIViewController *)keyWindowTopController
{
    return UIApplication.sharedApplication.delegate.window.topMostViewController;
}

// code from: http://stackoverflow.com/questions/11637709/get-the-current-displaying-uiviewcontroller-on-the-screen-in-appdelegate-m
- (UIViewController *)topMostViewController
{
    if (nil != self.rootViewController) {
        return [self topViewController:self.rootViewController];
    }
    
    // for window only add a subview from controller
    for (UIView *subView in self.subviews) {
        UIResponder *responder = subView.nextResponder;
        
        // added this block of code for iOS 8 which puts a UITransitionView in between the UIWindow and the UILayoutContainerView
        if (responder == self) {
            // this is a UITransitionView
            if (subView.subviews.count > 0) {
                // find the UILayoutContainerView
                NSString *key = [NSStringFromClass(UILayoutGuide.class) substringToIndex:8];
                UIView *subSubView = subView;
                do {
                    // this should be the UILayoutContainerView
                    subSubView = subSubView.subviews.firstObject;
                } while ([NSStringFromClass(subSubView.class) rangeOfString:key].location == NSNotFound && subSubView.subviews.count > 0 && ![subSubView.nextResponder isKindOfClass:UIViewController.class]);
                
                responder = subSubView.nextResponder;
            }
        }
        
        if ([responder isKindOfClass:UIViewController.class]) {
            return [self topViewController:(UIViewController *)responder];
        }
    }
    
    NSCAssert(false, @"topMostViewController nil");
    return nil;
}

- (UIViewController *)topViewController:(UIViewController *)controller
{
    BOOL isPresenting = NO;
    do {
        UIViewController *presented = controller.presentedViewController;
        isPresenting = presented != nil && !presented.beingDismissed && !presented.isMovingFromParentViewController;
        if (isPresenting) {
            controller = presented;
        }
        
    } while (isPresenting);
    
    if ([controller isKindOfClass:UITabBarController.class]) {
        UIViewController *ctrler = ((UITabBarController *)controller).selectedViewController;
        if (nil != ctrler) {
            controller = [self topViewController:ctrler];
        }
        
    } else if ([controller isKindOfClass:UINavigationController.class]) {
        UINavigationController *navi = (typeof(navi))controller;
        UIViewController *ctrler = navi.visibleViewController;
        if (ctrler.isBeingDismissed || ctrler.isMovingFromParentViewController) {
            ctrler = navi.topViewController;
        }
        if (nil != ctrler) {
            controller = [self topViewController:ctrler];
        }
        
    } else if ([controller isKindOfClass:UIPageViewController.class]) {
        UIPageViewController *page = (typeof(page))controller;
        UIViewController *ctrler = page.viewControllers.firstObject;
        if (nil != ctrler) {
            controller = [self topViewController:ctrler];
        }
    }
    
    NSCParameterAssert(controller);
    return controller;
}



#ifdef __IPHONE_7_0

- (UIViewController *)viewControllerForStatusBarStyle
{
    UIViewController *currentViewController = self.topMostViewController;
    while (nil != currentViewController.childViewControllerForStatusBarStyle) {
        currentViewController = currentViewController.childViewControllerForStatusBarStyle;
    }
    return currentViewController;
}

- (UIViewController *)viewControllerForStatusBarHidden
{
    UIViewController *currentViewController = self.topMostViewController;
    while (nil != currentViewController.childViewControllerForStatusBarHidden) {
        currentViewController = currentViewController.childViewControllerForStatusBarHidden;
    }
    return currentViewController;
}

#endif

@end

#endif



