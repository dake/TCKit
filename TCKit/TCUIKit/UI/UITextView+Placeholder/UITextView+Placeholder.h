/*
 The MIT License (MIT)

 Copyright (c) 2014 Suyeol Jeon (http://xoul.kr)

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (Placeholder)

@property (nullable, nonatomic, retain, readonly) UILabel *placeholderLabel;

@property (nullable, nonatomic, strong) NSString *placeholder;
@property (nullable, nonatomic, strong) UIColor *placeholderColor;

+ (UIColor *)defaultPlaceholderColor;

- (void)setLineBreakText:(NSString * _Nullable)text;
- (nullable NSMutableAttributedString *)lineBreakedForText:(NSString * _Nullable)text;

@end



@protocol TCTextViewHelperDelegate <NSObject>

@optional
- (void)tc_textViewValueChanged:(UITextView *)sender;

@end


@interface UITextView (TCHelper)

@property (nonatomic, assign) NSInteger tc_maxTextLength;
@property (nullable, nonatomic, weak) id<TCTextViewHelperDelegate> tc_delegate;

@end

NS_ASSUME_NONNULL_END

#endif
