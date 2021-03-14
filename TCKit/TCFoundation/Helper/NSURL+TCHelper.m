//
//  NSURL+TCHelper.m
//  TCKit
//
//  Created by dake on 16/8/19.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSURL+TCHelper.h"
#import <CoreServices/UTCoreTypes.h>
#import <CommonCrypto/CommonCrypto.h>
#import <sys/stat.h>

#import "NSString+TCHelper.h"


NSString *TCPercentEscapedStringFromString(NSString *string) {
    NSCharacterSet *allowedCharacterSet = NSCharacterSet.urlComponentAllowedCharacters;
    
    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = NSMutableString.string;
    
    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

NSString *TCPercentEscapedStringFromFileName(NSString *string)
{
    if (string.length < 1) {
        return nil;
    }
    
    NSString *name = [[string componentsSeparatedByCharactersInSet:NSCharacterSet.illegalFileNameCharacters] componentsJoinedByString:@"_"];
    if (name.length > NAME_MAX) {
        name = [name substringFromIndex:name.length - NAME_MAX];
    } else if ([name isEqualToString:@"_"]) {
        return nil;
    }
    return name.length < 1 ? nil : name;
}


#define FileHashDefaultChunkSizeForReadingData (1024 * 8U)

static NSString *tc_file_hash(NSURL *url, void *ctx, int (*fun_init)(void *c), int (*fun_update)(void *c, const void *data, CC_LONG len), int (*fun_final)(unsigned char *md, void *c), size_t digest_len)
{
    if (!url.isFileURL || url.hasDirectoryPath) {
        return nil;
    }
    
    CFReadStreamRef readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)url);
    if (NULL == readStream) {
        return nil;
    }
    if (!CFReadStreamOpen(readStream)) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        return nil;
    }

    if (NULL != fun_init) {
        fun_init(ctx);
    }
    
    bool hasMore = true;
    do {
        uint8_t buffer[FileHashDefaultChunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) {
            break;
        }
        if (readBytesCount == 0) {
            hasMore = false;
            break;
        }
        fun_update(ctx, (const void *)buffer, (CC_LONG)readBytesCount);
        
    } while (hasMore);
    
    CFReadStreamClose(readStream);
    CFRelease(readStream);
    
    if (hasMore) {
        return nil;
    }
    
    unsigned char digest[digest_len];
    fun_final(digest, ctx);
    NSMutableString *str = [NSMutableString stringWithCapacity:sizeof(digest) * 2];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        [str appendFormat:@"%02x", digest[i]];
    }
    return str;
}

static uLong tc_file_crc(NSURL *url, uLong (*fun_init)(uLong crc, const Bytef *buf, uInt len), uLong (*fun_update)(uLong crc, const Bytef *buf, uInt len))
{
    if (!url.isFileURL || url.hasDirectoryPath) {
        return 0UL;
    }
    
    CFReadStreamRef readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)url);
    if (NULL == readStream) {
        return 0UL;
    }
    if (!CFReadStreamOpen(readStream)) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        return 0UL;
    }
    
    uLong crc = fun_init(0L, Z_NULL, 0);
    bool hasMore = true;
    do {
        Bytef buffer[FileHashDefaultChunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) {
            break;
        }
        if (readBytesCount == 0) {
            hasMore = false;
            break;
        }
        crc = fun_update(crc, buffer, (uInt)readBytesCount);
        
    } while (hasMore);
    
    CFReadStreamClose(readStream);
    CFRelease(readStream);
    
    if (hasMore) {
        return 0UL;
    }
    return crc;
}

@implementation NSCharacterSet (TCHelper)

//+ (NSCharacterSet *)chineseAndEngSet
//{
//    static NSCharacterSet *chineseNameSet;
//    if (chineseNameSet == nil)
//    {
//        NSMutableCharacterSet *aCharacterSet = [[NSMutableCharacterSet alloc] init];
//
//        NSRange lcEnglishRange;
//        lcEnglishRange.location = (unsigned int)0x4e00;
//        lcEnglishRange.length = (unsigned int)0x9fa5 - (unsigned int)0x4e00;
//        [aCharacterSet addCharactersInRange:lcEnglishRange];
//        [aCharacterSet addCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
//        chineseNameSet = aCharacterSet;
//    }
//    return chineseNameSet;
//}

+ (NSCharacterSet *)urlComponentAllowedCharacters
{
    static NSString *const kTCCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString *const kTCCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *allowedCharacterSet = NSCharacterSet.URLHostAllowedCharacterSet.mutableCopy;
        [allowedCharacterSet removeCharactersInString:[kTCCharactersGeneralDelimitersToEncode stringByAppendingString:kTCCharactersSubDelimitersToEncode]];
        set = allowedCharacterSet;
    });
    
    return set;
}

+ (NSCharacterSet *)illegalFileNameCharacters
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // https://www.cnblogs.com/Smart_Joe/archive/2013/01/31/2886774.html
        NSMutableCharacterSet *notAllowedCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/\\?*|<>:"]; // @"/\\?%*|\"<>:"
        set = notAllowedCharacterSet;
    });
    
    return set;
}

@end


@implementation NSURL (TCHelper)

- (BOOL)isHttpURL
{
    NSString *const scheme = self.scheme;
    switch (scheme.length) {
        case 4:
            return NSOrderedSame == [scheme compare:@"http" options:NSCaseInsensitiveSearch];
            
        case 5:
            return NSOrderedSame == [scheme compare:@"https" options:NSCaseInsensitiveSearch];
            
        default:
            return NO;
    }
}

- (nullable NSString *)hostport
{
    NSString *const scheme = self.scheme.lowercaseString;
    if (scheme.length < 1) {
        return nil;
    }
    
    NSString *host = self.host;
    if (host.length < 1) {
        return nil;
    }
    NSURLComponents *com = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    if (nil != com) {
        host = com.percentEncodedHost ?: com.host;
    } else {
        bool ipv6 = false;
        if (tc_is_ip_addr(host.UTF8String, &ipv6) && ipv6) {
            host = [NSString stringWithFormat:@"[%@]", host];
        }
    }
        
    int port = (com.port ?: self.port).intValue;
    if (port < 1) {
        if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"wss"]) {
            port = 443;
        } else if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"ws"]) {
            port = 80;
        } else if ([scheme isEqualToString:@"ftp"]) {
            port = 21;
        } else if ([scheme isEqualToString:@"telnet"]) {
            port = 23;
        } else if ([scheme isEqualToString:@"smtp"]) {
            port = 25;
        } else if ([scheme isEqualToString:@"socks"]) {
            port = 1080;
        } else if ([scheme isEqualToString:@"ssh"] || [scheme isEqualToString:@"sftp"]) {
            port = 22;
        }
    }
    if (port < 1) {
        return host;
    }
    
    return [host stringByAppendingFormat:@":%d", port];
}

- (NSURL *)safeURLByResolvingSymlinksInPath
{
    NSURL *url = self.URLByResolvingSymlinksInPath;
    if (nil == url || [url isEqualToFile:self]) {
        return self;
    }
    
    return url;
}

+ (nullable NSURL *)availableURLWithName:(NSString *)name at:(NSURL *)dir
{
    return [self availableURLWithName:name at:dir isDirectory:NO];
}

+ (nullable NSURL *)availableURLWithName:(NSString *)name at:(NSURL *)dir isDirectory:(BOOL)isDir
{
    NSString *fileName = name;
    NSString *ext = nil;
    NSString *rawName = [fileName stringByDeletingFixedPathExtension:&ext];
    NSURL *dst = [dir URLByAppendingPathComponent:fileName isDirectory:isDir];
    int i = 2;
    while (nil != dst && [NSFileManager.defaultManager fileExistsAtPath:dst.path]) {
        if (ext.length > 0) {
            dst = [dir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d.%@", rawName, i++, ext] isDirectory:isDir];
        } else {
            dst = [dir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d", rawName, i++] isDirectory:isDir];
        }
    }
    return dst;
}

- (nullable NSURL *)URLByAppendingPathExtensionMust:(NSString *)str
{
    if (nil == str || str.length < 1) {
        return self;
    }
    
    NSURL *tmp = [self URLByAppendingPathExtension:str];
    if (nil != tmp) {
        return tmp;
    }
    
    NSString *fileName = self.lastPathComponent;
    return [self.URLByDeletingLastPathComponent URLByAppendingPathComponent:[fileName stringByAppendingFormat:@".%@", str]];
}

- (nullable NSString *)fixedFileExtension
{
    return self.absoluteString.fixedFileExtension;
}

- (nullable NSString *)fixedPath
{
    return (self.hasDirectoryPath && self.path.length > 1) ? [self.path stringByAppendingString:@"/"] : self.path;
}

- (BOOL)isEqualToFile:(NSURL *)url
{
    if (url == self || [url isEqual:self]) {
        return YES;
    }
    
    NSURL *right = url.URLByStandardizingPath;
    if ([right isEqual:self]) {
        return YES;
    }
    
    NSURL *left = self.URLByStandardizingPath;
    return [left isEqual:url] || [left isEqual:right];
}

- (nullable NSMutableDictionary<NSString *, NSString *> *)parseQueryToDictionaryWithDecodeInf:(BOOL)decodeInf orderKey:(NSArray<NSString *> **)orderKey
{
    NSString *query = [self.query stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
    return [query explodeToDictionaryInnerGlue:@"=" outterGlue:@"&" orderKey:orderKey decodeInf:decodeInf];
}

- (NSURL *)appendParam:(NSDictionary<NSString *, id> *)param orderKey:(NSArray<NSString *> *)orderKey overwrite:(BOOL)force encodeQuering:(BOOL)encode
{
    if (param.count < 1) {
        return self;
    }
    
    // NSURLComponents auto url encoding, property auto decoding
    NSURLComponents *com = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    
    if (force) {
        NSArray<NSString *> *rawOrder = nil;
        NSMutableDictionary *dic = [self parseQueryToDictionaryWithDecodeInf:NO orderKey:&rawOrder];
        if (nil == dic) {
            dic = NSMutableDictionary.dictionary;
        }
        [dic addEntriesFromDictionary:param];
        NSMutableArray<NSString *> *order = NSMutableArray.array;
        if (nil == orderKey) {
            orderKey = param.allKeys;
        }
        if (rawOrder.count > 0 && orderKey.count > 0) {
            [order filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", orderKey]];
        }
        if (nil != orderKey) {
            [order addObjectsFromArray:orderKey];
        }
        
        NSMutableString *query = NSMutableString.string;
        for (NSString *key in order) {
            NSString *value = TCPercentEscapedStringFromString([NSString stringWithFormat:@"%@", dic[key]]);
            if (encode) {
                value = TCPercentEscapedStringFromString(value);
            }
            [query appendFormat:(query.length > 0 ? @"&%@" : @"%@"), [TCPercentEscapedStringFromString(key) stringByAppendingFormat:@"=%@", value]];
        }
        com.percentEncodedQuery = query;
    } else {
        NSMutableString *query = NSMutableString.string;
        NSString *rawQuery = com.percentEncodedQuery;
        if (rawQuery.length > 0) {
            [query appendString:rawQuery];
        }
        if (nil == orderKey) {
            orderKey = param.allKeys;
        }
        
        for (NSString *key in orderKey) {
            if (nil == com.percentEncodedQuery || [com.percentEncodedQuery rangeOfString:key].location == NSNotFound) {
                NSString *value = TCPercentEscapedStringFromString([NSString stringWithFormat:@"%@", param[key]]);
                if (encode) {
                    value = TCPercentEscapedStringFromString(value);
                }
                [query appendFormat:(query.length > 0 ? @"&%@" : @"%@"), [TCPercentEscapedStringFromString(key) stringByAppendingFormat:@"=%@", value]];
            } else {
                NSCAssert(false, @"conflict query param");
            }
        }
        com.percentEncodedQuery = query;
    }
    
    return com.URL ?: self;
}

- (NSURL *)appendParamIfNeed:(NSDictionary<NSString *, id> *)param orderKey:(NSArray<NSString *> *_Nullable)orderKey
{
    return [self appendParam:param orderKey:orderKey overwrite:NO encodeQuering:NO];
}

- (unsigned long long)contentSizeInByte
{
    if (!self.isFileURL) {
        return 0;
    }
    
    unsigned long long size = 0;
    NSURL *url = self;
    NSArray<NSString *> *subPath = [NSFileManager.defaultManager contentsOfDirectoryAtPath:url.path error:NULL];
    if (subPath.count > 0) {
        for (NSString *fileName in subPath) {
            @autoreleasepool {
                size += [url URLByAppendingPathComponent:fileName].contentSizeInByte;
            }
        }
        return size;
    }
    
    struct stat statbuf;
    if (stat(url.fileSystemRepresentation, &statbuf) == 0) {
        size = (unsigned long long)statbuf.st_size;
    } else {
        size = [NSFileManager.defaultManager attributesOfItemAtPath:url.path error:NULL].fileSize;
    }
    
    return size;
}


#pragma mark -

// http://siruoxian.iteye.com/blog/2013601
// http://www.cnblogs.com/visen-0/p/3160907.html


- (unsigned long)fileCRC32
{
    return tc_file_crc(self, tc_crc32_formula_reflect, tc_crc32_formula_reflect);
}

- (nullable NSString *)fileCRC32String
{
    uLong c = tc_file_crc(self, tc_crc32_formula_reflect, tc_crc32_formula_reflect);
    if (0UL == c) {
        return nil;
    }
    return [NSString stringWithFormat:@"%08lx", c];
}

- (unsigned long)fileCRC32B
{
    return tc_file_crc(self, crc32, crc32);
}

- (nullable NSString *)fileCRC32BString
{
    uLong c = tc_file_crc(self, crc32, crc32);
    if (0UL == c) {
        return nil;
    }
    return [NSString stringWithFormat:@"%08lx", c];
}

- (unsigned long)fileAdler32
{
    return tc_file_crc(self, adler32, adler32);
}

- (nullable NSString *)fileAdler32String
{
    uLong c = tc_file_crc(self, adler32, adler32);
    if (0UL == c) {
        return nil;
    }
    return [NSString stringWithFormat:@"%08lx", c];
}

- (nullable NSString *)fileSHA:(NSUInteger)digestLen
{
    switch (digestLen) {
        case CC_SHA1_DIGEST_LENGTH: {
            CC_SHA1_CTX hash;
            return tc_file_hash(self, &hash, (int (*)(void *))CC_SHA1_Init,  (int (*)(void *, const void *, CC_LONG))CC_SHA1_Update, (int (*)(unsigned char *, void *))CC_SHA1_Final, digestLen);
        }
            
        case CC_SHA256_DIGEST_LENGTH: {
            CC_SHA256_CTX hash;
            return tc_file_hash(self, &hash, (int (*)(void *))CC_SHA256_Init,  (int (*)(void *, const void *, CC_LONG))CC_SHA256_Update, (int (*)(unsigned char *, void *))CC_SHA256_Final, digestLen);
        }
            
        case CC_SHA224_DIGEST_LENGTH: {
            CC_SHA256_CTX hash;
            return tc_file_hash(self, &hash, (int (*)(void *))CC_SHA224_Init,  (int (*)(void *, const void *, CC_LONG))CC_SHA224_Update, (int (*)(unsigned char *, void *))CC_SHA224_Final, digestLen);
        }
            
        case CC_SHA384_DIGEST_LENGTH: {
            CC_SHA512_CTX hash;
            return tc_file_hash(self, &hash, (int (*)(void *))CC_SHA384_Init,  (int (*)(void *, const void *, CC_LONG))CC_SHA384_Update, (int (*)(unsigned char *, void *))CC_SHA384_Final, digestLen);
        }
            
        case CC_SHA512_DIGEST_LENGTH: {
            CC_SHA512_CTX hash;
            return tc_file_hash(self, &hash, (int (*)(void *))CC_SHA512_Init,  (int (*)(void *, const void *, CC_LONG))CC_SHA512_Update, (int (*)(unsigned char *, void *))CC_SHA512_Final, digestLen);
        }
            
        default:
            return nil;
    }
}

static int tc_CCHmacFinal(unsigned char *md, void *c)
{
    CCHmacFinal(c, md);
    return 1;
}

static int tc_CCHmacUpdate(void *c, const void *data, CC_LONG len)
{
    CCHmacUpdate(c, data, len);
    return 1;
}

- (nullable NSString *)fileHmac:(CCHmacAlgorithm)alg key:(nullable NSData *)key
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
    
    CCHmacContext hash;
    CCHmacInit(&hash, alg, key.bytes, key.length);
    return tc_file_hash(self, &hash, NULL,  (int (*)(void *, const void *, CC_LONG))tc_CCHmacUpdate, (int (*)(unsigned char *, void *))tc_CCHmacFinal, digestLen);
}

- (nullable NSString *)fileMD5_32
{
    CC_MD5_CTX hash;
    return tc_file_hash(self, &hash, (int (*)(void *))CC_MD5_Init,  (int (*)(void *, const void *, CC_LONG))CC_MD5_Update, (int (*)(unsigned char *, void *))CC_MD5_Final, CC_MD5_DIGEST_LENGTH);
}

- (nullable NSString *)fileMD2
{
    CC_MD2_CTX hash;
    return tc_file_hash(self, &hash, (int (*)(void *))CC_MD2_Init,  (int (*)(void *, const void *, CC_LONG))CC_MD2_Update, (int (*)(unsigned char *, void *))CC_MD2_Final, CC_MD2_DIGEST_LENGTH);
}

- (nullable NSString *)fileMD4
{
    CC_MD4_CTX hash;
    return tc_file_hash(self, &hash, (int (*)(void *))CC_MD4_Init,  (int (*)(void *, const void *, CC_LONG))CC_MD4_Update, (int (*)(unsigned char *, void *))CC_MD4_Final, CC_MD4_DIGEST_LENGTH);
}

- (void)tc_fileMD5:(NSString *_Nullable *_Nullable)md5 sha256:(NSString *_Nullable *_Nullable)sha256
{
    if (!self.isFileURL || self.hasDirectoryPath || (NULL == md5 && NULL == sha256)) {
        return;
    }
    
    NSURL *url = self;
    CFReadStreamRef readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)url);
    if (NULL == readStream) {
        return;
    }
    if (!CFReadStreamOpen(readStream)) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        return;
    }
    
    BOOL calcMD5 = NULL != md5;
    BOOL calcSHA256 = NULL != sha256;
    CC_MD5_CTX md5Hash;
    CC_SHA256_CTX sha256Hash;
    if (calcMD5) {
        CC_MD5_Init(&md5Hash);
    }
    if (calcSHA256) {
        CC_SHA256_Init(&sha256Hash);
    }
    
    bool hasMore = true;
    do {
        uint8_t buffer[FileHashDefaultChunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) {
            break;
        }
        if (readBytesCount == 0) {
            hasMore = false;
            break;
        }
        if (calcMD5) {
            CC_MD5_Update(&md5Hash, (const void *)buffer, (CC_LONG)readBytesCount);
        }
        if (calcSHA256) {
            CC_SHA256_Update(&sha256Hash, (const void *)buffer, (CC_LONG)readBytesCount);
        }
        
    } while (hasMore);
    
    CFReadStreamClose(readStream);
    CFRelease(readStream);
    
    if (hasMore) {
        return;
    }
    
    if (calcMD5) {
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &md5Hash);
        NSMutableString *str = [NSMutableString stringWithCapacity:sizeof(digest) * 2];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            [str appendFormat:@"%02x", digest[i]];
        }
        *md5 = str;
    }
    
    if (calcSHA256) {
        unsigned char digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(digest, &sha256Hash);
        NSMutableString *str = [NSMutableString stringWithCapacity:sizeof(digest) * 2];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            [str appendFormat:@"%02x", digest[i]];
        }
        *sha256 = str;
    }
}

@end


@implementation NSFileManager (TCHelper)

- (BOOL)linkCopyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError **)error
{
    NSError *err = nil;
    BOOL suc = [self linkItemAtURL:srcURL toURL:dstURL error:&err];
    if (suc) {
        return YES;
    }
    
    if (NULL != error) {
        *error = err;
    }
    if (err.code == NSFileWriteFileExistsError && [err.domain isEqualToString:NSCocoaErrorDomain]) {
        return NO;
    }
    
    // !!!: may create an empty directory
    if (![srcURL isEqualToFile:dstURL]) {
        [self removeItemAtURL:dstURL error:NULL];
    }
    suc = [self copyItemAtURL:srcURL toURL:dstURL error:error];
    if (suc) {
        if (NULL != error) {
            *error = nil;
        }
        NSDictionary<NSFileAttributeKey, id> *attributes = [self attributesOfItemAtPath:srcURL.path error:NULL];
        if (attributes.count > 0) {
            [self setAttributes:attributes ofItemAtPath:dstURL.path error:NULL];
        }
    }
    return suc;
}

- (BOOL)moveItemMustAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError **)error
{
    NSError *err = nil;
    if ([self moveItemAtURL:srcURL toURL:dstURL error:&err]) {
        return YES;
    }
    
    if (nil != err) {
        if (NULL != error) {
            *error = err;
        }
        if (err.code == NSFileWriteFileExistsError && [err.domain isEqualToString:NSCocoaErrorDomain]) {
            return NO;
        }
    } else if ([NSFileManager.defaultManager fileExistsAtPath:dstURL.path]) {
        if (NULL != error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
        }
        return NO;
    }
    
    if (0 == rename(srcURL.fileSystemRepresentation, dstURL.fileSystemRepresentation)) {
        return YES;
    }
    
    BOOL suc = [self linkCopyItemAtURL:srcURL toURL:dstURL error:NULL];
    if (suc) {
        if ([self removeItemAtURL:srcURL error:NULL] || 0 == remove(srcURL.fileSystemRepresentation)) {
            if (NULL != error) {
                *error = nil;
            }
        } else {
            suc = NO;
            if (![self removeItemAtURL:dstURL error:NULL]) {
                remove(dstURL.fileSystemRepresentation);
            }
        }
    }
    
    return suc;
}

@end



@implementation UIPasteboard (TCHelper)

- (BOOL)setFile:(id<NSSecureCoding>)item suggestedName:(NSString *_Nullable)suggestedName uti:(NSString *_Nullable  *_Nullable)uti
{
    NSCParameterAssert(item);
    if (nil == item) {
        return NO;
    }
    
    BOOL const isURL = [(NSObject *)item isKindOfClass:NSURL.class];
    NSString *utiMust = nil;
    if (NULL == uti || (*uti).length < 1) {
        if (isURL) {
            utiMust = ((NSURL *)item).isFileURL ? (__bridge NSString *)kUTTypeFileURL : (__bridge NSString *)kUTTypeURL;
        } else {
            utiMust = (__bridge NSString *)kUTTypeData;
        }
        *uti = utiMust;
    } else {
        utiMust = *uti;
    }

    if (@available(iOS 11, *)) {
        NSItemProvider *fileProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:utiMust];
        fileProvider.suggestedName = TCPercentEscapedStringFromFileName(suggestedName) ?: (isURL ? ((NSURL *)item).lastPathComponent : nil);
        [self setItemProviders:@[fileProvider] localOnly:YES expirationDate:[NSDate dateWithMinutesFromNow:10]];
    } else {
        NSData *data = nil;
        if ([(NSObject *)item isKindOfClass:NSData.class]) {
            data = (typeof(data))item;
        } else if (isURL) {
            data = [NSData dataWithContentsOfAlwaysMappedURL:(NSURL *)item error:NULL];
        }
        
        if (nil == data) {
            return NO;
        }
        [self setData:data forPasteboardType:utiMust];
    }
    return YES;
}

- (nullable NSURL *)fileForName:(NSString *_Nullable)suggestedName uti:(NSString *_Nullable)uti
{
    // TODO: 取出以后的 item 从 pasteboard 清空
    if (@available(iOS 11, *)) {
        NSMutableArray<NSItemProvider *> *items = [NSMutableArray arrayWithArray:self.itemProviders ?: @[]];
        NSItemProvider *fileProvider = items.pullObject;
        if (nil == fileProvider) {
            return nil;
        }
        if (nil == fileProvider.suggestedName && nil != suggestedName) {
            fileProvider.suggestedName = TCPercentEscapedStringFromFileName(suggestedName);
        }
    
        __block NSURL *fileURL = nil;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        tc_dispatch_global_async_bg(^{
            @autoreleasepool {
                [fileProvider loadFileRepresentationForTypeIdentifier:uti.length > 0 ? uti : fileProvider.registeredTypeIdentifiers.firstObject completionHandler:^(NSURL * _Nullable item, NSError * _Nullable error) {
                    if (nil != item && [NSFileManager.defaultManager isReadableFileAtPath:item.path]) {
                        NSURL *dirURL = [NSObject defaultTmpDirectoryInDomain:@"tc_pasteboard_shared" create:YES];
                        if (nil != dirURL) {
                            NSURL *tmpURL = [NSURL availableURLWithName:item.lastPathComponent at:dirURL];
                            if (nil != tmpURL && [NSFileManager.defaultManager linkCopyItemAtURL:item toURL:tmpURL error:NULL]) {
                                fileURL = tmpURL;
                            }
                        }
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            }
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (nil != fileURL) {
            // 必须取完数据后才能置空，且置空后，取出的文件被销毁
            self.itemProviders = items;
            return fileURL;
        }
    }
    
    NSString *utiStr = uti.length > 0 ? uti : self.pasteboardTypes.firstObject;
    NSData *data = [self dataForPasteboardType:utiStr];
    if (nil == data) {
        return nil;
    }
    
    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray arrayWithArray:self.items ?: @[]];
    NSDictionary<NSString *, id> *item = nil;
    for (NSDictionary<NSString *, id> *tmp in items) {
        if (nil != tmp[utiStr]) {
            item = tmp;
            break;
        }
    }
    NSCParameterAssert(item);
    if (nil != item) {
        [items removeObjectIdenticalTo:item];
    }
    self.items = items;

    NSURL *dirURL = [NSObject defaultTmpDirectoryInDomain:@"tc_pasteboard_shared" create:YES];
    if (nil == dirURL) {
        return nil;
    }

    NSURL *tmpURL = [NSURL availableURLWithName:suggestedName ?: NSUUID.UUID.UUIDString at:dirURL];
    if (nil != tmpURL && [data writeToURL:tmpURL atomically:YES]) {
        return tmpURL;
    }
    return nil;
}

@end


@implementation TCURL : NSURL

- (void)dealloc
{
    if (self.autoDelete && self.isFileURL) {
        [NSFileManager.defaultManager removeItemAtURL:self error:NULL];
    }
}

+ (instancetype)URLWithNSURL:(NSURL *)url
{
    NSCParameterAssert(url);
    if (url.isFileURL) {
        return (TCURL *)[self fileURLWithPath:url.path isDirectory:url.hasDirectoryPath];
    }
    return (TCURL *)[self URLWithString:url.absoluteString];
}

@end
