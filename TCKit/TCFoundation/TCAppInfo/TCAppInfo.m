//
//  TCAppInfo.m
//  TCKit
//
//  Created by dake on 13-4-15.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import "TCAppInfo.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <UIKit/UIApplication.h>
#import "FCUUID.h"

#define DEFAULT_PLIST_FOR_KEY(key)      ([NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)(key)] ?: @"")


static NSString *const kTCMigrationLastVersionKey = @"lastMigrationVersion.TCMigration.TCKit";
static NSString *const kTCMigrationLastBuildKey = @"lastMigrationBuild.TCMigration.TCKit";

static NSString *const kTCMigrationLastAppVersionKey = @"lastAppVersion.TCMigration.TCKit";
static NSString *const kTCMigrationLastAppBuildKey = @"lastAppBuild.TCMigration.TCKit";
static NSString *const kTCMigrationLastSysBuildKey = @"lastSysBuild.TCMigration.TCKit";

NSString *const kTCApplicationDidReceiveDiskSpaceWarning = @"TCApplicationDidReceiveDiskSpaceWarning.TCKit";


@implementation TCAppInfo

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(NSNotification *note) = ^(NSNotification * _Nonnull note) {
            NSDictionary *fattributes = [NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:NULL];
            NSNumber *size = fattributes[NSFileSystemFreeSize];
            if (nil != size && size.unsignedLongLongValue < 500e6) {
                [NSNotificationCenter.defaultCenter postNotificationName:kTCApplicationDidReceiveDiskSpaceWarning object:size];
            }
        };
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:block];
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:block];
    });
}

+ (NSString *)appVersion:(TCMigrationVersionType)type
{
    if (kTCMigrationShortVersion == type) {
        return DEFAULT_PLIST_FOR_KEY(@"CFBundleShortVersionString");
    } else if (kTCMigrationBuildVersion == type) {
        return DEFAULT_PLIST_FOR_KEY(kCFBundleVersionKey);
    }
    
    return @"";
}

+ (NSString *)bundleName
{
    return DEFAULT_PLIST_FOR_KEY(kCFBundleNameKey);
}

+ (NSString *)displayName
{
    NSString *name = DEFAULT_PLIST_FOR_KEY(@"CFBundleDisplayName");
    return name.length > 0 ? name : self.bundleName;
}

+ (NSString *)bundleIdentifier
{
    return DEFAULT_PLIST_FOR_KEY(kCFBundleIdentifierKey);
}

+ (NSString *)uuidForDevice
{
    return FCUUID.uuidForDevice ?: @"";
}


#pragma mark - TCMigration

+ (void)migrateToVersion:(NSString *)version type:(TCMigrationVersionType)type domain:(NSString *)domain block:(dispatch_block_t)block
{
    NSCParameterAssert(version);
    
    if (nil == version) {
        return;
    }
    
    if (nil == domain) {
        domain = @"default";
    }
    
    // version > lastMigrationVersion && version <= appVersion
    if ([version compare:[self lastMigrationVersion:type domain:domain] options:NSNumericSearch] == NSOrderedDescending &&
        [version compare:[self appVersion:type] options:NSNumericSearch] != NSOrderedDescending) {
        if (nil != block) {
            block();
        }
        [self setLastMigrationVersion:version type:type domain:domain];
    }
}

+ (void)migrateResetDomain:(NSString *)domain type:(TCMigrationVersionType)type
{
    if (nil == domain) {
        domain = @"default";
    }
    
    [self setLastMigrationVersion:nil type:type domain:domain];
}

+ (BOOL)migratedVersion:(NSString *)version type:(TCMigrationVersionType)type domain:(NSString *)domain
{
    NSCParameterAssert(version);
    if (nil == version) {
        return YES;
    }
    
    if (nil == domain) {
        domain = @"default";
    }
    
    NSString *ver = [self lastMigrationVersion:type domain:domain];
    return ver.length < 1 ? NO : [ver compare:version options:NSNumericSearch] != NSOrderedAscending;
}

+ (void)applicationUpdateBlock:(dispatch_block_t)block type:(TCMigrationVersionType)type domain:(NSString *)domain
{
    if (nil == domain) {
        domain = @"default";
    }
    
    NSString *version = [self appVersion:type];
    if (![[self lastUpdateVersionForType:type domain:domain] isEqualToString:version]) {
        if (nil != block) {
            block();
        }
        [self setLastUpdateVersion:version type:type domain:domain];
    }
}

+ (void)updateResetDomain:(NSString *)domain type:(TCMigrationVersionType)type
{
    if (nil == domain) {
        domain = @"default";
    }
    
    [self setLastUpdateVersion:nil type:type domain:domain];
}

+ (BOOL)updatedVersion:(TCMigrationVersionType)type domain:(NSString *)domain
{
    if (nil == domain) {
        domain = @"default";
    }
    
    NSString *ver = [self lastUpdateVersionForType:type domain:domain];
    
    return ver.length < 1 ? NO : [ver isEqualToString:[self appVersion:type]];
}

+ (void)systemUpdateBlock:(dispatch_block_t)block domain:(NSString *)domain
{
    if (nil == domain) {
        domain = @"default";
    }
    
    NSString *version = UIDevice.currentDevice.systemVersion;
    if (![[self lastSysVersionForDomain:domain] isEqualToString:version]) {
        if (nil != block) {
            block();
        }
        [self setLastSysVersion:version domain:domain];
    }
}


// migrate version

+ (NSString *)versionMigrationKeyForType:(TCMigrationVersionType)type domain:(NSString *)domain
{
    NSString *rootKey = nil;
    if (kTCMigrationShortVersion == type) {
        rootKey = kTCMigrationLastVersionKey;
    } else if (kTCMigrationBuildVersion == type) {
        rootKey = kTCMigrationLastBuildKey;
    } else {
        rootKey = kTCMigrationLastBuildKey;
    }
    
    return [domain stringByAppendingFormat:@".%@", rootKey];
}

+ (NSString *)lastMigrationVersion:(TCMigrationVersionType)type domain:(NSString *)domain
{
    NSString *res = [NSUserDefaults.standardUserDefaults valueForKey:[self versionMigrationKeyForType:type domain:domain]];
    return res ?: @"";
}

+ (void)setLastMigrationVersion:(NSString *)version type:(TCMigrationVersionType)type domain:(NSString *)domain
{
    [NSUserDefaults.standardUserDefaults setValue:version forKey:[self versionMigrationKeyForType:type domain:domain]];
    [NSUserDefaults.standardUserDefaults synchronize];
}


// update vesion

+ (NSString *)versionUpdateKeyForType:(TCMigrationVersionType)type domain:(NSString *)domain
{
    NSString *rootKey = nil;
    if (kTCMigrationShortVersion == type) {
        rootKey = kTCMigrationLastAppVersionKey;
    } else if (kTCMigrationBuildVersion == type) {
        rootKey = kTCMigrationLastAppBuildKey;
    } else {
        rootKey = kTCMigrationLastAppBuildKey;
    }
    
    return [domain stringByAppendingFormat:@".%@", rootKey];
}

+ (NSString *)lastUpdateVersionForType:(TCMigrationVersionType)type domain:(NSString *)domain
{
    NSString *res = [NSUserDefaults.standardUserDefaults valueForKey:[self versionUpdateKeyForType:type domain:domain]];
    return res ?: @"";
}

+ (void)setLastUpdateVersion:(NSString *)version type:(TCMigrationVersionType)type domain:(NSString *)domain
{
    [NSUserDefaults.standardUserDefaults setValue:version forKey:[self versionUpdateKeyForType:type domain:domain]];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (NSString *)lastSysVersionForDomain:(NSString *)domain
{
    NSString *res = [NSUserDefaults.standardUserDefaults valueForKey:[domain stringByAppendingFormat:@".%@", kTCMigrationLastSysBuildKey]];
    return res ?: @"";
}

+ (void)setLastSysVersion:(NSString *)version domain:(NSString *)domain
{
    [NSUserDefaults.standardUserDefaults setValue:version forKey:[domain stringByAppendingFormat:@".%@", kTCMigrationLastSysBuildKey]];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
