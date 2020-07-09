//
//  TCAlertController.m
//  TCKit
//
//  Created by dake on 15/3/12.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#ifndef TARGET_IS_EXTENSION

#import "TCAlertController.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
#import "UIAlertView+TCBlocks.h"
#import "UIActionSheet+TCBlocks.h"
#endif

#import "UIWindow+TCHelper.h"


@protocol UIAlertViewAction <NSObject>

@required
- (void)addAction:(id)action;

@end


@implementation TCAlertController
{
@private
    id<UIAlertViewAction> _alertView;
    __weak UIViewController *_parentCtrler;
}



- (instancetype)initAlertViewWithTitle:(NSString *)title
                               message:(NSString *)message
                         presentCtrler:(UIViewController *)viewCtrler
                          cancelAction:(TCAlertAction *)cancelAction
                          otherActions:(NSArray *)otherActions
{
    self = [super init];
    if (self) {
        _preferredStyle = kTCAlertControllerStyleAlert;
        
        if (Nil == UIAlertController.class) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
            _alertView = (id<UIAlertViewAction>)[[UIAlertView alloc] initWithTitle:title message:message cancelAction:cancelAction otherActions:otherActions];
#endif
        } else {
            UIAlertController *alertCtrler = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            
            if (nil != cancelAction) {
                [alertCtrler addAction:cancelAction.toUIAlertAction];
            }
            
            for (TCAlertAction *eachItem in otherActions) {
                [alertCtrler addAction:eachItem.toUIAlertAction];
            }
            
            _alertView = (id<UIAlertViewAction>)alertCtrler;
            _parentCtrler = viewCtrler;
        }
    }
    
    return self;
}

- (instancetype)initAlertViewWithTitle:(NSString *)title
                               message:(NSString *)message
                         presentCtrler:(UIViewController *)viewCtrler
                          cancelAction:(TCAlertAction *)cancelAction
                           otherAction:(TCAlertAction *)otherAction, ...
{
    NSMutableArray *arry = nil;
    if (nil != otherAction) {
        arry = NSMutableArray.array;
        TCAlertAction *eachItem = otherAction;
        va_list argumentList;
        va_start(argumentList, otherAction);
        do {
            [arry addObject:eachItem];
            eachItem = va_arg(argumentList, TCAlertAction *);
        } while (nil != eachItem);
        va_end(argumentList);
    }
    
    return [self initAlertViewWithTitle:title message:message presentCtrler:viewCtrler cancelAction:cancelAction otherActions:arry];
}


- (instancetype)initActionSheetWithTitle:(NSString *)title
                           presentCtrler:(UIViewController *)viewCtrler
                            cancelAction:(TCAlertAction *)cancelAction
                       destructiveAction:(TCAlertAction *)destructiveAction
                            otherActions:(NSArray *)otherActions
{
    self = [super init];
    if (self) {
        _preferredStyle = kTCAlertControllerStyleActionSheet;
        _parentCtrler = viewCtrler;
        
        if (Nil == UIAlertController.class) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
            _alertView = (id<UIAlertViewAction>)[[UIActionSheet alloc] initWithTitle:title cancelAction:cancelAction destructiveAction:destructiveAction otherActions:otherActions];
#endif
        } else {
            UIAlertController *alertCtrler = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            if (nil != cancelAction) {
                [alertCtrler addAction:cancelAction.toUIAlertAction];
            }
            
            if (nil != destructiveAction) {
                [alertCtrler addAction:destructiveAction.toUIAlertAction];
            }
            
            for (TCAlertAction *eachItem in otherActions) {
                [alertCtrler addAction:eachItem.toUIAlertAction];
            }
            
            _alertView = (id<UIAlertViewAction>)alertCtrler;
        }
    }
    
    return self;
}


- (instancetype)initActionSheetWithTitle:(NSString *)title
                           presentCtrler:(UIViewController *)viewCtrler
                            cancelAction:(TCAlertAction *)cancelAction
                       destructiveAction:(TCAlertAction *)destructiveAction
                             otherAction:(TCAlertAction *)otherAction, ...
{
    NSMutableArray *arry = nil;
    if (nil != otherAction) {
        arry = NSMutableArray.array;
        TCAlertAction *eachItem = otherAction;
        va_list argumentList;
        va_start(argumentList, otherAction);
        do {
            [arry addObject:eachItem];
            eachItem = va_arg(argumentList, TCAlertAction *);
        } while (nil != eachItem);
        va_end(argumentList);
    }
    return [self initActionSheetWithTitle:title presentCtrler:viewCtrler cancelAction:cancelAction destructiveAction:destructiveAction otherActions:arry];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
- (UIPopoverPresentationController *)popoverPresentationController
{
    return ((UIAlertController *)_alertView).popoverPresentationController;
}
#endif

- (void)addAction:(TCAlertAction *)action
{
    if ([_alertView isKindOfClass:UIAlertController.class]) {
        [_alertView addAction:action.toUIAlertAction];
    } else {
        [_alertView addAction:action];
    }
}

- (void)show
{
    if (nil == _parentCtrler) {
        _parentCtrler = UIWindow.keyWindowTopController;
    }
    
    if ([_alertView isKindOfClass:UIViewController.class]) {
        [_parentCtrler presentViewController:(UIViewController *)_alertView animated:YES completion:nil];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    } else if ([_alertView isKindOfClass:UIAlertView.class]) {
        [((UIAlertView *)_alertView) show];
    } else if ([_alertView isKindOfClass:UIActionSheet.class]) {
        [((UIActionSheet *)_alertView) showInView:_parentCtrler.view];
#endif
    }
    
    _alertView = nil;
}


@end

#endif
