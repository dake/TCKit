//
//  UIImage+TCHelper.m
//  TCKit
//
//  Created by dake on 15/5/13.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "UIImage+TCHelper.h"

@implementation UIImage (TCHelper)

+ (instancetype)imageWithContentsOfName:(NSString *)name
{
    return [self imageWithContentsOfName:name inBundle:nil];
}

+ (instancetype)imageWithContentsOfName:(NSString *)name inBundle:(NSBundle *)bundle
{
    return [self imageWithContentsOfFile:[(bundle ?: NSBundle.mainBundle) pathForResource:name ofType:nil]];
}

+ (instancetype)launchImage
{
    NSString *launchImage = nil;
    NSArray *imagesDic = [NSBundle.mainBundle.infoDictionary valueForKey:@"UILaunchImages"];
    for (NSDictionary *dic in imagesDic) {
        CGSize imageSize = CGSizeFromString(dic[@"UILaunchImageSize"]);
        
        if (CGSizeEqualToSize(imageSize, UIScreen.mainScreen.bounds.size)) {
            launchImage = dic[@"UILaunchImageName"];
            break;
        }
    }
    
    return nil != launchImage ? [UIImage imageNamed:launchImage] : nil;
}

- (instancetype)fitToScreenScale
{
    CGFloat scale = UIScreen.mainScreen.scale;
    if (scale == self.scale) {
        return self;
    }
    
    return [self.class imageWithCGImage:self.CGImage scale:scale orientation:self.imageOrientation];
}

- (BOOL)hasAlpha
{
    switch (CGImageGetAlphaInfo(self.CGImage)) {
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaLast:
        case kCGImageAlphaFirst:
            return YES;
            
        default:
            return NO;
    }
}

@end
