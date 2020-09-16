//
//  UILabel+TCHelper.h
//  TCKit
//
//  Created by dake on 15/3/10.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TCTextVerticalAlignment) {
    kTCTextVerticalAlignmentDefault = 0,
    kTCTextVerticalAlignmentTop,
    kTCTextVerticalAlignmentMiddle,
    kTCTextVerticalAlignmentBottom,
};

@protocol TCLabelHelperDelegate <NSObject>

@optional
- (NSString *)copyStringForLabel:(UILabel *)sender;

@end

@interface UILabel (TCHelper) <UIContextMenuInteractionDelegate>

@property (nonatomic, assign) TCTextVerticalAlignment textVerticalAlignment;
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;
@property (nullable, nonatomic, weak) id<TCLabelHelperDelegate> tc_delegate;
@property (nonatomic, assign) BOOL copyEnable;

- (void)showMenu:(CGRect)rect;


@end

NS_ASSUME_NONNULL_END

#endif
