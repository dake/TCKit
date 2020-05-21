//
//  UIScrollView+TCHelper.m
//  TCKit
//
//  Created by dake on 16/4/19.
//  Copyright © 2016年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import "UIScrollView+TCHelper.h"
#import <objc/runtime.h>
#import "NSObject+TCUtilities.h"


@implementation UIScrollView (TCHelper)

@dynamic tc_touchesShouldCancelInContentViewBlock;


+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(touchesShouldCancelInContentView:)];
    });
}


- (BOOL (^)(UIView *, BOOL (^)(UIView *)))tc_touchesShouldCancelInContentViewBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setTc_touchesShouldCancelInContentViewBlock:(BOOL (^)(UIView * _Nonnull, BOOL (^ _Nonnull)(UIView * _Nonnull)))tc_touchesShouldCancelInContentViewBlock
{
    objc_setAssociatedObject(self, @selector(tc_touchesShouldCancelInContentViewBlock), tc_touchesShouldCancelInContentViewBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)tc_touchesShouldCancelInContentView:(UIView *)view
{
    if (nil != self.tc_touchesShouldCancelInContentViewBlock) {
        return self.tc_touchesShouldCancelInContentViewBlock(view, ^BOOL (UIView *view){
            return [self tc_touchesShouldCancelInContentView:view];
        });
    }
    
    return [self tc_touchesShouldCancelInContentView:view];
}

- (void)stopScrolling
{
    if (self.isDragging || self.isDecelerating || self.tracking) {
        [self setContentOffset:self.contentOffset animated:NO];
    }
}

#pragma mark -

- (void)delayContentTouches
{
    self.delaysContentTouches = NO;
    for (UIView *view in self.subviews) {
        // looking for a UITableViewWrapperView
        if ([NSStringFromClass(view.class) isEqualToString:[NSStringFromClass(UITableView.class) stringByAppendingString:@"WrapperView"]]) {
            // this test is necessary for safety and because a "UITableViewWrapperView" is NOT a UIScrollView in iOS7
            if ([view isKindOfClass:UIScrollView.class]) {
                // turn OFF delaysContentTouches in the hidden subview
                UIScrollView *scroll = (UIScrollView *)view;
                scroll.delaysContentTouches = NO;
            }
            break;
        }
    }
    
    self.tc_touchesShouldCancelInContentViewBlock = ^BOOL (UIView * view, BOOL (^originalBlock)(UIView *view)){
        if ([view isKindOfClass:UIButton.class]) {
            return YES;
        }
        return originalBlock(view);
    };
}

@end

#endif
