//
//  NSBundle+TCHelper.m
//  TCKit
//
//  Created by dake on 16/12/2.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSBundle+TCHelper.h"

@implementation NSBundle (TCHelper)

//+ (nullable NSBundle *)hostMainBundle
//{
//    static NSBundle *s_bundle = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        NSBundle *bundle = NSBundle.mainBundle;
//        if ([bundle.bundleURL.pathExtension isEqualToString:@"appex"]) {
//            NSURL *url = bundle.bundleURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent;
//            NSBundle *bundle2 = [NSBundle bundleWithURL:url];
////            NSCParameterAssert(bundle2);
//            if (nil != bundle2) {
//                s_bundle = bundle2;
//            } else {
//                DLog(@"hostMainBundle == nil");
//            }
//        } else if ([bundle.bundleURL.pathExtension isEqualToString:@"app"]) {
//            s_bundle = bundle;
//        }
//    });
//    return s_bundle;
//}

- (BOOL)isHostMainBundle
{
    return [self.bundleURL.pathExtension isEqualToString:@"app"];
//    return [NSBundle.hostMainBundle isEqual:self];
}

+ (nullable NSString *)hostMainBundleIdentifier
{
    NSBundle *bundle = NSBundle.mainBundle;
    if (bundle.isHostMainBundle) {
        return bundle.bundleIdentifier;
    }
    NSString *str = bundle.bundleIdentifier;
    NSRange range = [str rangeOfString:@"." options:NSBackwardsSearch];
    if (NSNotFound == range.location) {
        if ([str isEqual:@"*"]) {
            return str;
        }
        return nil;
    }
    
    return [str substringToIndex:range.location];
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

- (nullable NSString *)displayName
{
    NSString *name = [self objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    return name.length > 0 ? name : self.bundleName;
}

@end

//@implementation UIImage (AppExtension)
//
//+ (UIImage *)hostMainBundleImageNamed:(NSString *)name
//{
//    NSBundle *bundle = NSBundle.hostMainBundle;
//    if (nil == bundle) {
//        return nil;
//    }
//    return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
//}
//
//@end
