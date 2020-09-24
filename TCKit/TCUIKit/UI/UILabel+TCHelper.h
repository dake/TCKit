//
//  UILabel+TCHelper.h
//  TCKit
//
//  Created by dake on 15/3/10.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TCTextVerticalAlignment) {
    kTCTextVerticalAlignmentDefault = 0,
    kTCTextVerticalAlignmentTop,
    kTCTextVerticalAlignmentMiddle,
    kTCTextVerticalAlignmentBottom,
};

NS_ASSUME_NONNULL_BEGIN

@protocol TCLabelHelperDelegate <NSObject>

@optional
- (nullable NSString *)copyStringForLabel:(UILabel *)sender;
- (nullable NSArray<UIMenuElement *> *)menuItemsForLabel:(UILabel *)sender API_AVAILABLE(ios(13.0));

+ (nullable NSString *)copyStringForLabel:(UILabel *)sender;
+ (nullable NSArray<UIMenuElement *> *)menuItemsForLabel:(UILabel *)sender API_AVAILABLE(ios(13.0));

@end

@interface UILabel (TCHelper) <UIContextMenuInteractionDelegate>

@property (nonatomic, assign) TCTextVerticalAlignment textVerticalAlignment;
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;

@property (nullable, nonatomic, weak) id<TCLabelHelperDelegate> menuDelegate;
@property (nonatomic, assign) BOOL copyEnable;


- (nullable NSMutableAttributedString *)attributedStringForText:(NSString * _Nullable)text;

+ (nullable id<TCLabelHelperDelegate>)menuDelegate;
+ (void)setMenuDelegate:(id<TCLabelHelperDelegate> _Nullable)menuDelegate;

- (void)showMenu:(CGRect)rect;


@end

NS_ASSUME_NONNULL_END

#endif
