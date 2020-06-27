//
//  UIButton+TCHelper.m
//  TCKit
//
//  Created by dake on 15/1/24.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import "UIButton+TCHelper.h"
#import <objc/runtime.h>


@interface UIButton (TCLayoutStyle)

- (void)updateLayoutStyle;

@end

@interface _TCButtonExtra : NSObject
{
@package
    __weak UIButton *_target;
}

@property (nonatomic, assign) UIEdgeInsets alignmentRectInsets;
@property (nonatomic, assign) CGFloat paddingBetweenTitleAndImage;
@property (nonatomic, strong) NSMutableDictionary *innerBackgroundColorDic;
@property (nonatomic, strong) NSMutableDictionary *borderColorDic;
@property (nonatomic, assign) TCButtonLayoutStyle layoutStyle;
@property (nonatomic, assign) BOOL isFrameObserved;
@property (nonatomic, assign) BOOL enableUnderline;

- (void)addFrameObserver:(UIButton *)target;
- (void)removeFrameObserver:(UIButton *)target;

- (void)addStateObserver:(UIButton *)target;
- (void)removeStateObserver:(UIButton *)target;

@end

@implementation _TCButtonExtra
{
    @private
    BOOL _isStateObserved;
}


- (void)addFrameObserver:(UIButton *)target
{
    if (_isFrameObserved) {
        return;
    }
    _isFrameObserved = YES;
    [target addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [target addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeFrameObserver:(UIButton *)target
{
    if (!_isFrameObserved) {
        return;
    }
    [target removeObserver:self forKeyPath:@"bounds"];
    [target removeObserver:self forKeyPath:@"frame"];
    _isFrameObserved = NO;
}

- (void)addStateObserver:(UIButton *)target
{
    if (_isStateObserved) {
        return;
    }
    
    _isStateObserved = YES;
    [target addObserver:self forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew context:NULL];
    [target addObserver:self forKeyPath:@"selected" options:NSKeyValueObservingOptionNew context:NULL];
    [target addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeStateObserver:(UIButton *)target
{
    if (!_isStateObserved) {
        return;
    }
    [target removeObserver:self forKeyPath:@"highlighted"];
    [target removeObserver:self forKeyPath:@"selected"];
    [target removeObserver:self forKeyPath:@"enabled"];
    _isStateObserved = NO;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _target) {
        if ([keyPath isEqualToString:@"highlighted"] || [keyPath isEqualToString:@"selected"] || [keyPath isEqualToString:@"enabled"]) {
            NSNumber *state = @(_target.state);
            _target.backgroundColor = _innerBackgroundColorDic[state];
            _target.layer.borderColor = [(UIColor *)_borderColorDic[state] CGColor];
            
        } else if ([keyPath isEqualToString:@"bounds"] || [keyPath isEqualToString:@"frame"]) {
            CGRect oldFrame = [(NSValue *)change[NSKeyValueChangeOldKey] CGRectValue];
            CGRect newFrame = [(NSValue *)change[NSKeyValueChangeNewKey] CGRectValue];
            
            if (!CGSizeEqualToSize(oldFrame.size, newFrame.size)) {
                [_target updateLayoutStyle];
            }
        }
    }
}


@end



static char const kBtnExtraKey;

@implementation UIButton (TCHelper)

@dynamic layoutStyle;
@dynamic alignmentRectInsets;
@dynamic paddingBetweenTitleAndImage;


- (void)tc_dealloc
{
    _TCButtonExtra *observer = objc_getAssociatedObject(self, &kBtnExtraKey);
    if (nil != observer) {
        [observer removeFrameObserver:self];
        [observer removeStateObserver:self];
        objc_setAssociatedObject(self, &kBtnExtraKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [self tc_dealloc];
}

+ (void)load
{
    // ARC forbids us to use a selector on dealloc, so we must trick it with NSSelectorFromString()
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tc_swizzle:NSSelectorFromString(@"dealloc")];
        [self tc_swizzle:@selector(setImage:forState:)];
        [self tc_swizzle:@selector(setTitle:forState:)];
        [self tc_swizzle:@selector(setAttributedTitle:forState:)];
    });
}

- (_TCButtonExtra *)btnExtra
{
    _TCButtonExtra *observer = objc_getAssociatedObject(self, &kBtnExtraKey);
    
    if (nil == observer) {
        observer = [[_TCButtonExtra alloc] init];
        observer->_target = self;
        objc_setAssociatedObject(self, &kBtnExtraKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return observer;
}

- (void)tc_setImage:(UIImage *)image forState:(UIControlState)state
{
    UIImage *oldImg = [self imageForState:state];
    [self tc_setImage:image forState:state];
    if (oldImg != image && !CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
}

- (void)tc_setTitle:(NSString *)title forState:(UIControlState)state
{
    NSString *oldTitle = [self titleForState:state];
    [self tc_setTitle:title forState:state];
    if (![oldTitle isEqualToString:title] && !CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
}

- (void)tc_setAttributedTitle:(NSAttributedString *)title forState:(UIControlState)state
{
    NSAttributedString *oldTitle = [self attributedTitleForState:state];
    [self tc_setAttributedTitle:title forState:state];
    if (![oldTitle isEqual:title] && !CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
}

#pragma mark -  underline

- (void)setUnderlineAtrributedStringForState:(UIControlState)state
{
    NSMutableAttributedString *titleString = nil;
    
    NSString *title = [self titleForState:state];
    if (nil != title) {
        
        titleString = [[NSMutableAttributedString alloc] initWithString:title];
        [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, titleString.length)];
        UIColor *color = [self titleColorForState:state];
        if (nil == color) {
            color = [self titleColorForState:UIControlStateNormal];
        }
        if (nil != color) {
            [titleString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, titleString.length)];
        }
    } else {
        UIColor *color = [self titleColorForState:state];
        if (nil != color) {
            title = [self titleForState:UIControlStateNormal];
            if (nil != title) {
                titleString = [[NSMutableAttributedString alloc] initWithString:title];
                [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, titleString.length)];
                [titleString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, titleString.length)];
            }
        }
    }
    
    [self setAttributedTitle:titleString forState:state];
}

- (void)setEnableUnderline:(BOOL)enableUnderline
{
    self.btnExtra.enableUnderline = enableUnderline;
    if (enableUnderline) {
        NSString *title = [self titleForState:UIControlStateNormal];
        if (nil != title) {
            NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title];
            [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, titleString.length)];
            UIColor *color = [self titleColorForState:UIControlStateNormal];
            if (nil != color) {
                [titleString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, titleString.length)];
            }
            [self setAttributedTitle:titleString forState:UIControlStateNormal];
        }
        
        [self setUnderlineAtrributedStringForState:UIControlStateHighlighted];
        [self setUnderlineAtrributedStringForState:UIControlStateSelected];
        [self setUnderlineAtrributedStringForState:UIControlStateDisabled];
        [self setUnderlineAtrributedStringForState:UIControlStateHighlighted | UIControlStateSelected];
    } else {
        [self setAttributedTitle:nil forState:UIControlStateNormal];
        [self setAttributedTitle:nil forState:UIControlStateHighlighted];
        [self setAttributedTitle:nil forState:UIControlStateSelected];
        [self setAttributedTitle:nil forState:UIControlStateDisabled];
        [self setAttributedTitle:nil forState:UIControlStateHighlighted | UIControlStateSelected];
    }
}


#pragma mark - alignmentRectInsets

- (UIEdgeInsets)alignmentRectInsets
{
    return self.btnExtra.alignmentRectInsets;
}

- (void)setAlignmentRectInsets:(UIEdgeInsets)alignmentRectInsets
{
    self.btnExtra.alignmentRectInsets = alignmentRectInsets;
}


#pragma mark - layoutStyle

- (TCButtonLayoutStyle)layoutStyle
{
    return self.btnExtra.layoutStyle;
}

- (void)setLayoutStyle:(TCButtonLayoutStyle)layoutStyle
{
    _TCButtonExtra *btnExtra = self.btnExtra;
    if (btnExtra.layoutStyle == layoutStyle) {
        return;
    }
    
    btnExtra.layoutStyle = layoutStyle;
    
    if (!CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
    
    if (layoutStyle != kTCButtonLayoutStyleDefault) {
        [btnExtra addFrameObserver:self];
    } else {
        if (btnExtra.isFrameObserved) {
            [btnExtra removeFrameObserver:self];
            [self resetImageAndTitleEdges];
        }
    }
}

- (CGFloat)paddingBetweenTitleAndImage
{
    return self.btnExtra.paddingBetweenTitleAndImage;
}

- (void)setPaddingBetweenTitleAndImage:(CGFloat)paddingBetweenTitleAndImage
{
    self.btnExtra.paddingBetweenTitleAndImage = paddingBetweenTitleAndImage;
}

- (void (^)(__kindof UIButton *sender, CGSize layoutSize))layoutSizeNeedChangeBlock
{
    return (void (^)(__kindof UIButton *sender, CGSize layoutSize))objc_getAssociatedObject(self, @selector(setLayoutSizeNeedChange:));
}

- (void)setLayoutSizeNeedChange:(void (^)(__kindof UIButton *sender, CGSize layoutSize))block
{
    objc_setAssociatedObject(self, _cmd, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


- (void)updateLayoutStyle
{
    switch (self.layoutStyle) {
        case kTCButtonLayoutStyleImageLeftTitleRight:
            [self imageAndTitleToFitHorizonal];
            break;
            
        case kTCButtonLayoutStyleImageRightTitleLeft:
            [self imageAndTitleToFitHorizonalReverse];
            break;
            
        case kTCButtonLayoutStyleImageTopTitleBottom:
            [self imageAndTitleToFitVertical:YES];
            break;
            
        case kTCButtonLayoutStyleImageBottomTitleTop:
            [self imageAndTitleToFitVertical:NO];
            break;
            
        default:
            break;
    }
    
    if (self.btnExtra.enableUnderline) {
        self.enableUnderline = YES;
    }
}

- (void)noFrameKVOPerform:(dispatch_block_t)block
{
    NSCParameterAssert(block);
    
    if (nil == block) {
        return;
    }
    
    _TCButtonExtra *btnExtra = self.btnExtra;
    BOOL observed = btnExtra.isFrameObserved;
    if (observed) {
        [btnExtra removeFrameObserver:self];
    }
    
    block();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (observed) {
            [btnExtra addFrameObserver:self];
        }
    });
}

- (void)imageAndTitleToFitVertical:(BOOL)up
{
    if (nil != self.titleLabel && nil != self.imageView) {
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        CGRect contentRect = [self contentRectForBounds:self.bounds];
        CGSize imageSize = [self imageRectForContentRect:contentRect].size;
        
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, 0, 0);
        contentRect = [self contentRectForBounds:self.bounds];
        CGSize titleSize = [self titleRectForContentRect:contentRect].size;
        
        CGSize size = contentRect.size;
        CGFloat pad = self.paddingBetweenTitleAndImage * 0.5f;
        CGFloat r = (titleSize.height + imageSize.height) * 0.5f - titleSize.height;// MIN(titleSize.height, imageSize.height);
        CGFloat border = self.layer.borderWidth;
        
        if (up) {
            CGFloat left = (size.width - imageSize.width) * 0.5f;
            self.imageEdgeInsets = UIEdgeInsetsMake(-imageSize.height * 0.5f - pad + border + r,
                                                    left,
                                                    imageSize.height * 0.5f + pad - border - r,
                                                    -left);
            self.titleEdgeInsets = UIEdgeInsetsMake(titleSize.height * 0.5f + pad + border + r,
                                                    (size.width - titleSize.width) * 0.5f - imageSize.width,
                                                    -titleSize.height * 0.5f - pad - border - r,
                                                    0);
        } else {
            self.imageEdgeInsets = UIEdgeInsetsMake(imageSize.height * 0.5f + pad - r,
                                                    (size.width - imageSize.width) * 0.5f,
                                                    -imageSize.height * 0.5f - pad + r,
                                                    -titleSize.width);
            self.titleEdgeInsets = UIEdgeInsetsMake(-titleSize.height * 0.5f - pad - r,
                                                    (size.width - titleSize.width) * 0.5f - imageSize.width,
                                                    titleSize.height * 0.5f + pad + r,
                                                    0);
        }
        
        CGSize dstSize = CGSizeMake(MAX(imageSize.width, titleSize.width) + border * 2, imageSize.height + titleSize.height + self.paddingBetweenTitleAndImage + border * 2);
        if (!CGSizeEqualToSize(size, dstSize)) {
            if (nil != self.layoutSizeNeedChangeBlock) {
                self.layoutSizeNeedChangeBlock(self, dstSize);
            }
        }
        
//        self.imageView.backgroundColor = UIColor.grayColor;
//        self.backgroundColor = UIColor.whiteColor;
//        self.titleLabel.backgroundColor = UIColor.redColor;
        
        //            CGFloat expand = (titleSize.height + imageSize.height - size.height) * 0.5 + pad + border;
        //            CGRect bounds = self.bounds;
        //            bounds.size.height += expand * 2;
        //            self.bounds = bounds;
    }
}

- (void)imageAndTitleToFitHorizonalReverse
{
    if (nil != self.titleLabel && nil != self.imageView) {
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        
        CGRect contentRect = [self contentRectForBounds:self.bounds];
        CGSize imageSize = [self imageRectForContentRect:contentRect].size;
        CGSize titleSize = [self titleRectForContentRect:contentRect].size;
        CGFloat pad = self.paddingBetweenTitleAndImage * 0.5f;
        
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width - pad, 0, imageSize.width + pad);
        self.imageEdgeInsets = UIEdgeInsetsMake(0, titleSize.width + pad, 0, -titleSize.width - pad);
        
        [self noFrameKVOPerform:^{
            CGFloat expand = pad + self.layer.borderWidth;
            CGFloat width = expand * 2 + imageSize.width + titleSize.width;
            CGSize size = [self contentRectForBounds:self.bounds].size;
            if (width != size.width) {
                if (nil != self.layoutSizeNeedChangeBlock) {
                    size.width = width;
                    self.layoutSizeNeedChangeBlock(self, size);
                } else {
                    self.contentEdgeInsets = UIEdgeInsetsMake(0, expand, 0, expand);
                }
            }
        }];
    }
}

- (void)imageAndTitleToFitHorizonal
{
    if (nil != self.titleLabel && nil != self.imageView) {
        
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        
        CGFloat pad = self.paddingBetweenTitleAndImage * 0.5f;
        CGFloat border = self.layer.borderWidth;
        self.titleEdgeInsets = UIEdgeInsetsMake(0, pad, 0, -pad);
        self.imageEdgeInsets = UIEdgeInsetsMake(0, -pad, 0, pad);
      
        [self noFrameKVOPerform:^{
            CGFloat expand = pad + border;
            CGRect contentRect = [self contentRectForBounds:self.bounds];
            CGSize imageSize = [self imageRectForContentRect:contentRect].size;
            CGSize titleSize = [self titleRectForContentRect:contentRect].size;
            CGFloat width = expand * 2 + imageSize.width + titleSize.width;
            CGSize size = contentRect.size;
            
            if (width != size.width) {
                if (nil != self.layoutSizeNeedChangeBlock) {
                    size.width = width;
                    self.layoutSizeNeedChangeBlock(self, size);
                } else {
                    self.contentEdgeInsets = UIEdgeInsetsMake(0, expand, 0, expand);
                }
            }
        }];
    }
}

- (void)resetImageAndTitleEdges
{
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleEdgeInsets = UIEdgeInsetsZero;
    self.imageEdgeInsets = UIEdgeInsetsZero;
    self.contentEdgeInsets = UIEdgeInsetsZero;
}


#pragma mark - backgroundColor

- (NSMutableDictionary *)innerBackgroundColorDic
{
    _TCButtonExtra *btnExtra = self.btnExtra;
    if (nil == btnExtra.innerBackgroundColorDic) {
        btnExtra.innerBackgroundColorDic = [NSMutableDictionary dictionary];
        if (nil == btnExtra.borderColorDic) {
            [btnExtra addStateObserver:self];
        }
    }
    
    return btnExtra.innerBackgroundColorDic;
}

- (NSMutableDictionary *)borderColorDic
{
    _TCButtonExtra *btnExtra = self.btnExtra;
    if (nil == btnExtra.borderColorDic) {
        btnExtra.borderColorDic = [NSMutableDictionary dictionary];
        if (nil == btnExtra.innerBackgroundColorDic) {
            [btnExtra addStateObserver:self];
        }
    }
    
    return btnExtra.borderColorDic;
}


- (UIColor *)backgroundColorForState:(UIControlState)state
{
    return self.innerBackgroundColorDic[@(state)];
}

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    if (nil == color) {
        [self.innerBackgroundColorDic removeObjectForKey:@(state)];
    } else {
        self.innerBackgroundColorDic[@(state)] = color;
        
        if ((UIControlStateNormal & state) == UIControlStateNormal) {
            if (nil == [self backgroundColorForState:state | UIControlStateHighlighted]) {
                self.innerBackgroundColorDic[@(state | UIControlStateHighlighted)] = color;
            }
            
            if (nil == [self backgroundColorForState:state | UIControlStateSelected]) {
                self.innerBackgroundColorDic[@(state | UIControlStateSelected)] = color;
            }
        }
    }
    
    if (state == self.state) {
        self.backgroundColor = color;
    }
}

- (UIColor *)borderColorForState:(UIControlState)state;
{
    return self.borderColorDic[@(state)];
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state
{
    if (nil == color) {
        [self.borderColorDic removeObjectForKey:@(state)];
    } else {
        self.borderColorDic[@(state)] = color;
        
        if ((UIControlStateNormal & state) == UIControlStateNormal) {
            if (nil == [self borderColorForState:state | UIControlStateHighlighted]) {
                self.borderColorDic[@(state | UIControlStateHighlighted)] = color;
            }
            
            if (nil == [self borderColorForState:state | UIControlStateSelected]) {
                self.borderColorDic[@(state | UIControlStateSelected)] = color;
            }
        }
    }
    
    if (state == self.state) {
        self.layer.borderColor = color.CGColor;
    }
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

+ (UIImage *)imageFromBarButtonSystemItem:(UIBarButtonSystemItem)item
{
    switch (item) {
        case UIBarButtonSystemItemDone:
        case UIBarButtonSystemItemCancel:
        case UIBarButtonSystemItemEdit:
        case UIBarButtonSystemItemSave:
        case UIBarButtonSystemItemFlexibleSpace:
        case UIBarButtonSystemItemFixedSpace:
        case UIBarButtonSystemItemPageCurl:
            return nil;
            
        default:
            break;
    }
    
    if (@available(iOS 13, *)) {
        NSString *key = nil;
        switch (item) {
            case UIBarButtonSystemItemAdd:
                key = @"plus";
                break;
           
            case UIBarButtonSystemItemCompose:
                key = @"square.and.pencil";
                break;
                
            case UIBarButtonSystemItemReply:
                key = @"arrowshape.turn.up.left";
                break;
                
            case UIBarButtonSystemItemAction:
                key = @"square.and.arrow.up";
                break;
                
            case UIBarButtonSystemItemOrganize:
                key = @"folder";
                break;
                
            case UIBarButtonSystemItemBookmarks:
                key = @"book";
                break;
                
            case UIBarButtonSystemItemSearch:
                key = @"magnifyingglass";
                break;
                
            case UIBarButtonSystemItemRefresh:
                key = @"arrow.clockwise";
                break;
                
            case UIBarButtonSystemItemStop:
                key = @"xmark";
                break;
                
            case UIBarButtonSystemItemCamera:
                key = @"camera.fill";
                break;
                
            case UIBarButtonSystemItemTrash:
                key = @"trash";
                break;
                
            case UIBarButtonSystemItemPlay:
                key = @"play.fill";
                break;
                
            case UIBarButtonSystemItemPause:
                key = @"pause.fill";
                break;
                
            case UIBarButtonSystemItemRewind:
                key = @"backward.fill";
                break;
                
            case UIBarButtonSystemItemFastForward:
                key = @"forward.fill";
                break;
                
            case UIBarButtonSystemItemUndo:
                key = @"arrow.uturn.left";
                break;
                
            case UIBarButtonSystemItemRedo:
                key = @"arrow.uturn.right";
                break;
                
                // toolbar only
            case UIBarButtonSystemItemPageCurl:
                break;
                
            case UIBarButtonSystemItemClose:
//                key = @"xmark.circle";
                break;
                
            default:
                break;
        }
        
        if (nil != key) {
            return [UIImage systemImageNamed:key];
        }
    }
    
    
    static const CGFloat defaultNBBtnHW = 44.0;
    
    UIImage *img = nil;
    @try {
        BOOL isToolBar = UIBarButtonSystemItemPageCurl == item;
        UIView *bar = isToolBar ? [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, defaultNBBtnHW, defaultNBBtnHW)] : [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, defaultNBBtnHW, defaultNBBtnHW)];
        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:nil action:NULL];
        if (isToolBar) {
            ((UIToolbar *)bar).items = @[barItem];
        } else {
            UINavigationItem *naviItem = [[UINavigationItem alloc] init];
            naviItem.rightBarButtonItems = @[barItem];
            ((UINavigationBar *)bar).items = @[naviItem];
        }
        [bar snapshotViewAfterScreenUpdates:YES];
        [bar layoutIfNeeded];
        UIView *barButtonItemView = [barItem respondsToSelector:@selector(view)] ? [barItem valueForKey:NSStringFromSelector(@selector(view))] : nil;
        if ([barButtonItemView isKindOfClass:UIButton.class]) {
            img = [(UIButton *)barButtonItemView imageForState:UIControlStateNormal];
        } else {
            for (UIView *subview in barButtonItemView.subviews) {
                if ([subview isKindOfClass:UIButton.class]) {
                    img = [(UIButton *)subview imageForState:UIControlStateNormal];
                    if (nil != img) {
                        break;
                    }
                }
            }
            if (nil == img) {
                for (UIView *subview in barButtonItemView.subviews) {
                    if ([subview isKindOfClass:UIImageView.class]) {
                        img = ((UIImageView *)subview).image;
                        if (nil != img) {
                            break;
                        }
                    }
                }
            }
        }
    } @catch (NSException *exp) {
        
    } @finally {
        return img;
    }
}


@end

#endif
