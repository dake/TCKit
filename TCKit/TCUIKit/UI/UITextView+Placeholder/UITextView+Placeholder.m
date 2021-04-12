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

#import <objc/runtime.h>
#import "UITextView+Placeholder.h"
#import "NSObject+TCUtilities.h"
//#import "UILabel+TCHelper.h"

@implementation UITextView (Placeholder)

#pragma mark - Swizzle Dealloc

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:NSSelectorFromString(@"dealloc")];
    });
}

- (void)tc_dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    if (nil != objc_getAssociatedObject(self, @selector(placeholderLabel))) {
        @try {
            for (NSString *key in self.class.observingKeys) {
                [self removeObserver:self forKeyPath:key];
            }
        }
        @catch (NSException *exception) {
            // Do nothing
        }
    }
    [self tc_dealloc];
}

- (nullable NSMutableAttributedString *)lineBreakedForText:(NSString * _Nullable)text
{
    if (text.length < 1) {
        return nil;
    }
  
    NSMutableDictionary *attributes = NSMutableDictionary.dictionary;
    NSMutableParagraphStyle *paragraphStyle = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
    paragraphStyle.lineBreakMode = self.textContainer.lineBreakMode;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    
    if (nil != self.font) {
        attributes[NSFontAttributeName] = self.font;
    }
    if (nil != self.textColor) {
        attributes[NSForegroundColorAttributeName] = self.textColor;
    }
    if (@available(iOS 13, *)) {
        if (nil != self.accessibilityTextualContext) {
            attributes[UIAccessibilityTextAttributeContext] = self.accessibilityTextualContext;
        }
    }

   return [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
}

- (void)setLineBreakText:(NSString * _Nullable)text
{
    if (text.length < 1 || NSLineBreakByWordWrapping == self.textContainer.lineBreakMode) {
        self.text = text;
        return;
    }

    self.attributedText = [self lineBreakedForText:text];
}


#pragma mark - Class Methods
#pragma mark `defaultPlaceholderColor`

+ (UIColor *)defaultPlaceholderColor {
    static UIColor *color = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 13, *)) {
            color = UIColor.placeholderTextColor;
        } else {
            UITextField *textField = [[UITextField alloc] init];
            textField.placeholder = @" ";
            color = [textField.attributedPlaceholder attributesAtIndex:0 effectiveRange:NULL][NSForegroundColorAttributeName];
        }
    });
    return color;
}


#pragma mark - `observingKeys`

+ (NSArray *)observingKeys {
    return @[@"attributedText",
             @"bounds",
             @"font",
             @"frame",
             @"text",
             @"textAlignment",
             @"textContainerInset"];
}


#pragma mark - Properties
#pragma mark `placeholderLabel`

- (UILabel *)placeholderLabel {
    UILabel *(^block) (void) = ^{
        UILabel *label = objc_getAssociatedObject(self, @selector(placeholderLabel));
        if (nil == label) {
            NSAttributedString *originalText = self.attributedText;
            self.text = @" "; // lazily set font of `UITextView`.
            self.attributedText = originalText;
            
            label = [[UILabel alloc] init];
            label.textColor = self.class.defaultPlaceholderColor;
            label.lineBreakMode = self.textContainer.lineBreakMode;
            label.numberOfLines = 0;
            label.font = self.font;
//            label.userInteractionEnabled = NO;
            objc_setAssociatedObject(self, @selector(placeholderLabel), label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(updatePlaceholderLabel)
                                                       name:UITextViewTextDidChangeNotification
                                                     object:self];
            
            for (NSString *key in self.class.observingKeys) {
                [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
            }
//            label.copyEnable = YES;
        }
        return label;
    };
    
    if (!NSThread.isMainThread) {
        __block UILabel *label = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            label = block();
        });
        
        return label;
    }
    
    return block();
}


#pragma mark `placeholder`

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

- (void)setPlaceholder:(NSString *)placeholder {
    if (NSThread.isMainThread) {
        self.placeholderLabel.text = placeholder;
        [self updatePlaceholderLabel];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.placeholderLabel.text = placeholder;
            [self updatePlaceholderLabel];
        });
    }
}


#pragma mark `placeholderColor`

- (UIColor *)placeholderColor {
    return self.placeholderLabel.textColor;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    self.placeholderLabel.textColor = placeholderColor;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self) {
        if ([self.class.observingKeys containsObject:keyPath]) {
            [self updatePlaceholderLabel];
        }
    }
}


#pragma mark - Update

- (void)updatePlaceholderLabel {
    if (self.text.length > 0) {
        [self.placeholderLabel removeFromSuperview];
        return;
    }

    [self insertSubview:self.placeholderLabel atIndex:0];

    if (nil == self.placeholderLabel.font) {
        self.placeholderLabel.font = self.font;
    }
    self.placeholderLabel.textAlignment = self.textAlignment;

    // `NSTextContainer` is available since iOS 7
    CGFloat lineFragmentPadding = 0;
    UIEdgeInsets textContainerInset = UIEdgeInsetsZero;

#pragma deploymate push "ignored-api-availability"
    // iOS 7+
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        lineFragmentPadding = self.textContainer.lineFragmentPadding;
        textContainerInset = self.textContainerInset;
    }
#pragma deploymate pop

    // iOS 6
    else {
        lineFragmentPadding = 5;
        textContainerInset = UIEdgeInsetsMake(8, 0, 8, 0);
    }

    CGFloat x = lineFragmentPadding + textContainerInset.left;
    CGFloat y = textContainerInset.top;
    CGFloat width = CGRectGetWidth(self.bounds) - x - lineFragmentPadding - textContainerInset.right;
    CGFloat height = [self.placeholderLabel sizeThatFits:CGSizeMake(width, 0)].height;
    self.placeholderLabel.frame = CGRectMake(x, y, width, height);
}


#ifndef __TCKit__
#pragma mark - helper

+ (BOOL)tc_swizzle:(SEL)aSelector
{
    Method m1 = class_getInstanceMethod(self, aSelector);
    if (NULL == m1) {
        return NO;
    }
    
    SEL bSelector = NSSelectorFromString([NSString stringWithFormat:@"tc_%@", NSStringFromSelector(aSelector)]);
    Method m2 = class_getInstanceMethod(self, bSelector);
    
    if (class_addMethod(self, aSelector, method_getImplementation(m2), method_getTypeEncoding(m2))) {
        class_replaceMethod(self, bSelector, method_getImplementation(m1), method_getTypeEncoding(m1));
    } else {
        method_exchangeImplementations(m1, m2);
    }
    
    return YES;
}
#endif

@end



@interface TCTextViewTarget : NSObject

- (void)textViewEditChanged:(NSNotification *)note;

@end


@implementation TCTextViewTarget


- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)textViewEditChanged:(NSNotification *)note
{
    UITextView *textView = note.object;
    NSString *toBeString = textView.text;
    UITextRange *selectedRange = textView.markedTextRange;
    // check highlight selection position
    UITextPosition *position = nil;
    if (nil != selectedRange) {
        position = [textView positionFromPosition:selectedRange.start offset:0];
    }
    // no highlight selection
    if (nil == position) {
        NSInteger maxLength = textView.tc_maxTextLength;
        
        if (maxLength >= 0 && toBeString.length > maxLength) {
            NSRange range = [toBeString rangeOfComposedCharacterSequenceAtIndex:(NSUInteger)maxLength];
            textView.text = [toBeString substringToIndex:range.location == NSNotFound ? (NSUInteger)maxLength : range.location];
        }
    } else {
    }
    
    id<TCTextViewHelperDelegate> tc_delegate = textView.tc_delegate;
    if (nil != tc_delegate && [tc_delegate respondsToSelector:@selector(tc_textViewValueChanged:)]) {
        [tc_delegate tc_textViewValueChanged:textView];
    }
}

@end


@implementation UITextView (TCHelper)

- (id<TCTextViewHelperDelegate>)tc_delegate
{
    return [self bk_associatedValueForKey:_cmd];
}

- (void)setTc_delegate:(id<TCTextViewHelperDelegate>)tc_delegate
{
    [self bk_weaklyAssociateValue:tc_delegate withKey:@selector(tc_delegate)];

    
    TCTextViewTarget *target = objc_getAssociatedObject(self, @selector(setTc_maxTextLength:));
    if (nil == target) {
        target = [[TCTextViewTarget alloc] init];
        [NSNotificationCenter.defaultCenter addObserver:target selector:@selector(textViewEditChanged:) name:UITextViewTextDidChangeNotification object:self];
        objc_setAssociatedObject(self, @selector(setTc_maxTextLength:), target, OBJC_ASSOCIATION_RETAIN);
    }
}


- (NSInteger)tc_maxTextLength
{
    NSNumber *value = objc_getAssociatedObject(self, _cmd);
    return nil == value ? -1 : value.integerValue;
}

- (void)setTc_maxTextLength:(NSInteger)tc_maxTextLength
{
    objc_setAssociatedObject(self, @selector(tc_maxTextLength), @(tc_maxTextLength), OBJC_ASSOCIATION_RETAIN);
    
    TCTextViewTarget *target = objc_getAssociatedObject(self, _cmd);
    if (nil == target) {
        target = [[TCTextViewTarget alloc] init];
        [NSNotificationCenter.defaultCenter addObserver:target selector:@selector(textViewEditChanged:) name:UITextViewTextDidChangeNotification object:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN);
    }
}

@end

#endif
