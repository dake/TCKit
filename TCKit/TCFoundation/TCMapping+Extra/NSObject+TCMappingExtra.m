//
//  NSObject+TCMappingExtra.m
//  TCKit
//
//  Created by dake on 16/8/22.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSObject+TCMappingExtra.h"
#import "UIColor+TCUtilities.h"
//#import "AnimatedGIFImageSerialization.h"
#import "NSData+TCCypher.h"
#import "UIImage+Resize.h"


@implementation NSObject (TCMappingExtra)


#pragma mark - UIColor <--> NSString

+ (UIColor *)tc_transformColorFromString:(NSString *)string
{
    UIColor *ret = nil;
    NSString *str = string.lowercaseString;
    if ([str hasPrefix:@"#"]) {
        str = [str substringFromIndex:1];
    } else if ([str hasPrefix:@"0x"]) {
        str = [str substringFromIndex:2];
    }
    
    NSUInteger len = str.length;
    if (len == 6) {
        ret = [UIColor colorWithRGBHexString:string];
        
    } else if (len == 8) {
        ret = [UIColor colorWithARGBHexString:string];
    }
    
    return ret;
}

+ (UIColor *)tc_transformColorFromHex:(uint32_t)hex
{
    if (hex < 0x01000000u) { // RGB or clear
        return [UIColor colorWithRGBHex:hex];
    } else { // ARGB
        return [UIColor colorWithARGBHex:hex];
    }
}

+ (NSString *)tc_transformHexStringFromColor:(UIColor *)color
{
    NSString *str = color.argbHexStringValue;
    if (nil == str) {
        return nil;
    }
    return [@"#" stringByAppendingString:str];
}


#pragma mark - UIImage <--> NSData

+ (NSData *)tc_transformDataFromImage:(UIImage *)img
{
//    if (img.images.count > 0) {
//        return [AnimatedGIFImageSerialization animatedGIFDataWithImage:img error:NULL];
//    }
    
    CGImageAlphaInfo const alphaInfo = CGImageGetBitmapInfo(img.CGImage) & kCGBitmapAlphaInfoMask;
    BOOL noAlpha = kCGImageAlphaNone == alphaInfo ||
    kCGImageAlphaNoneSkipLast == alphaInfo ||
    kCGImageAlphaNoneSkipFirst == alphaInfo;
    
    if (noAlpha) {
        return UIImageJPEGRepresentation(img.fixOrientationToUp, 0.6f);
    }
    return UIImagePNGRepresentation(img.fixOrientationToUp);
}

+ (UIImage *)tc_transformImageFromData:(NSData *)data
{
    return [UIImage imageWithData:data];
}

+ (UIImage *)tc_transformImageFromBase64String:(NSString *)str
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [self tc_transformImageFromData:data];
}


#pragma mark - NSData <-> NSString

+ (nullable NSData *)tc_transformDataFromString:(NSString *)hex
{
    return [NSData dataWithHexString:hex];
}

+ (nullable NSString *)tc_transformHexStringFromData:(NSData *)data
{
    return data.hexStringRepresentation;
}

@end
