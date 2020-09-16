//
//  UILabel+TCHelper.m
//  TCKit
//
//  Created by dake on 15/3/10.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import "UILabel+TCHelper.h"
#import <objc/runtime.h>
#import "NSObject+TCUtilities.h"


@implementation UILabel (TCHelper)

@dynamic contentEdgeInsets;

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:@selector(textRectForBounds:limitedToNumberOfLines:)];
        [self tc_swizzle:@selector(drawTextInRect:)];
    });
}

- (UIEdgeInsets)contentEdgeInsets
{
    NSValue *value = objc_getAssociatedObject(self, _cmd);
    return nil != value ? [value UIEdgeInsetsValue] : UIEdgeInsetsZero;
}

- (void)setContentEdgeInsets:(UIEdgeInsets)contentEdgeInsets
{
    objc_setAssociatedObject(self, @selector(contentEdgeInsets), [NSValue valueWithUIEdgeInsets:contentEdgeInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (TCTextVerticalAlignment)textVerticalAlignment
{
    NSNumber *alignment = objc_getAssociatedObject(self, _cmd);
    
    if (nil != alignment) {
        return (TCTextVerticalAlignment)alignment.integerValue;
    }
    
    objc_setAssociatedObject(self, _cmd, @(kTCTextVerticalAlignmentDefault), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return kTCTextVerticalAlignmentDefault;
}

- (void)setTextVerticalAlignment:(TCTextVerticalAlignment)textVerticalAlignment
{
    objc_setAssociatedObject(self, @selector(textVerticalAlignment), @(textVerticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (CGRect)tc_textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    CGRect textRect = [self tc_textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    
    switch (self.textVerticalAlignment) {
        case kTCTextVerticalAlignmentTop:
            textRect.origin.y = bounds.origin.y;
            break;
            
        case kTCTextVerticalAlignmentBottom:
            textRect.origin.y = bounds.origin.y + bounds.size.height - textRect.size.height;
            break;
            
        case kTCTextVerticalAlignmentDefault:
        case kTCTextVerticalAlignmentMiddle:
            textRect.origin.y = bounds.origin.y + (bounds.size.height - textRect.size.height) / 2.0f;
            break;
            
        default:
            break;
    }
    
    UIEdgeInsets insets = self.contentEdgeInsets;
    return UIEdgeInsetsInsetRect(textRect, insets);
}

- (void)tc_drawTextInRect:(CGRect)rect
{
    CGRect fixRect = rect;
    UIEdgeInsets edge = self.contentEdgeInsets;
    if (self.textVerticalAlignment != kTCTextVerticalAlignmentDefault || !UIEdgeInsetsEqualToEdgeInsets(edge, UIEdgeInsetsZero)) {
        fixRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
    }
    [self tc_drawTextInRect:fixRect];
}


#pragma mark - copy

- (void)setTc_delegate:(id<TCLabelHelperDelegate>)tc_delegate
{
    [self bk_weaklyAssociateValue:tc_delegate withKey:@selector(tc_delegate)];
}

- (id<TCLabelHelperDelegate>)tc_delegate
{
    return [self bk_associatedValueForKey:_cmd];
}

- (void)setLongPressGestureRecognizer:(id)recognizer
{
    objc_setAssociatedObject(self, @selector(longPressGestureRecognizer), recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)longPressGestureRecognizer
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCopyEnable:(BOOL)copyEnable
{
    self.userInteractionEnabled = copyEnable;
    if (copyEnable) {
        if (nil == self.longPressGestureRecognizer) {
            if (@available(iOS 13, *)) {
                // FIXME: strong delegate?
                UIContextMenuInteraction *menuInter = [[UIContextMenuInteraction alloc] initWithDelegate:self];
                [self addInteraction:menuInter];
                self.longPressGestureRecognizer = menuInter;
            } else {
                UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
                [self addGestureRecognizer:longPressGes];
                self.longPressGestureRecognizer = longPressGes;
            }
        }
        
    } else {
        if (nil != self.longPressGestureRecognizer) {
            if (@available(iOS 13, *)) {
                [self removeInteraction:self.longPressGestureRecognizer];
            } else {
                [self removeGestureRecognizer:self.longPressGestureRecognizer];
            }
            self.longPressGestureRecognizer = nil;
        }
    }
    objc_setAssociatedObject(self, @selector(copyEnable), @(copyEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)copyEnable
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)canBecomeFirstResponder
{
    return self.copyEnable;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return action == @selector(copy:);
//    || action == @selector(select:)
//    || action == @selector(selectAll:);
}

//- (void)select:(nullable id)sender API_AVAILABLE(ios(3.0))
//{
//
//}
//
//- (void)selectAll:(nullable id)sender API_AVAILABLE(ios(3.0))
//{
//
//}

- (void)copy:(id)sender
{
    UIPasteboard *pboard = UIPasteboard.generalPasteboard;
    id<TCLabelHelperDelegate> delegate = self.tc_delegate;
    
    NSString *str = nil;
    if (nil != delegate && [delegate respondsToSelector:@selector(copyStringForLabel:)]) {
        str = [delegate copyStringForLabel:self];
    } else {
        str = self.text;
    }
    
    if (str.length > 0) {
        pboard.string = str;
    }
}

- (void)handleLongPress:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:self];
        CGRect rect = CGRectMake(point.x, 0, 0, 0);
        [self showMenu:rect];
    }
}

- (void)showMenu:(CGRect)rect
{
    if (self.copyEnable && [self becomeFirstResponder]) {
        UIMenuController *menu = UIMenuController.sharedMenuController;
#ifdef __IPHONE_13_0
        if (@available(iOS 13, *)) {
            [menu showMenuFromView:self rect:rect];
        } else
#endif
        {
            [menu setTargetRect:rect inView:self];
            [menu setMenuVisible:YES animated:YES];
        }
    }
}


// MARK: UIContextMenuInteractionDelegate

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0))
{
    __weak typeof(self) wSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        NSMutableArray<UIMenuElement *> *arry = NSMutableArray.array;
        [arry addObject:({
            NSBundle* uikitBundle = [NSBundle bundleForClass:wSelf.class];
            NSString *str = [uikitBundle localizedStringForKey:@"Copy" value:@"Copy" table:nil];
            UIAction *act = [UIAction actionWithTitle:str image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [wSelf copy:nil];
            }];
            act;
        })];
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:0 children:arry];
        return menu;
    }];
}

@end

#endif
