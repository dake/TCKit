//
//  TCRSA.m
//  TCKit
//
//  Created by dake on 16/5/16.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCRSA.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>


@implementation TCRSA
{
@private
    SecKeyRef _publicKey;
    SecKeyRef _privateKey;
    
    NSString *_pubFile;
    NSString *_privateFile;
    NSString *_passwd;
}


- (void)dealloc
{
    if (NULL != _publicKey) {
        CFRelease(_publicKey);
    }
    
    if (NULL != _privateKey) {
        CFRelease(_privateKey);
    }
}

+ (instancetype)RSAWithPublicFile:(NSString *)derFile
{
    return [self RSAWithPublicFile:derFile privateFile:nil passwd:nil];
}

+ (instancetype)RSAWithPublicFile:(NSString *)derFile privateFile:(NSString *)p12File passwd:(NSString *)passwd
{
    NSCParameterAssert(derFile);
    if (nil == derFile) {
        return nil;
    }
    
    TCRSA *rsa = [[self alloc] init];
    rsa->_pubFile = derFile;
    rsa->_privateFile = p12File;
    rsa->_passwd = passwd;
    
    return rsa;
}


- (SecKeyRef)publicKey
{
    if (NULL == _publicKey && nil != _pubFile) {

        NSData *data = [NSData dataWithContentsOfFile:_pubFile];
        _pubFile = nil;
        
        if (nil != data) {
            SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)data);
            SecPolicyRef policy = SecPolicyCreateBasicX509();
            SecTrustRef trust = NULL;
            OSStatus status = SecTrustCreateWithCertificates(certificate, policy, &trust);
            CFRelease(certificate);
            CFRelease(policy);
            SecTrustResultType reslt = kSecTrustResultInvalid;
            if (noErr == status && noErr == SecTrustEvaluate(trust, &reslt)) {
                _publicKey = SecTrustCopyPublicKey(trust);
            }
            
            if (NULL != trust) {
                CFRelease(trust);
            }
        }
    }
    
    NSCParameterAssert(_publicKey);
    return _publicKey;
}

- (SecKeyRef)privateKey
{
    if (NULL == _privateKey && nil != _privateFile) {
        NSData *data = [NSData dataWithContentsOfFile:_privateFile];
        _privateFile = nil;
        
        if (nil != data) {
            NSDictionary *options = nil;
            if (nil != _passwd) {
                options = @{(__bridge NSString *)kSecImportExportPassphrase: _passwd};
                _passwd = nil;
            } else {
                options = @{};
            }
            CFArrayRef items = CFArrayCreate(kCFAllocatorDefault, 0, 0, NULL);
            OSStatus securityError = SecPKCS12Import((__bridge CFDataRef)data, (__bridge CFDictionaryRef)options, &items);
            if (noErr == securityError && CFArrayGetCount(items) > 0) {
                CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
                SecIdentityRef identityApp = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
                securityError = SecIdentityCopyPrivateKey(identityApp, &_privateKey);
                if (noErr != securityError) {
                    _privateKey = NULL;
                }
            }
            
            if (NULL != items) {
                CFRelease(items);
            }
        }
    }
    
    NSCParameterAssert(_privateKey);
    return _privateKey;
}


/**
 encrypt with public key, decrypt with private key
 */

- (NSData *)encryptData:(NSData *)plainData
{
    NSCParameterAssert(plainData);
    if (nil == plainData) {
        return nil;
    }
    
    SecKeyRef key = self.publicKey;
    NSCParameterAssert(key);
    if (NULL == key) {
        return nil;
    }
    
    size_t cipherBufferSize = SecKeyGetBlockSize(key);
    size_t blockSize = cipherBufferSize - 11;
    size_t blockCount = (size_t)ceil(plainData.length / (double)blockSize);
    if (blockCount < 1) {
        return nil;
    }
    
    uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
    if (NULL == cipherBuffer) {
        return nil;
    }
    
    NSMutableData *encryptedData = [NSMutableData data];
    NSUInteger len = plainData.length;
    
    for (size_t i = 0; i < blockCount; i++) {
        NSData *buffer = [plainData subdataWithRange:NSMakeRange(i * blockSize, MIN(blockSize, len - i * blockSize))];
        size_t cipherTextLe = 0;
        OSStatus status = SecKeyEncrypt(key,
                                        kSecPaddingPKCS1,
                                        (const uint8_t *)buffer.bytes,
                                        buffer.length,
                                        cipherBuffer,
                                        &cipherTextLe);
        
        if (status != noErr) {
            encryptedData = nil;
            break;
        }
        
        NSData *data = [NSData dataWithBytes:(const void *)cipherBuffer length:cipherTextLe];
        if (nil == data) {
            encryptedData = nil;
            break;
        }
        [encryptedData appendData:data];
    }
    
    free(cipherBuffer);
    
    return encryptedData;
}

- (NSData *)decryptData:(NSData *)cypherData
{
    NSCParameterAssert(cypherData);
    if (nil == cypherData) {
        return nil;
    }
    
    SecKeyRef key = self.privateKey;
    NSCParameterAssert(key);
    if (NULL == key) {
        return nil;
    }
    
    size_t cipherBufferSize = SecKeyGetBlockSize(key);
    size_t blockSize = cipherBufferSize;
    size_t blockCount = (size_t)ceil(cypherData.length / (double)blockSize);
    if (blockCount < 1) {
        return nil;
    }
    
    NSMutableData *decryptedData = NSMutableData.data;
    NSUInteger len = cypherData.length;
    
    for (size_t i = 0; i < blockCount; i++) {
        NSData *buffer = [cypherData subdataWithRange:NSMakeRange(i * blockSize, MIN(blockSize , len - i * blockSize))];
        
        size_t plainLen = SecKeyGetBlockSize(key);
        void *plain = malloc(plainLen);
        if (NULL == plain) {
            decryptedData = nil;
            break;
        }
        
        OSStatus status = SecKeyDecrypt(key, kSecPaddingPKCS1, buffer.bytes, buffer.length, plain, &plainLen);
        
        if (status != errSecSuccess) {
            free(plain);
            decryptedData = nil;
            break;
        }
        
        NSData *data = [NSData dataWithBytesNoCopy:plain length:plainLen];
        if (nil == data) {
            free(plain);
            decryptedData = nil;
            break;
        }
        [decryptedData appendData:data];
    }
    
    return decryptedData;
}

- (NSString *)encryptString:(NSString *)plainStr
{
    NSCParameterAssert(plainStr);
    if (nil == plainStr) {
        return nil;
    }
    
    NSData *data = [self encryptData:[plainStr dataUsingEncoding:NSUTF8StringEncoding]];
    return [data base64EncodedStringWithOptions:kNilOptions];
}

- (NSString *)decryptString:(NSString *)cypherStr
{
    NSCParameterAssert(cypherStr);
    if (nil == cypherStr) {
        return nil;
    }
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:cypherStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData *decryptData = [self decryptData:data];
    return nil != decryptData ? [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding] : nil;
}


/**
 sign with private key, verify with public key
 */

- (NSData *)signSHA256Data:(NSData *)plainData
{
    NSCParameterAssert(plainData);
    if (nil == plainData) {
        return nil;
    }
    
    SecKeyRef key = self.privateKey;
    NSCParameterAssert(key);
    if (NULL == key) {
        return nil;
    }
    
    uint8_t hashBytes[CC_SHA256_DIGEST_LENGTH];
    bzero(hashBytes, CC_SHA256_DIGEST_LENGTH);
    if (!CC_SHA256(plainData.bytes, (CC_LONG)plainData.length, hashBytes)) {
        return nil;
    }
    
    size_t signedHashBytesSize = SecKeyGetBlockSize(key);
    uint8_t *signedHashBytes = malloc(signedHashBytesSize);
    if (NULL == signedHashBytes) {
        return nil;
    }
    bzero(signedHashBytes, signedHashBytesSize);
    
    OSStatus status = SecKeyRawSign(key,
                                    kSecPaddingPKCS1SHA256,
                                    hashBytes,
                                    CC_SHA256_DIGEST_LENGTH,
                                    signedHashBytes,
                                    &signedHashBytesSize);
    
    if (status != errSecSuccess) {
        free(signedHashBytes);
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:signedHashBytes length:(NSUInteger)signedHashBytesSize];
    free(signedHashBytes);
    return data;
}

- (BOOL)verifySHA256Data:(NSData *)plainData signData:(NSData *)signData
{
    NSCParameterAssert(plainData);
    NSCParameterAssert(signData);
    if (nil == plainData || nil == signData) {
        return NO;
    }
    
    SecKeyRef key = self.publicKey;
    NSCParameterAssert(key);
    if (NULL == key) {
        return NO;
    }
    
    uint8_t hashBytes[CC_SHA256_DIGEST_LENGTH];
    bzero(hashBytes, CC_SHA256_DIGEST_LENGTH);
    if (!CC_SHA256(plainData.bytes, (CC_LONG)plainData.length, hashBytes)) {
        return NO;
    }
    
    OSStatus status = SecKeyRawVerify(key,
                                      kSecPaddingPKCS1SHA256,
                                      hashBytes,
                                      CC_SHA256_DIGEST_LENGTH,
                                      signData.bytes,
                                      SecKeyGetBlockSize(key));
    
    //  if the signature is not verified because the underlying data has changed, then the status return is -9809.
    return errSecSuccess == status;
}

- (NSString *)signSHA256String:(NSString *)plainStr
{
    NSCParameterAssert(plainStr);
    if (nil == plainStr) {
        return nil;
    }
    
    NSData *signData = [self signSHA256Data:[plainStr dataUsingEncoding:NSUTF8StringEncoding]];
    return [signData base64EncodedStringWithOptions:kNilOptions];
}

- (BOOL)verifySHA256String:(NSString *)plainStr sign:(NSString *)signStr
{
    NSCParameterAssert(plainStr);
    NSCParameterAssert(signStr);
    if (nil == plainStr || nil == signStr) {
        return NO;
    }
    
    NSData *signData = [[NSData alloc] initWithBase64EncodedString:signStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData *plainData = [plainStr dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self verifySHA256Data:plainData signData:signData];
}

@end
