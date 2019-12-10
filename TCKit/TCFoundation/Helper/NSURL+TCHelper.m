//
//  NSURL+TCHelper.m
//  TCKit
//
//  Created by dake on 16/8/19.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSURL+TCHelper.h"
#import "NSString+TCHelper.h"
#import <CommonCrypto/CommonCrypto.h>
#import <sys/stat.h>

NSString * TCPercentEscapedStringFromString(NSString *string) {
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

NSString * TCPercentEscapedStringFromFileName(NSString *string)
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
        NSMutableCharacterSet *notAllowedCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:"];
        set = notAllowedCharacterSet;
    });
    
    return set;
}

@end


@implementation NSURL (TCHelper)

- (NSURL *)safeURLByResolvingSymlinksInPath
{
    NSURL *url = self.URLByResolvingSymlinksInPath;
    if (nil == url || [url isEqual:self]) {
        return self;
    }
    
    return url;
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
    
    NSURL *url = self.safeURLByResolvingSymlinksInPath;
    NSArray<NSString *> *subPath = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:url.path error:NULL];
    if (subPath.count > 0) {
        unsigned long long size = 0;
        for (NSString *fileName in subPath) {
            size += [url URLByAppendingPathComponent:fileName].contentSizeInByte;
        }
        return size;
    }
    
    unsigned long long fileSize = 0;
    struct stat statbuf;
    if (stat(url.fileSystemRepresentation, &statbuf) == 0) {
        fileSize = (unsigned long long)statbuf.st_size;
    } else {
        fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:url.path error:NULL].fileSize;
    }
    
    return fileSize;
}


#pragma mark -

// http://siruoxian.iteye.com/blog/2013601
// http://www.cnblogs.com/visen-0/p/3160907.html

#define FileHashDefaultChunkSizeForReadingData 1024*8
static CFStringRef FileMD5HashCreateWithPath(CFURLRef fileURL,
                                             size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (chunkSizeForReadingData < 1) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
                                       (const char *)hash,
                                       kCFStringEncodingUTF8);
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    return result;
}

- (NSString *)tc_fileMD5
{
    if (!self.isFileURL || self.hasDirectoryPath) {
        return nil;
    }
    NSURL *url = self.safeURLByResolvingSymlinksInPath;
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFURLRef)url, FileHashDefaultChunkSizeForReadingData);
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
    if (![srcURL.standardizedURL isEqual:dstURL.standardizedURL]) {
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
    
    if (NULL != error) {
        *error = err;
    }
    if (err.code == NSFileWriteFileExistsError && [err.domain isEqualToString:NSCocoaErrorDomain]) {
        return NO;
    }
    
    BOOL suc = [self linkCopyItemAtURL:srcURL toURL:dstURL error:NULL];
    if (suc) {
        if ([self removeItemAtURL:srcURL error:NULL]) {
            if (NULL != error) {
                *error = nil;
            }
        } else {
            suc = NO;
            [self removeItemAtURL:dstURL error:NULL];
        }
    }
    
    return suc;
}



@end
