//
//  UIView+TCHelper.m
//  TCKit
//
//  Created by dake on 15/5/12.
//  Copyright (c) 2015年 TCKit. All rights reserved.
//


#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import "UIView+TCHelper.h"
#import <objc/runtime.h>
#import "NSObject+TCUtilities.h"


NSString *const kTCCellIdentifier = @"cell";
NSString *const kTCHeaderIdentifier = @"header";
NSString *const kTCFooterIdentifier = @"footer";

static char const kAlignmentRectInsetsKey;

@implementation UIView (TCHelper)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(alignmentRectInsets)];
    });
}

+ (CGFloat)pointWithPixel:(NSUInteger)pixel
{
    return pixel / UIScreen.mainScreen.scale;
}

- (UIEdgeInsets)tc_alignmentRectInsets
{
    NSValue *value = objc_getAssociatedObject(self, &kAlignmentRectInsetsKey);
    return nil != value ? value.UIEdgeInsetsValue : self.tc_alignmentRectInsets;
}

- (void)setAlignmentRectInsets:(UIEdgeInsets)alignmentRectInsets
{
    objc_setAssociatedObject(self, &kAlignmentRectInsetsKey, [NSValue valueWithUIEdgeInsets:alignmentRectInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//- (void)viewRoundedRect:(UIView *)itemView byConers:(UIRectCorner)corners
//{
//    UIBezierPath *cornerPath = [UIBezierPath bezierPathWithRoundedRect:itemView.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(7.0, 7.0)];
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = itemView.bounds;
//    maskLayer.path = cornerPath.CGPath;
//    itemView.layer.mask = maskLayer;
//}

- (UIViewController *)nearestController
{
    UIResponder *responder = self.nextResponder;

    if ([responder isKindOfClass:UIViewController.class]) {
        return (UIViewController *)responder;
    }
    
    return ((UIView *)responder).nearestController;
}

@end

@implementation UISearchBar (TCHelper)

- (nullable __kindof UITextField *)tc_textField
{
    if (@available(iOS 13, *)) {
        return self.searchTextField;
    }
    
    UITextField *searchTf = nil;
    for (__kindof UIView *subView in self.subviews) {
        if ([subView isKindOfClass:UITextField.class]) {
            searchTf = subView;
            break;
        }
    }
    
    if (nil == searchTf) {
        for (UIView *subView in self.subviews) {
            for (__kindof UIView *subView2 in subView.subviews) {
                if ([subView2 isKindOfClass:UITextField.class]) {
                    searchTf = subView2;
                    break;
                }
                
                if (nil != searchTf) {
                    break;
                }
            }
        }
    }
    return searchTf;
}

@end

@implementation UITableView (TCFixLayoutMargin)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(initWithFrame:style:)];
    });
}

- (instancetype)tc_initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    UITableView *tableView = [self tc_initWithFrame:frame style:style];
    tableView.cellLayoutMarginsFollowReadableWidth = NO;
    return tableView;
}

@end



@implementation TCUIAction

- (BOOL)hasNextLevelMenu
{
    return self.children.count > 0 && 0 == (TCMenuOptionsDisplayInline & self.options);
}

- (UIMenuOptions)UIMenuOptions API_AVAILABLE(ios(13.0))
{
    TCMenuOptions options = self.options;
    if (options == 0) {
        return 0;
    }
    
    UIMenuOptions opt = 0;
    if (0 != (TCMenuOptionsDisplayInline & options)) {
        opt |= UIMenuOptionsDisplayInline;
    }
    if (0 != (TCMenuOptionsDestructive & options)) {
        opt |= UIMenuOptionsDestructive;
    }
    return opt;
}

- (UIMenuElementAttributes)UIMenuElementAttributes API_AVAILABLE(ios(13.0))
{
    TCMenuElementAttributes attrib = self.attributes;
    if (attrib == 0) {
        return 0;
    }
    
    UIMenuElementAttributes attr = 0;
    if (0 != (TCMenuElementAttributesDisabled & attrib)) {
        attr |= UIMenuElementAttributesDisabled;
    }
    if (0 != (TCMenuElementAttributesDestructive & attrib)) {
        attr |= UIMenuElementAttributesDestructive;
    }
    if (0 != (TCMenuElementAttributesHidden & attrib)) {
        attr |= UIMenuElementAttributesHidden;
    }
    return attr;
}

- (UIMenuElementState)UIMenuElementState API_AVAILABLE(ios(13.0))
{
    switch (self.state) {
        case TCMenuElementStateOff:
            return UIMenuElementStateOff;
        case TCMenuElementStateOn:
            return UIMenuElementStateOn;
        case TCMenuElementStateMixed:
            return UIMenuElementStateMixed;
            
        default:
            return UIMenuElementStateOff;
    }
}

// TODO: cancel 等老方式才有的 item 怎么转换
// TODO: UIKeyCommand UIDeferredMenuElement
- (__kindof UIMenuElement *)UIMenuElement API_AVAILABLE(ios(13.0))
{
    if (self.children.count < 1) {
        UIImage *icon = nil != self.imageBlock ? self.imageBlock() : nil;
        UIAction *action = [UIAction actionWithTitle:self.title ?: @"" image:icon identifier:self.identifier handler:^(__kindof UIAction * _Nonnull action) {
            // force retain
            if (nil != self.handler) {
                self.handler(self);
            }
        }];
        action.discoverabilityTitle = self.discoverabilityTitle;
        action.attributes = self.UIMenuElementAttributes;
        action.state = self.UIMenuElementState;
        return action;
    }
    
    NSCParameterAssert(nil == self.handler);
    NSMutableArray<UIMenuElement *> *items = NSMutableArray.array;
    for (TCUIAction *action in self.children) {
        [items addObject:action.UIMenuElement];
    }
    
    UIImage *icon = nil != self.imageBlock ? self.imageBlock() : nil;
    UIMenu *menu = [UIMenu menuWithTitle:self.title ?: @"" image:icon identifier:self.identifier options:self.UIMenuOptions children:items];
    return menu;
}

- (NSArray<UIAlertAction *> *)UIAlertActions
{
    if (self.hasNextLevelMenu) {
        TCMenuElementAttributes attr = nil != self.attributesWithoutIcon ? self.attributesWithoutIcon.unsignedIntegerValue : self.attributes;
        UIAlertActionStyle style = 0 != (TCMenuOptionsDestructive & self.options) ? UIAlertActionStyleDestructive : (0 != (TCMenuElementAttributesCancel & attr) ? UIAlertActionStyleCancel : UIAlertActionStyleDefault);
        UIAlertAction *action = [UIAlertAction actionWithTitle:self.titleWithoutIcon ?: self.title style:style handler:^(UIAlertAction * _Nonnull action) {
            // force retain
            if (nil != self.handler) {
                self.handler(self);
            }
        }];
        action.enabled = 0 == (TCMenuElementAttributesDisabled & attr);
        return @[action];
    }
    
    NSMutableArray<UIAlertAction *> *items = NSMutableArray.array;
    if (self.title.length > 0 && (nil != self.handler || self.children.count < 1)) {
        TCMenuElementAttributes attr = nil != self.attributesWithoutIcon ? self.attributesWithoutIcon.unsignedIntegerValue : self.attributes;
        UIAlertActionStyle style = 0 != (TCMenuElementAttributesDestructive & attr) ? UIAlertActionStyleDestructive : (0 != (TCMenuElementAttributesCancel & attr) ? UIAlertActionStyleCancel : UIAlertActionStyleDefault);
        UIAlertAction *action = [UIAlertAction actionWithTitle:self.titleWithoutIcon ?: self.title style:style handler:^(UIAlertAction * _Nonnull action) {
            // force retain
            if (nil != self.handler) {
                self.handler(self);
            }
        }];
        action.enabled = 0 == (TCMenuElementAttributesDisabled & attr);
        [items addObject:action];
    }
    for (TCUIAction *action in self.children) {
        [items addObjectsFromArray:action.UIAlertActions];
    }
    
    return items;
}

@end


#endif
