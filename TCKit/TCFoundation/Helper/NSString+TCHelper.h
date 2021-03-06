//
//  NSString+TCHelper.h
//  TCKit
//
//  Created by dake on 16/2/18.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern bool tc_is_ip_addr(char const *host, bool *_Nullable ipv6);

@interface NSString (TCHelper)

- (NSString *)stringByAddSpaceEach;

- (NSString *)reversedString;

- (nullable NSMutableDictionary<NSString *, NSString *> *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue orderKey:(NSArray<NSString *> *_Nullable *_Nullable)orderKey decodeInf:(BOOL)decodeInf;
- (nullable NSString *)fixedFileExtension;
- (NSString *)stringByDeletingFixedPathExtension:(NSString *_Nullable *_Nullable)ext;
- (nullable NSString *)stringByAppendingPathExtensionMust:(NSString *)str;

- (NSString *)domainOrIPMust;

- (BOOL)hasInCasePrefix:(NSString *)str;
- (BOOL)hasInCaseSuffix:(NSString *)str;
- (nullable NSString *)safeStringByRemovingPercentEncoding;

#pragma mark - pattern

- (NSString *)firstCharacter;

// 去除标点符号, 空白符, 换行符, 空格, emoji
- (NSString *)clearSymbolAndWhiteString;

- (BOOL)isInteger;
- (BOOL)isPureNumber;
- (BOOL)isPureAlphabet;
- (BOOL)isValidIDCardNumberOfChina;
- (BOOL)isIPAddress:(BOOL *_Nullable)ipv6; // 纯 ip ，不能有端口，路径，方括号等
- (BOOL)isIPAddressInURLHost:(BOOL *_Nullable)ipv6; // [::1]:44/xx.cgi?a=b
- (BOOL)isLocalLAN;

/**
 @brief	convert IANA charset name encoding
 
 @param iana [IN] IANA charset name
 
 @return 0, if failed
 */
+ (NSStringEncoding)encodingForIANACharset:(NSString *)iana;
+ (nullable NSString *)IANACharsetForEncoding:(NSStringEncoding)encoding;
+ (nullable instancetype)stringWithData:(NSData *)data usedEncoding:(nullable NSStringEncoding *)enc force:(BOOL)force;
+ (nullable instancetype)stringWithData:(NSData *)data usedEncoding:(nullable NSStringEncoding *)enc force:(BOOL)force fast:(BOOL)fast;

- (BOOL)wrongEncoding;

- (nullable NSString *)stringByEscapingForHTML;
- (nullable NSString *)stringByEscapingForAsciiHTML;
- (nullable NSString *)stringByUnescapingHTML;

- (NSString *)replaceUnicode;

- (nullable NSString *)stringByBackEscaping;
- (NSString *)stringByBackUnescaping;
- (NSString *)replaceTemplate:(BOOL)unescaped;

@end

NS_ASSUME_NONNULL_END
