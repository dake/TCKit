//
//  NSBundle+TCHelper.h
//  TCKit
//
//  Created by dake on 16/12/2.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (TCHelper)

+ (NSBundle *)hostMainBundle;
+ (BOOL)isHostMainBundle;

@end


@interface UIImage (AppExtension)

+ (nullable UIImage *)hostMainBundleImageNamed:(NSString *)name NS_AVAILABLE_IOS(8_0);

@end

NS_ASSUME_NONNULL_END
