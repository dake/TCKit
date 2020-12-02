//
//  UIView+TCHelper.h
//  TCKit
//
//  Created by dake on 15/5/12.
//  Copyright (c) 2015年 TCKit. All rights reserved.
//

#if !defined(TARGET_IS_EXTENSION) || defined(TARGET_IS_UI_EXTENSION)

#import <UIKit/UIKit.h>



NS_ASSUME_NONNULL_BEGIN

extern NSString *const kTCCellIdentifier;
extern NSString *const kTCHeaderIdentifier;
extern NSString *const kTCFooterIdentifier;

@interface UIView (TCHelper)

+ (CGFloat)pointWithPixel:(NSUInteger)pixel;

- (void)setAlignmentRectInsets:(UIEdgeInsets)alignmentRectInsets;

- (nullable UIViewController *)nearestController;

@end

@interface UISearchBar (TCHelper)

- (nullable __kindof UITextField *)tc_textField;

@end



typedef NS_ENUM(NSInteger, TCMenuElementState) {
    TCMenuElementStateOff,
    TCMenuElementStateOn,
    TCMenuElementStateMixed
};

typedef NS_OPTIONS(NSUInteger, TCMenuElementAttributes) {
    TCMenuElementAttributesDefault      = 0,
    TCMenuElementAttributesDisabled     = 1 << 0,
    TCMenuElementAttributesDestructive  = 1 << 1,
    TCMenuElementAttributesHidden       = 1 << 2,
    
    
    
    TCMenuElementAttributesCancel       = 1 << 20,
};

typedef NS_OPTIONS(NSUInteger, TCMenuOptions) {
    /// Show children inline in parent, instead of hierarchically
    TCMenuOptionsDisplayInline  = 1 << 0,

    /// Indicates whether the menu should be rendered with a destructive appearance in its parent
    TCMenuOptionsDestructive    = 1 << 1,
};

 
@class TCUIAction;
typedef void (^TCUIActionHandler)(__kindof TCUIAction *action);

@interface TCUIAction : NSObject

@property (nonatomic, assign) BOOL menuOnly;

/// Short display title.
@property (nullable, nonatomic, copy) NSString *title;

@property (nullable, nonatomic, copy) NSString *titleWithoutIcon;

/// Image that can appear next to this action.
@property (nullable, nonatomic, copy) UIImage *_Nullable (^imageBlock)(void);

/// Elaborated title, if any.
@property (nullable, nonatomic, copy) NSString *discoverabilityTitle;

/// This action's identifier.
@property (nullable, nonatomic, copy) NSString *identifier;

/// This action's style.
@property (nonatomic, assign) TCMenuElementAttributes attributes;

@property (nullable, nonatomic, strong) NSNumber/*TCMenuElementAttributes*/ *attributesWithoutIcon;

@property (nonatomic, assign) TCMenuElementState state;

@property (nonatomic, assign) TCMenuOptions options;

@property (nullable, nonatomic, copy) TCUIActionHandler handler;

@property (nullable, nonatomic, strong) NSArray<TCUIAction *> *children;

- (BOOL)hasNextLevelMenu;

- (__kindof UIMenuElement *)UIMenuElement API_AVAILABLE(ios(13.0));
- (NSArray<UIAlertAction *> *)UIAlertActions;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
- (NSArray<UITableViewRowAction *> *)UITableViewRowActions;
#endif

//- (UIAction *)UIAction:(UIActionHandler)handler API_AVAILABLE(ios(13.0));
//- (UIContextualAction *)UIContextualAction:(UIContextualActionHandler)handler API_AVAILABLE(ios(11.0));
//- (UITableViewRowAction *)UITableViewRowAction:(void (^)(UITableViewRowAction *action, NSIndexPath *indexPath))handler;
//- (UIAlertAction *)UIAlertAction:(void (^ __nullable)(UIAlertAction *action))handler;
//- (UIPreviewAction *)UIPreviewAction:(void (^)(UIPreviewAction *action, UIViewController *previewViewController))handler;
// UIMenuItem

// UIBarItem block 封装

@end


NS_ASSUME_NONNULL_END


#endif
