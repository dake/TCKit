//
//  TCAlertAction.m
//  TCKit
//
//  Created by dake on 15/3/12.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#ifndef TARGET_IS_EXTENSION

#import "TCAlertAction.h"


@interface TCAlertAction ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, assign, readwrite) TCAlertActionStyle style;

@end

@implementation TCAlertAction

+ (instancetype)actionWithTitle:(NSString *)title style:(TCAlertActionStyle)style handler:(void (^)(TCAlertAction *action))handler
{
    TCAlertAction *action = [[self alloc] init];
    action.title = title;
    action.style = style;
    action.handler = handler;
    
    return action;
}

+ (instancetype)defaultActionWithTitle:(NSString *)title handler:(void (^)(TCAlertAction *action))handler
{
    return [self actionWithTitle:title style:kTCAlertActionStyleDefault handler:handler];
}

+ (instancetype)cancelActionWithTitle:(NSString *)title handler:(void (^)(TCAlertAction *action))handler
{
    return [self actionWithTitle:title style:kTCAlertActionStyleCancel handler:handler];
}

+ (instancetype)destructiveActionWithTitle:(NSString *)title handler:(void (^)(TCAlertAction *action))handler
{
    return [self actionWithTitle:title style:kTCAlertActionStyleDestructive handler:handler];
}

- (UIAlertAction *)toUIAlertAction
{
    void (^handler)(UIAlertAction *action) = nil;
    if (nil != self.handler) {
        // !!!: no weak self in purpose
        handler = ^(UIAlertAction *action) {
            self.handler(self);
            self.handler = nil;
        };
    }
    
    return [UIAlertAction actionWithTitle:self.title style:(UIAlertActionStyle)self.style handler:handler];
}


@end



#endif
