//
//  TCAppInfo.h
//  TCKit
//
//  Created by dake on 13-4-15.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, TCMigrationVersionType) {
    kTCMigrationShortVersion, // e.g. 2.1.0
    kTCMigrationBuildVersion, // e.g. 2.1.0.23
};


NS_ASSUME_NONNULL_BEGIN

extern NSString *const kTCApplicationDidReceiveDiskSpaceWarning;

@interface TCAppInfo : NSObject

+ (NSString *)appVersion:(TCMigrationVersionType)type;

+ (NSString *)uuidForDevice;


#pragma mark - TCMigration
// code from: https://github.com/mysterioustrousers/MTMigration

/**
 Executes a block of code for a specific version number and remembers this version as the latest migration done by TCMigration.
 
 @param version A string with a specific version number
 @param migrationBlock A block object to be executed when the application version matches the string 'version'. This parameter can't be nil.
 
 */
+ (void)migrateToVersion:(NSString *)version type:(TCMigrationVersionType)type domain:(nullable NSString *)domain block:(nullable dispatch_block_t)migrationBlock;


/**
 Clears the last migration remembered by TCMigration. Causes all migrations to run from the beginning.
 
 */
+ (void)migrateResetDomain:(nullable NSString *)domain type:(TCMigrationVersionType)type;
+ (BOOL)migratedVersion:(NSString *)version type:(TCMigrationVersionType)type domain:(nullable NSString *)domain;


/**
 
 Executes a block of code for every time the application version changes.
 
 @param updateBlock A block object to be executed when the application version changes. This parameter can't be nil.
 
 */
+ (void)applicationUpdateBlock:(nullable dispatch_block_t)updateBlock type:(TCMigrationVersionType)type domain:(nullable NSString *)domain;
+ (void)updateResetDomain:(nullable NSString *)domain type:(TCMigrationVersionType)type;
+ (BOOL)updatedVersion:(TCMigrationVersionType)type domain:(nullable NSString *)domain;
+ (void)systemUpdateBlock:(dispatch_block_t)block domain:(nullable NSString *)domain;

@end

NS_ASSUME_NONNULL_END
