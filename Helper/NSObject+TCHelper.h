//
//  NSObject+TCHelper.h
//  TCKit
//
//  Created by dake on 14-5-4.
//  Copyright (c) 2014年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (TCHelper)

@property (nullable, nonatomic, copy) NSString *humanDescription;

// file system
+ (nullable NSString *)defaultPersistentDirectoryInDomain:(NSString *__nullable)domain;
+ (nullable NSString *)defaultCacheDirectoryInDomain:(NSString *__nullable)domain;
+ (nullable NSString *)defaultTmpDirectoryInDomain:(NSString *__nullable)domain;

@end

NS_ASSUME_NONNULL_END
