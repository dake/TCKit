//
//  TCAlertAction.h
//  TCKit
//
//  Created by dake on 15/3/12.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#ifndef TARGET_IS_EXTENSION

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TCAlertActionStyle) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    kTCAlertActionStyleDefault = UIAlertActionStyleDefault,
    kTCAlertActionStyleCancel = UIAlertActionStyleCancel,
    kTCAlertActionStyleDestructive = UIAlertActionStyleDestructive,
#else
    kTCAlertActionStyleDefault = 0,
    kTCAlertActionStyleCancel,
    kTCAlertActionStyleDestructive,
#endif
};

NS_ASSUME_NONNULL_BEGIN

@interface TCAlertAction : NSObject //<NSCopying>

+ (instancetype)actionWithTitle:(NSString *__nullable)title style:(TCAlertActionStyle)style handler:(void (^__nullable)(TCAlertAction *action))handler;

+ (instancetype)defaultActionWithTitle:(NSString *)title handler:(void (^__nullable)(TCAlertAction *action))handler;
+ (instancetype)cancelActionWithTitle:(NSString *)title handler:(void (^__nullable)(TCAlertAction *action))handler;
+ (instancetype)destructiveActionWithTitle:(NSString *)title handler:(void (^__nullable)(TCAlertAction *action))handler;

@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) TCAlertActionStyle style;
@property (nullable, nonatomic, copy) void (^handler)(TCAlertAction *action);

- (UIAlertAction *)toUIAlertAction;

@end


NS_ASSUME_NONNULL_END

#endif
