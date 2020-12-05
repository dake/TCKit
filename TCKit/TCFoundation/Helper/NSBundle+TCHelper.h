//
//  NSBundle+TCHelper.h
//  TCKit
//
//  Created by dake on 16/12/2.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <UIKit/UIImage.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSBundle (TCHelper)

//+ (nullable NSBundle *)hostMainBundle;
+ (nullable NSString *)hostMainBundleIdentifier;
- (BOOL)isHostMainBundle;

- (nullable NSString *)bundleVersion;
- (nullable NSString *)bundleShortVersion;
- (nullable NSString *)bundleName;
- (nullable NSString *)displayName;


@end


//@interface UIImage (AppExtension)
//
//+ (nullable UIImage *)hostMainBundleImageNamed:(NSString *)name NS_AVAILABLE_IOS(8_0);
//
//@end

NS_ASSUME_NONNULL_END
