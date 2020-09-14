//
//  NSBundle+TCHelper.m
//  TCKit
//
//  Created by dake on 16/12/2.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSBundle+TCHelper.h"

@implementation NSBundle (TCHelper)

+ (instancetype)hostMainBundle
{
    static NSBundle *s_bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_bundle = NSBundle.mainBundle;
        if ([s_bundle.bundleURL.pathExtension isEqualToString:@"appex"]) {
            NSURL *url = s_bundle.bundleURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent;
            NSBundle *bundle = [NSBundle bundleWithURL:url];
            if (nil != bundle) {
                s_bundle = bundle;
            }
        }
    });
    return s_bundle;
}

+ (BOOL)isHostMainBundle
{
    return [NSBundle.mainBundle isEqual:self.hostMainBundle];
}


- (nullable NSString *)bundleVersion
{
    return [self objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
}

- (nullable NSString *)bundleShortVersion
{
    return [self objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (nullable NSString *)bundleName
{
    return [self objectForInfoDictionaryKey:(id)kCFBundleNameKey];
}

//- (nullable NSString *)bundleIdentifier
//{
//    return [self objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
//}

- (nullable NSString *)displayName
{
    NSString *name = [self objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    return name.length > 0 ? name : self.bundleName;
}

@end

@implementation UIImage (AppExtension)

+ (UIImage *)hostMainBundleImageNamed:(NSString *)name
{
    return [UIImage imageNamed:name inBundle:NSBundle.hostMainBundle compatibleWithTraitCollection:nil];
}

@end
