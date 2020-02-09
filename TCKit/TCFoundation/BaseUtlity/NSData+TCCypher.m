//
//  NSData+TCCypher.m
//  TCKit
//
//  Created by dake on 15/3/11.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "NSData+TCCypher.h"

#if ! __has_feature(objc_arc)
#error this file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


uLong tc_crc32_formula_reflect(uLong crc0, const Bytef *buffer, uInt len)
{
    if (NULL == buffer || len < 1) {
        return crc0;
    }
    
    static const uLong POLY = 0x04C11DB7UL;
    uLong crc = crc0 > 0 ? htonl(~crc0) : ULONG_MAX;
    do {
        crc = crc ^ ((uLong)(*buffer++) << 24);
        for (int bit = 0; bit < 8; bit++) {
            if ((crc & (1U << 31)) != 0) {
                crc = (crc << 1) ^ POLY;
            } else {
                crc = (crc << 1);
            }
        }
    } while (--len > 0);    
    return ntohl(~crc);
}

static void fixKeyLengths(CCAlgorithm algorithm, NSMutableData *keyData, NSMutableData *ivData)
{
    NSUInteger keyLength = keyData.length;
    NSUInteger ivLen = 0;
    switch (algorithm) {
        case kCCAlgorithmAES: {
            if (keyLength <= kCCKeySizeAES128) {
                keyData.length = kCCKeySizeAES128;
            } else if (keyLength <= kCCKeySizeAES192) {
                keyData.length = kCCKeySizeAES192;
            } else {
                keyData.length = kCCKeySizeAES256;
            }
            
            ivLen = kCCBlockSizeAES128;
            break;
        }
            
        case kCCAlgorithmDES: {
            keyData.length = kCCKeySizeDES;
            ivLen = kCCBlockSizeDES;
            break;
        }
            
        case kCCAlgorithm3DES: {
            keyData.length = kCCKeySize3DES;
            ivLen = kCCBlockSize3DES;
            break;
        }
            
        case kCCAlgorithmCAST: {
            if (keyLength < kCCKeySizeMinCAST) {
                keyData.length = kCCKeySizeMinCAST;
            } else if (keyLength > kCCKeySizeMaxCAST) {
                keyData.length = kCCKeySizeMaxCAST;
            }
            ivLen = kCCBlockSizeCAST;
            break;
        }
            
        case kCCAlgorithmRC4: {
            if (keyLength < kCCKeySizeMinRC4) {
                keyData.length = kCCKeySizeMinRC4;
            } else if (keyLength > kCCKeySizeMaxRC4) {
                keyData.length = kCCKeySizeMaxRC4;
            }
            break;
        }
            
        case kCCAlgorithmRC2: {
            if (keyLength < kCCKeySizeMinRC2) {
                keyData.length = kCCKeySizeMinRC2;
            } else if (keyLength > kCCKeySizeMaxRC2) {
                keyData.length = kCCKeySizeMaxRC2;
            }
            ivLen = kCCBlockSizeRC2;
            break;
        }
            
        case kCCAlgorithmBlowfish: {
            if (keyLength < kCCKeySizeMinBlowfish) {
                keyData.length = kCCKeySizeMinBlowfish;
            } else if (keyLength > kCCKeySizeMaxBlowfish) {
                keyData.length = kCCKeySizeMaxBlowfish;
            }
            ivLen = kCCBlockSizeBlowfish;
            break;
        }
            
        default:
            break;
    }
    
    if (nil != ivData && ivLen > 0) {
        ivData.length = ivLen;
    }
}



NSString *const TCCommonCryptoErrorDomain = @"TCCommonCryptoErrorDomain";

@implementation NSError (CommonCryptoErrorDomain)

+ (NSError *)errorWithCCCryptorStatus:(CCCryptorStatus)status
{
    NSString *description = nil, *reason = nil;
    
    switch (status) {
        case kCCSuccess:
            return nil;
            
        case kCCParamError:
            description = NSLocalizedString(@"Parameter Error", @"Error description");
            reason = NSLocalizedString(@"Illegal parameter supplied to encryption/decryption algorithm", @"Error reason");
            break;
            
        case kCCBufferTooSmall:
            description = NSLocalizedString(@"Buffer Too Small", @"Error description");
            reason = NSLocalizedString(@"Insufficient buffer provided for specified operation", @"Error reason");
            break;
            
        case kCCMemoryFailure:
            description = NSLocalizedString(@"Memory Failure", @"Error description");
            reason = NSLocalizedString(@"Failed to allocate memory", @"Error reason");
            break;
            
        case kCCAlignmentError:
            description = NSLocalizedString(@"Alignment Error", @"Error description");
            reason = NSLocalizedString(@"Input size to encryption algorithm was not aligned correctly", @"Error reason");
            break;
            
        case kCCDecodeError:
            description = NSLocalizedString(@"Decode Error", @"Error description");
            reason = NSLocalizedString(@"Input data did not decode or decrypt correctly", @"Error reason");
            break;
            
        case kCCUnimplemented:
            description = NSLocalizedString(@"Unimplemented Function", @"Error description");
            reason = NSLocalizedString(@"Function not implemented for the current algorithm", @"Error reason");
            break;
            
        default:
            description = NSLocalizedString(@"Unknown Error", @"Error description");
            reason = NSLocalizedString(@"Unknown Error", @"Error description");
            break;
    }
    
    NSMutableDictionary *userInfo = NSMutableDictionary.dictionary;
    userInfo[NSLocalizedDescriptionKey] = description;
    if (reason != nil) {
         userInfo[NSLocalizedFailureReasonErrorKey] = reason;
    }
    
    return [NSError errorWithDomain:TCCommonCryptoErrorDomain code:status userInfo:userInfo];
}

@end

@implementation NSData (TCCypher)


#pragma mark - Base64

- (NSData *)base64Encode
{
    NSData *data = nil;
    @try {
        data = [self base64EncodedDataWithOptions:kNilOptions];
    } @catch (NSException *exception) {
        
    } @finally {
        return data;
    }
}

- (NSData *)base64DecodeWithOptions:(NSDataBase64DecodingOptions)ops
{
    NSData *data = nil;
    @try {
        data = [[NSData alloc] initWithBase64EncodedData:self options:ops];
    } @catch (NSException *exception) {
        
    } @finally {
        return data;
    }
}

- (NSData *)base64Decode
{
    return [self base64DecodeWithOptions:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (NSString *)base64EncodeString
{
    return [self base64EncodedStringWithOptions:kNilOptions];
}


#pragma mark -

- (nullable NSData *)dataUsingAlgorithm:(CCAlgorithm)alg
                              operation:(CCOperation)op
                                    key:(NSData *)key
                                     iv:(NSData *)iv
                                  tweak:(NSData *)tweak
                                   mode:(CCMode)mode
                                padding:(CCPadding)padding
                                  error:(CCCryptorStatus *)error
{
    NSMutableData *keyData = key.mutableCopy ?: NSMutableData.data;
    NSMutableData *ivData = iv.mutableCopy;
    fixKeyLengths(alg, keyData, ivData);
    
    NSData *tweakData = tweak;
    if (kCCModeXTS == mode) {
        ivData = nil;
        if (tweak.length != keyData.length) {
            NSMutableData *data = tweak.mutableCopy ?: NSMutableData.data;
            data.length = keyData.length;
            tweakData = data;
        }
    } else {
        tweakData = nil;
    }
    
    // Missing and needed for CTR mode is CCModeOptions kCCModeOptionCTR_LE or kCCModeOptionCTR_BE
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = CCCryptorCreateWithMode(op,
                                                     mode, alg, padding,
                                                     ivData.bytes,
                                                     keyData.bytes, keyData.length,
                                                     tweakData.bytes, tweakData.length,
                                                     0,
                                                     (kCCModeCTR == mode) ? kCCModeOptionCTR_BE : 0,
                                                     &cryptor);
    
    if (NULL == cryptor || status != kCCSuccess) {
        if (error != NULL) {
            *error = status;
        }
        if (NULL != cryptor) {
            CCCryptorRelease(cryptor);
        }
        return nil;
    }
    
    NSData *result = [self _runCryptor:cryptor result:&status];
    if (result == nil && error != NULL) {
        *error = status;
    }
    CCCryptorRelease(cryptor);
    return result;
}

- (NSData *)_runCryptor:(CCCryptorRef)cryptor result:(CCCryptorStatus *)status
{
    size_t bufsize = CCCryptorGetOutputLength(cryptor, (size_t)self.length, true);
    if (bufsize < 1) {
        *status = kCCAlignmentError;
        return nil;
    }
    void *buf = calloc(bufsize, 1);
    if (NULL == buf) {
        *status = kCCMemoryFailure;
        return nil;
    }
    
    size_t bufused = 0;
    size_t bytesTotal = 0;
    *status = CCCryptorUpdate(cryptor, self.bytes, (size_t)self.length, buf, bufsize, &bufused);
    if (*status != kCCSuccess) {
        free(buf);
        return nil;
    }
    bytesTotal += bufused;
    
    // From Brent Royal-Gordon (Twitter: architechies):
    // Need to update buf ptr past used bytes when calling CCCryptorFinal()
    *status = CCCryptorFinal(cryptor, buf + bufused, bufsize - bufused, &bufused);
    if (*status != kCCSuccess) {
        free(buf);
        return nil;
    }
    
    bytesTotal += bufused;
    return [NSData dataWithBytesNoCopy:buf length:bytesTotal];
}

- (nullable NSData *)crypto:(CCOperation)op
                  algorithm:(CCAlgorithm)alg
                       mode:(CCMode)mode
                    padding:(CCPadding)padding
                        key:(nullable NSData *)key
                         iv:(nullable NSData *)iv
                      tweak:(nullable NSData *)tweak
                    keySize:(size_t)keySize
                      error:(NSError * _Nullable __strong * _Nullable)error
{
    NSMutableData *keyData = key.mutableCopy ?: NSMutableData.data;
    if (keySize > 0) {
        keyData.length = keySize;
    }
    
    CCCryptorStatus status = kCCSuccess;
    NSData *result = [self dataUsingAlgorithm:alg
                                    operation:op
                                          key:keyData
                                           iv:iv
                                        tweak:tweak
                                         mode:(mode != 0 ? mode : kCCModeCBC)
                                      padding:padding
                                        error:&status];
    if (result != nil) {
        return result;
    }
    
    if (error != NULL) {
        *error = [NSError errorWithCCCryptorStatus:status];
    }
    return nil;
}

- (nullable NSData *)RC4:(CCOperation)op key:(nullable NSData *)key
{
    return [self crypto:op algorithm:kCCAlgorithmRC4 mode:kCCModeRC4 padding:ccNoPadding key:key iv:nil tweak:nil keySize:0 error:NULL];
}

// SHA
- (NSData *)SHADigest:(NSUInteger)len
{
    unsigned char result[len];
    
    switch (len) {
        case CC_SHA1_DIGEST_LENGTH:
             CC_SHA1(self.bytes, (CC_LONG)self.length, result);
            break;
            
        case CC_SHA256_DIGEST_LENGTH:
            CC_SHA256(self.bytes, (CC_LONG)self.length, result);
            break;
            
        case CC_SHA224_DIGEST_LENGTH:
            CC_SHA224(self.bytes, (CC_LONG)self.length, result);
            break;
            
        case CC_SHA384_DIGEST_LENGTH:
            CC_SHA384(self.bytes, (CC_LONG)self.length, result);
            break;
            
        case CC_SHA512_DIGEST_LENGTH:
            CC_SHA512(self.bytes, (CC_LONG)self.length, result);
            break;
            
        default:
            return nil;
    }
    
    return [NSData dataWithBytes:result length:len];
}

- (nullable NSString *)SHAString:(NSUInteger)len
{
    NSData *data = [self SHADigest:len];
    if (nil == data) {
        return nil;
    }
    
    const unsigned char *result = data.bytes;
    NSUInteger dataLen = data.length;
    NSMutableString *str = [NSMutableString stringWithCapacity:dataLen * 2];
    for (NSUInteger i = 0; i < dataLen; ++i) {
        [str appendFormat:@"%02x", result[i]];
    }
    return str;
}

- (nullable NSData *)Hmac:(CCHmacAlgorithm)alg key:(nullable NSData *)key
{
    NSUInteger digestLen = 0;
    switch (alg) {
        case kCCHmacAlgSHA1:
            digestLen = CC_SHA1_DIGEST_LENGTH;
            break;
        case kCCHmacAlgMD5:
            digestLen = CC_MD5_DIGEST_LENGTH;
            break;
        case kCCHmacAlgSHA224:
            digestLen = CC_SHA224_DIGEST_LENGTH;
            break;
        case kCCHmacAlgSHA256:
            digestLen = CC_SHA256_DIGEST_LENGTH;
            break;
        case kCCHmacAlgSHA384:
            digestLen = CC_SHA384_DIGEST_LENGTH;
            break;
        case kCCHmacAlgSHA512:
            digestLen = CC_SHA512_DIGEST_LENGTH;
            break;
        default:
            return nil;
    }
    
    unsigned char buf[digestLen];
    bzero(buf, digestLen);
    CCHmac(alg, key.bytes, key.length, self.bytes, self.length, buf);
    return [NSData dataWithBytes:buf length:digestLen];
}

- (nullable NSString *)HmacString:(CCHmacAlgorithm)alg key:(nullable NSData *)key
{
    NSData *data = [self Hmac:alg key:key];
    if (nil == data) {
        return nil;
    }
    
    const unsigned char *result = data.bytes;
    NSUInteger dataLen = data.length;
    NSMutableString *outputString = [NSMutableString stringWithCapacity:dataLen * 2];
    for (NSUInteger i = 0; i < dataLen; ++i) {
        [outputString appendFormat:@"%02x", result[i]];
    }
    return outputString;
}

- (NSData *)MD5_32
{
    unsigned char buf[CC_MD5_DIGEST_LENGTH];
    bzero(buf, sizeof(buf));
    CC_MD5(self.bytes, (CC_LONG)self.length, buf);
    return [NSData dataWithBytes:buf length:CC_MD5_DIGEST_LENGTH];
}

- (NSData *)MD4
{
    unsigned char buf[CC_MD4_DIGEST_LENGTH];
    bzero(buf, sizeof(buf));
    CC_MD4(self.bytes, (CC_LONG)self.length, buf);
    return [NSData dataWithBytes:buf length:CC_MD4_DIGEST_LENGTH];
}

- (NSData *)MD2
{
    unsigned char buf[CC_MD2_DIGEST_LENGTH];
    bzero(buf, sizeof(buf));
    CC_MD2(self.bytes, (CC_LONG)self.length, buf);
    return [NSData dataWithBytes:buf length:CC_MD2_DIGEST_LENGTH];
}

// https://stackoverflow.com/questions/39005351/zlib-seems-to-be-returning-crc32b-not-crc32-in-c
- (unsigned long)CRC32B
{
    if (self.length < 1) {
        return 0;
    }
    uLong crc = crc32(0L, Z_NULL, 0);
    return crc32(crc, self.bytes, (uInt)self.length);
}

- (nullable NSString *)CRC32BString
{
    if (self.length < 1) {
        return nil;
    }
    uLong c = self.CRC32B;
    return [NSString stringWithFormat:@"%08lx", c];
}

- (unsigned long)CRC32
{
    if (self.length < 1) {
        return 0U;
    }

    return tc_crc32_formula_reflect(0L, (const Bytef *)self.bytes, (uInt)self.length);
}

- (nullable NSString *)CRC32String
{
    return [NSString stringWithFormat:@"%08lx", self.CRC32];
}

- (unsigned long)adler32
{
    if (self.length < 1) {
        return 0;
    }
    uLong crc = adler32(0L, Z_NULL, 0);
    return adler32(crc, self.bytes, (uInt)self.length);
}

- (nullable NSString *)adler32String
{
    if (self.length < 1) {
        return nil;
    }
    uLong crc = adler32(0L, Z_NULL, 0);
    uLong c = adler32(crc, self.bytes, (uInt)self.length);
    return [NSString stringWithFormat:@"%08lx", c];
}


- (nullable NSString *)MD5String
{
    return self.MD5_32.hexStringRepresentation;
}

- (nullable NSString *)MD4String
{
    return self.MD4.hexStringRepresentation;
}

- (nullable NSString *)MD2String
{
    return self.MD2.hexStringRepresentation;
}


@end


@implementation NSData (FastHex)

static const uint8_t invalidNibble = 128;

static uint8_t nibbleFromChar(unichar c) {
    if (c >= '0' && c <= '9') {
        return (uint8_t)(c - '0');
    } else if (c >= 'A' && c <= 'F') {
        return (uint8_t)(10 + c - 'A');
    } else if (c >= 'a' && c <= 'f') {
        return (uint8_t)(10 + c - 'a');
    } else {
        return invalidNibble;
    }
}

+ (instancetype)dataWithHexString:(NSString *)hexString
{
    return [[self alloc] initWithHexString:hexString ignoreOtherCharacters:YES];
}

- (nullable NSData *)extractFromHexData:(BOOL)ignoreOtherCharacters
{
    const NSUInteger charLength = self.length;
    if (charLength < 1) {
        return nil;
    }
    
    const NSUInteger maxByteLength = charLength / 2;
    uint8_t *const bytes = malloc(maxByteLength);
    if (NULL == bytes) {
        return nil;
    }
    uint8_t *bytePtr = bytes;
    const uint8_t *rawBytes = self.bytes;
    
    uint8_t hiNibble = invalidNibble;
    for (CFIndex i = 0; i < charLength; ++i) {
        uint8_t nextNibble = nibbleFromChar(rawBytes[i]);
        if (nextNibble == invalidNibble && !ignoreOtherCharacters) {
            if (rawBytes[i] == ' ') {
                continue;
            }
            free(bytes);
            return nil;
        } else if (hiNibble == invalidNibble) {
            hiNibble = nextNibble;
        } else if (nextNibble != invalidNibble) {
            // Have next full byte
            *bytePtr++ = (uint8_t)((hiNibble << 4) | nextNibble);
            hiNibble = invalidNibble;
        }
    }
    
    if (hiNibble != invalidNibble && !ignoreOtherCharacters) { // trailing hex character
        free(bytes);
        return nil;
    }
    
    if (bytePtr <= bytes) {
        free(bytes);
        return nil;
    }
  
    return [NSData dataWithBytesNoCopy:bytes length:(NSUInteger)(bytePtr - bytes) freeWhenDone:YES];
}

- (nullable instancetype)initWithHexString:(NSString *)hexString ignoreOtherCharacters:(BOOL)ignoreOtherCharacters
{
    if (nil == hexString) {
        return nil;
    }
    
    const NSUInteger charLength = hexString.length;
    const NSUInteger maxByteLength = charLength / 2;
    uint8_t *const bytes = malloc(maxByteLength);
    if (NULL == bytes) {
        return nil;
    }
    uint8_t *bytePtr = bytes;
    
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer((CFStringRef)hexString, &inlineBuffer, CFRangeMake(0, (CFIndex)charLength));
    
    // Each byte is made up of two hex characters; store the outstanding half-byte until we read the second
    uint8_t hiNibble = invalidNibble;
    for (CFIndex i = 0; i < charLength; ++i) {
        uint8_t nextNibble = nibbleFromChar(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i));
        
        if (nextNibble == invalidNibble && !ignoreOtherCharacters) {
            free(bytes);
            return nil;
        } else if (hiNibble == invalidNibble) {
            hiNibble = nextNibble;
        } else if (nextNibble != invalidNibble) {
            // Have next full byte
            *bytePtr++ = (uint8_t)((hiNibble << 4) | nextNibble);
            hiNibble = invalidNibble;
        }
    }
    
    if (hiNibble != invalidNibble && !ignoreOtherCharacters) { // trailing hex character
        free(bytes);
        return nil;
    }
    
    if (bytePtr <= bytes) {
        free(bytes);
        return nil;
    }
    
    return [self initWithBytesNoCopy:bytes length:(NSUInteger)(bytePtr - bytes) freeWhenDone:YES];
}

- (NSString *)hexStringRepresentation
{
    return [self hexStringRepresentationUppercase:NO seperator:nil width:0];
}

- (NSString *)hexStringRepresentationUppercase:(BOOL)uppercase seperator:(NSString *__nullable)seperator width:(NSUInteger)width
{
    const char *const hexTable = uppercase ? "0123456789ABCDEF" : "0123456789abcdef";
    const NSUInteger charLength = self.length * 2;

    
    char *const hexChars = malloc(charLength * sizeof(*hexChars));
    __block char *charPtr = hexChars;
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        const uint8_t *bytePtr = bytes;
        for (NSUInteger count = 0; count < byteRange.length; ++count) {
            const uint8_t byte = *bytePtr++;
            *charPtr++ = hexTable[(byte >> 4) & 0xF];
            *charPtr++ = hexTable[byte & 0xF];
        }
    }];
    
    NSMutableString *str = [[NSMutableString alloc] initWithBytesNoCopy:hexChars length:charLength encoding:NSASCIIStringEncoding freeWhenDone:YES];
    
    NSUInteger sepLen = seperator.length;
    BOOL sep = sepLen > 0 && width > 0;
    if (sep) {
        NSUInteger unitCount = (charLength + width - 1) / width;
        for (NSUInteger i = 0; i < unitCount; ++i) {
            NSUInteger index = (i + 1) * width + i * sepLen;
            [str insertString:seperator atIndex:index];
        }
    }
    
    return str;
}


#pragma mark - quoted-printable

// https://github.com/etoile/Inbox/blob/fd2adfb1059a3572a7d86b587ba7e68003db299d/Pantomime/Framework/Pantomime/NSData%2BExtensions.m

- (NSData *)encodeQuotedPrintableWithLineLength:(NSUInteger)theLength inHeader:(BOOL)aBOOL
{
    static const char *const hexDigit = "0123456789ABCDEF";
    
    if (self.length < 1) {
        return self;
    }
    
    NSUInteger length = self.length;
    NSMutableData *aMutableData = [NSMutableData dataWithCapacity:length];
    const unsigned char  *b = self.bytes;
    
    char buf[4] = {'=', '\0', '\0', '\0'};
    NSUInteger line = 0;
    
    for (NSUInteger i = 0; i < length; i++, b++) {
        if (theLength > 0 && line >= theLength) {
            [aMutableData appendBytes:"=\n" length:2];
            line = 0;
        }
        
        // RFC says must encode space and tab right before end of line
        if ((*b == ' ' || *b == '\t') && i < length - 1 && b[1] == '\n') {
            buf[1] = hexDigit[(*b)>>4];
            buf[2] = hexDigit[(*b)&15];
            [aMutableData appendBytes:buf length:3];
            line += 3;
        }
        // FIXME: really always pass \n through here?
        else if (!aBOOL &&
                 (*b == '\n' || *b == ' ' || *b == '\t'
                  || (*b >= 33 && *b <= 60)
                  || (*b >= 62 && *b <= 126))) {
                     [aMutableData appendBytes:b length:1];
                     if (*b == '\n') {
                         line = 0;
                     } else {
                         line++;
                     }
                 }
        else if (aBOOL && ((*b >= 'a' && *b <= 'z') || (*b >= 'A' && *b <= 'Z'))) {
            [aMutableData appendBytes:b length:1];
            if (*b == '\n') {
                line = 0;
            } else {
                line++;
            }
        }
        else if (aBOOL && *b == ' ') {
            [aMutableData appendBytes:"_"  length:1];
        }
        else {
            buf[1] = hexDigit[(*b)>>4];
            buf[2] = hexDigit[(*b)&15];
            [aMutableData appendBytes: buf length:3];
            line += 3;
        }
    }
    
    return aMutableData;
}

- (nullable NSData *)decodeQuotedPrintableInHeader:(BOOL)aBOOL
{
    NSUInteger len = self.length;
    if (len < 1) {
        return nil;
    }
    
    const unsigned char *bytes = self.bytes;
    const unsigned char *b = bytes;
    
    unsigned char ch = '\0';
    NSMutableData *result = [NSMutableData dataWithCapacity:len];
    
    for (NSUInteger i = 0; i < len; i++, b++) {
        if (b[0] == '=' && i+1 < len && b[1] == '\n') {
            b++,i++;
            continue;
        } else if (*b == '=' && i+2 < len) {
            b++, i++;
            if (*b >= 'A' && *b <= 'F') {
                ch = 16*(*b-'A'+10);
            } else if (*b >= 'a' && *b <= 'f') {
                ch = 16*(*b-'a'+10);
            } else if (*b>='0' && *b<='9') {
                ch = 16*(*b-'0');
            }
            
            b++, i++;
            
            if (*b >= 'A' && *b <= 'F') {
                ch += *b-'A'+10;
            } else if (*b >= 'a' && *b <= 'f') {
                ch += *b-'a'+10;
            } else if (*b >= '0' && *b <= '9') {
                ch += *b-'0';
            }
            
            [result appendBytes:&ch length:1];
        } else if (aBOOL && *b == '_') {
            ch = 0x20;
            [result appendBytes:&ch length:1];
        } else {
            [result appendBytes:b length:1];
        }
    }
    
    return result.length > 0 ? result : nil;
}

@end


@implementation NSData (TCHelper)

+ (nullable instancetype)dataWithContentsOfAlwaysMappedFile:(NSString *)path error:(NSError **)errorPtr
{
    return [self dataWithContentsOfFile:path options:NSDataReadingUncached|NSDataReadingMappedAlways error:errorPtr];
}

+ (nullable instancetype)dataWithContentsOfAlwaysMappedURL:(NSURL *)url error:(NSError **)errorPtr
{
    return [self dataWithContentsOfURL:url options:NSDataReadingUncached|NSDataReadingMappedAlways error:errorPtr];
}

- (NSRange)rangeOfString:(NSString *)strToFind encoding:(NSStringEncoding)encoding options:(NSDataSearchOptions)mask range:(NSRange * _Nullable)searchRange
{
    NSCParameterAssert(strToFind);
    if (nil == strToFind) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    if (0 == encoding) {
        encoding = NSASCIIStringEncoding;
    }
    
    NSUInteger len = self.length;
    NSData *keyData = [strToFind dataUsingEncoding:encoding];
    if (nil == keyData || len < keyData.length) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSRange range;
    if (NULL != searchRange) {
        if (searchRange->location == NSNotFound) {
            searchRange->location = 0;
        }
        
        if (searchRange->length < 1 || searchRange->length > len) {
            searchRange->length = len;
        }
        
        range = *searchRange;
    } else {
        range.location = 0;
        range.length = len;
    }

    return [self rangeOfData:keyData options:mask range:range];
}

@end

