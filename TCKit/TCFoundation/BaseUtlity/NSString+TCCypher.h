//
//  NSString+TCCypher.h
//  TCKit
//
//  Created by dake on 15/3/11.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (TCCypher)

// for AES

/**
 @brief keySize
 kCCKeySizeAES128          = 16,
 kCCKeySizeAES192          = 24,
 kCCKeySizeAES256          = 32,
 */
- (nullable NSData *)AESEncryptWithKey:(nullable NSData *)key iv:(nullable NSData *)iv keySize:(size_t)keySize;
- (nullable NSData *)AESDecryptBase64WithKey:(nullable NSData *)key iv:(nullable NSData *)iv keySize:(size_t)keySize;
- (nullable NSData *)AESDecryptHexWithKey:(nullable NSData *)key iv:(nullable NSData *)iv keySize:(size_t)keySize;

// for MD5
- (nullable NSString *)MD5_32;
- (nullable NSString *)MD5_16;

- (nullable NSString *)MD5_32:(NSStringEncoding)encoding;
- (nullable NSString *)MD5_16:(NSStringEncoding)encoding;

- (nullable NSString *)MD2;
- (nullable NSString *)MD4;

- (nullable NSString *)MD2:(NSStringEncoding)encoding;
- (nullable NSString *)MD4:(NSStringEncoding)encoding;

- (unsigned long)CRC32B;
- (nullable NSString *)CRC32BString;
- (unsigned long)CRC32;
- (nullable NSString *)CRC32String;
- (unsigned long)adler32;
- (nullable NSString *)adler32String;

/**
 @brief
 case CC_SHA1_DIGEST_LENGTH:
 case CC_SHA256_DIGEST_LENGTH:
 case CC_SHA224_DIGEST_LENGTH:
 case CC_SHA384_DIGEST_LENGTH:
 case CC_SHA512_DIGEST_LENGTH:
 */
- (nullable NSString *)SHAString:(NSUInteger)len;
- (nullable NSString *)SHAString:(NSUInteger)len encoding:(NSStringEncoding)encoding;

- (nullable NSString *)Hmac:(CCHmacAlgorithm)alg key:(nullable NSData *)key;
- (nullable NSString *)Hmac:(CCHmacAlgorithm)alg key:(nullable NSData *)key encoding:(NSStringEncoding)encoding;

// base64
- (nullable NSString *)base64Encode;
- (nullable NSString *)base64Decode;
- (nullable NSString *)base64DecodeWithOptions:(NSDataBase64DecodingOptions)options;
- (nullable NSData *)base64DecodeData;
- (nullable NSData *)base64DecodeDataWithOptions:(NSDataBase64DecodingOptions)options;

- (nullable NSString *)base64Encode:(NSStringEncoding)encoding;
- (nullable NSString *)base64Decode:(NSStringEncoding)encoding;
- (nullable NSString *)base64DecodeWithOptions:(NSDataBase64DecodingOptions)options encoding:(NSStringEncoding)encoding;

@end

NS_ASSUME_NONNULL_END
