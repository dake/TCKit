//
//  NSObject+TCCoding.h
//  TCKit
//
//  Created by dake on 16/3/11.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMappingOption.h"


@protocol TCCodingIgnore; // unavailable for `Class`


NS_ASSUME_NONNULL_BEGIN

@interface NSObject (TCCoding) <TCMappingOption>

/**
 @brief JSONMapping
 
 UIImage -> base64 string
 UIColor -> "#1234FEA8" ARGB
 NSData -> base64 string
 NSDate -> "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
 NSURL -> string
 NSAttributedString -> string
 SEL -> string
 
 */
- (nullable id/*NSArray or NSDictionary*/)tc_JSONObject;
- (nullable NSData *)tc_JSONData;
- (nullable NSData *)tc_JSONData:(NSJSONWritingOptions)opt;
- (nullable NSString *)tc_JSONString;
- (nullable NSString *)tc_JSONString:(NSJSONWritingOptions)opt;
- (BOOL)tc_writeJSONToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;

- (nullable id/*NSArray or NSDictionary*/)tc_JSONObjectWithOption:(TCMappingOption * __nullable)option;

#pragma mark - TCPlistMapping

/**
 @brief PlistMapping

 NSPropertyListSerialization, NSCoding: NSData, NSString, NSArray, NSDictionary, NSDate, NSNumber.
 key for NSDictionary must be NSString
 
 UIImage -> data
 UIColor -> "#1234FEA8" ARGB
 NSURL -> string
 NSAttributedString -> string
 SEL -> string
 
 return NSData, NSString, NSArray, NSDictionary, NSDate, NSNumber

 */
- (nullable id)tc_plistObject;

@end


@interface NSString (TCJSONMapping)

- (nullable id)tc_JSONObject;

@end


@interface NSData (TCJSONMapping)

- (nullable id)tc_JSONObject;

@end

NS_ASSUME_NONNULL_END
