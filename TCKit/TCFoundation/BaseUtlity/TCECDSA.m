//
//  TCECDSA.m
//  TCFoundation
//
//  Created by dake on 2018/1/18.
//  Copyright © 2018年 PixelCyber. All rights reserved.
//

#import "TCECDSA.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>

// https://medium.com/@edisonlo/objective-c-digital-signature-signing-and-verification-with-pem-der-or-base64-string-aff4c0a7f805


@interface TCECDSA ()

@end

@implementation TCECDSA
{
@private
    SecKeyRef _publicKey;
    SecKeyRef _privateKey;
}

+ (SecKeyRef)getPrivateKeyRefrenceFromData:(NSData*)p12Data password:(NSString*)password
{
    SecKeyRef privateKeyRef = NULL;
    NSMutableDictionary * options = NSMutableDictionary.dictionary;
    [options setObject: password forKey:(__bridge id)kSecImportExportPassphrase];
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus securityError = SecPKCS12Import((__bridge CFDataRef) p12Data, (__bridge CFDictionaryRef)options, &items);
    if (securityError == noErr && CFArrayGetCount(items) > 0) {
        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
        SecIdentityRef identityApp = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
        securityError = SecIdentityCopyPrivateKey(identityApp, &privateKeyRef);
        if (securityError != noErr) {
            privateKeyRef = NULL;
        }
    }
    CFRelease(items);
    
    return privateKeyRef;
}

//- (SecKeyRef)getPublicKeyRefrenceFromeData:(NSData*)derData {
//
//    SecCertificateRef myCertificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)derData);
//    SecPolicyRef myPolicy = SecPolicyCreateBasicX509();
//    SecTrustRef myTrust;
//    OSStatus status = SecTrustCreateWithCertificates(myCertificate,myPolicy,&myTrust);
//    SecTrustResultType trustResult;
//    if (status == noErr) {
//        status = SecTrustEvaluate(myTrust, &trustResult);
//    }
//    SecKeyRef securityKey = SecTrustCopyPublicKey(myTrust);
//    CFRelease(myCertificate);
//    CFRelease(myPolicy);
//    CFRelease(myTrust);
//
//    return securityKey;
//}

- (SecKeyRef)privateKey
{
    NSCParameterAssert(_privateKey);
    return _privateKey;
}


+ (nullable NSData *)signData:(NSData *)plainData withPrivateKey:(NSData *)p12Data passwd:(NSString *_Nullable)passwd
{
    NSCParameterAssert(plainData);
    if (nil == plainData) {
        return nil;
    }
    
    SecKeyRef key = [self getPrivateKeyRefrenceFromData:p12Data password:passwd];
    NSCParameterAssert(key);
    if (NULL == key) {
        return nil;
    }
    
    uint8_t hashBytes[CC_SHA256_DIGEST_LENGTH];
    bzero(hashBytes, CC_SHA256_DIGEST_LENGTH);
    if (!CC_SHA256(plainData.bytes, (CC_LONG)plainData.length, hashBytes)) {
        return nil;
    }
    
    size_t signedHashBytesSize = 256;//SecKeyGetBlockSize(key);
    uint8_t *signedHashBytes = malloc(signedHashBytesSize);
    if (NULL == signedHashBytes) {
        return nil;
    }
    bzero(signedHashBytes, signedHashBytesSize);
    
    OSStatus status = SecKeyRawSign(key,
                                    kSecPaddingNone,//kSecPaddingPKCS1, //kSecPaddingPKCS1SHA256 : iOS10, iOS11 有效
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

@end
