//
//  NSURL+TCHelper.h
//  TCKit
//
//  Created by dake on 16/8/19.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/UTCoreTypes.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * TCPercentEscapedStringFromString(NSString *string);
extern NSString *_Nullable TCPercentEscapedStringFromFileName(NSString *string);

@interface NSURL (TCHelper)

- (nullable NSMutableDictionary<NSString *, NSString *> *)parseQueryToDictionaryWithDecodeInf:(BOOL)decodeInf orderKey:(NSArray<NSString *> *_Nullable *_Nullable)orderKey;
- (NSURL *)appendParam:(NSDictionary<NSString *, id> *)param orderKey:(NSArray<NSString *> *_Nullable)orderKey overwrite:(BOOL)force encodeQuering:(BOOL)encode;
- (NSURL *)appendParamIfNeed:(NSDictionary<NSString *, id> *)param orderKey:(NSArray<NSString *> *_Nullable)orderKey;

- (unsigned long long)contentSizeInByte;

// xx.tar.gz -> tar.gz,
// xx.jpg?i=xx&j=oo -> jpg
- (nullable NSString *)fixedFileExtension;
- (nullable NSURL *)URLByAppendingPathExtensionMust:(NSString *)pathExtension;

// "http://bid.cn/path/?er=1" 这种为 .path 补全最后的 /
- (nullable NSString *)fixedPath;

- (BOOL)isEqualToFile:(NSURL *)url;

- (BOOL)isHttpURL;

// ipv6 无端口也带 []
- (nullable NSString *)hostport;


/**
@brief
case CC_SHA1_DIGEST_LENGTH:
case CC_SHA256_DIGEST_LENGTH:
case CC_SHA224_DIGEST_LENGTH:
case CC_SHA384_DIGEST_LENGTH:
case CC_SHA512_DIGEST_LENGTH:
*/
- (nullable NSString *)fileSHA:(NSUInteger)digestLen;
- (nullable NSString *)fileMD5_32;
- (nullable NSString *)fileMD2;
- (nullable NSString *)fileMD4;
- (nullable NSString *)fileHmac:(CCHmacAlgorithm)alg key:(nullable NSData *)key;
- (void)tc_fileMD5:(NSString *_Nullable *_Nullable)md5 sha256:(NSString *_Nullable *_Nullable)sha256;

- (unsigned long)fileCRC32;
- (nullable NSString *)fileCRC32String;
- (unsigned long)fileCRC32B;
- (nullable NSString *)fileCRC32BString;
- (unsigned long)fileAdler32;
- (nullable NSString *)fileAdler32String;

- (NSURL *)safeURLByResolvingSymlinksInPath;

@end

@interface NSCharacterSet (TCHelper)

+ (NSCharacterSet *)urlComponentAllowedCharacters;
+ (NSCharacterSet *)illegalFileNameCharacters;

@end

@interface NSFileManager (TCHelper)

- (BOOL)linkCopyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError *_Nullable *_Nullable)error;
- (BOOL)moveItemMustAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError *_Nullable *_Nullable)error;

@end


@interface UIPasteboard (TCHelper)

// NSURL, NSData
- (BOOL)setFile:(id<NSSecureCoding>)item suggestedName:(NSString *_Nullable)suggestedName uti:(NSString *_Nullable  *_Nullable)uti;

- (nullable NSURL *)fileForName:(NSString *_Nullable)suggestedName uti:(NSString *_Nullable)uti;

@end


NS_ASSUME_NONNULL_END
