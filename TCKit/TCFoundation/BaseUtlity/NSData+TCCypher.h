//
//  NSData+TCCypher.h
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


extern NSString *const TCCommonCryptoErrorDomain;

extern uint32_t tc_crc32_formula_reflect(size_t len, const unsigned char *buffer);

@interface NSData (TCCypher)


// Base64
- (NSData *)base64Encode;
- (nullable NSData *)base64Decode;
- (nullable NSData *)base64DecodeWithOptions:(NSDataBase64DecodingOptions)ops;

- (NSString *)base64EncodeString;


/**
 @brief keySize
 kCCKeySizeAES128          = 16,
 kCCKeySizeAES192          = 24,
 kCCKeySizeAES256          = 32,
 kCCKeySizeDES             = 8,
 kCCKeySize3DES            = 24,
 kCCKeySizeMinCAST         = 5,
 kCCKeySizeMaxCAST         = 16,
 kCCKeySizeMinRC4          = 1,
 kCCKeySizeMaxRC4          = 512,
 kCCKeySizeMinRC2          = 1,
 kCCKeySizeMaxRC2          = 128,
 kCCKeySizeMinBlowfish     = 8,
 kCCKeySizeMaxBlowfish     = 56,
 
 iv 16
 */
// CBC default
- (nullable NSData *)cryptoOperation:(CCOperation)operation algorithm:(CCAlgorithm)algorithm option:(CCOptions)option key:(nullable NSData *)key iv:(nullable NSData *)iv keySize:(size_t)keySize error:(NSError **)error;


/**
 @brief    
 case CC_SHA1_DIGEST_LENGTH:
 case CC_SHA256_DIGEST_LENGTH:
 case CC_SHA224_DIGEST_LENGTH:
 case CC_SHA384_DIGEST_LENGTH:
 case CC_SHA512_DIGEST_LENGTH:
 */
- (nullable NSData *)SHADigest:(NSUInteger)len;
- (nullable NSString *)SHAString:(NSUInteger)len;


- (nullable NSData *)Hmac:(CCHmacAlgorithm)alg key:(nullable NSData *)key;
- (nullable NSString *)HmacString:(CCHmacAlgorithm)alg key:(nullable NSData *)key;

- (nullable NSData *)MD5_32;
- (nullable NSData *)MD4;
- (nullable NSData *)MD2;

- (nullable NSString *)MD5String;
- (nullable NSString *)MD4String;
- (nullable NSString *)MD2String;

- (unsigned long)CRC32B;
- (nullable NSString *)CRC32BString;
- (uint32_t)CRC32;
- (nullable NSString *)CRC32String;
- (unsigned long)adler32;
- (nullable NSString *)adler32String;

- (nullable NSData *)RC4:(CCOperation)operation key:(nullable NSData *)key;

@end


@interface NSData (FastHex)

/** Returns an NSData instance constructed from the hex characters of the passed string.
 * A convenience method for \p -initWithHexString:ignoreOtherCharacters: with the value
 * YES for \p ignoreOtherCharacters . */
+ (instancetype)dataWithHexString:(NSString *)hexString;

/** Initializes the NSData instance with data from the hex characters of the passed string.
 *
 * \param hexString A string containing ASCII hexadecimal characters (uppercase and lowercase accepted).
 * \param ignoreOtherCharacters If YES, skips non-hexadecimal characters, and trailing characters.
 *  If NO, non-hexadecimal or trailing characters will abort parsing and this method will return nil.
 *
 * \return the initialized data instance, or nil if \p ignoreOtherCharacters is NO and \p hexString
 * contains a non-hex or trailing character. If \p hexString is the empty string, returns an empty
 * (non-nil) NSData instance. */
- (nullable instancetype)initWithHexString:(NSString *)hexString ignoreOtherCharacters:(BOOL)ignoreOtherCharacters;

/** Returns a string of the receiver's data bytes as uppercase hexadecimal characters. */
- (NSString *)hexStringRepresentation;

/** Returns a string of the receiver's data bytes as uppercase or lowercase hexadecimal characters.
 *
 * \param uppercase YES to use uppercase letters A-F; NO for lowercase a-f
 */
- (NSString *)hexStringRepresentationUppercase:(BOOL)uppercase seperator:(NSString *__nullable)seperator width:(NSUInteger)width;

- (nullable NSData *)extractFromHexData:(BOOL)ignoreOtherCharacters;

@end


@interface NSData (TCHelper)

- (NSRange)rangeOfString:(NSString *)strToFind encoding:(NSStringEncoding)encoding options:(NSDataSearchOptions)mask range:(NSRange * _Nullable)searchRange;

@end

NS_ASSUME_NONNULL_END
