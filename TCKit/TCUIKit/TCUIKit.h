//
//  TCUIKit.h
//  TCKit
//
//  Created by dake on 16/6/2.
//  Copyright © 2016年 dake. All rights reserved.
//

#ifndef TCUIKit_h
#define TCUIKit_h

#ifndef __IPHONE_13_0
enum {
    UIActivityIndicatorViewStyleMedium = 100,
    UIActivityIndicatorViewStyleLarge = 101,
};
#endif

#import "UIView+TCHelper.h"
#import "UILabel+TCHelper.h"
#import "UIButton+TCHelper.h"
#import "UIViewController+TCHelper.h"
#import "UITextField+TCHelper.h"
#import "TCAlertController.h"
#import "UIWindow+TCHelper.h"
#import "UIScrollView+TCHelper.h"
#import "UIImageView+TCHelper.h"
#import "UITextView+Placeholder.h"

#import "TCWKWebView.h"

#ifndef TARGET_IS_EXTENSION
#import "UIApplication+TCHelper.h"
#endif

#endif /* TCUIKit_h */
