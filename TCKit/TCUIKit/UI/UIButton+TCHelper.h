//
//  UIButton+TCHelper.h
//  TCKit
//
//  Created by dake on 15/1/24.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TCButtonLayoutStyle) {
    kTCButtonLayoutStyleDefault = 0,
    kTCButtonLayoutStyleImageLeftTitleRight,
    kTCButtonLayoutStyleImageRightTitleLeft,
    kTCButtonLayoutStyleImageTopTitleBottom,
    kTCButtonLayoutStyleImageBottomTitleTop,
};

@interface UIButton (TCHelper)

@property (nonatomic, assign) UIEdgeInsets alignmentRectInsets;
@property (nonatomic, assign) CGFloat paddingBetweenTitleAndImage;

@property (nonatomic, assign) TCButtonLayoutStyle layoutStyle;

+ (nullable UIImage *)imageFromBarButtonSystemItem:(UIBarButtonSystemItem)item;

/**
 @brief set underline
 
 !!!: shout set behind setTitle:ForState: setTitleColor:ForState:
 
 NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:@"The Underlined text"];
 
 // making text property to underline text-
 [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, [titleString length])];
 
 // using text on button
 [button setAttributedTitle: titleString forState:UIControlStateNormal];
 
 */
- (void)setEnableUnderline:(BOOL)enableUnderline; // default: NO


- (void)resetImageAndTitleEdges;
- (void)updateLayoutStyle;

- (void)setLayoutSizeNeedChange:(void (^)(__kindof UIButton *sender, CGSize layoutSize))block;


- (nullable UIColor *)backgroundColorForState:(UIControlState)state;
- (void)setBackgroundColor:(UIColor * __nullable)color forState:(UIControlState)state;

- (nullable UIColor *)borderColorForState:(UIControlState)state;
- (void)setBorderColor:(UIColor * __nullable)color forState:(UIControlState)state;


@end

NS_ASSUME_NONNULL_END

#endif
