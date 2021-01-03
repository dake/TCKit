//
//  UIImage+TCHelper.h
//  TCKit
//
//  Created by dake on 15/5/13.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern BOOL tcCGImageHasAlpha(CGImageRef imgRef);

@interface UIImage (TCHelper)

// main bundle
+ (nullable instancetype)imageWithContentsOfName:(NSString *)name;
+ (nullable instancetype)imageWithContentsOfName:(NSString *)name inBundle:(NSBundle *__nullable)bundle;

+ (nullable instancetype)launchImage;

- (instancetype)fitToScreenScale;

- (BOOL)hasAlpha;


@end

NS_ASSUME_NONNULL_END
