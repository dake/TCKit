//
//  NSString+TCHelper.m
//  TCKit
//
//  Created by dake on 16/2/18.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSString+TCHelper.h"
#import <UIKit/UIApplication.h>

@implementation NSString (TCHelper)

#ifndef TARGET_IS_EXTENSION

- (void)phoneCall:(void(^)(BOOL success))complete
{
    BOOL ret = self.length > 1;
    if (ret) {
        NSURL *phoneNumber = [NSURL URLWithString:[@"telprompt://" stringByAppendingString:self]];
        ret = [UIApplication.sharedApplication canOpenURL:phoneNumber];
        if (ret) {
            [UIApplication.sharedApplication openURL:phoneNumber options:@{} completionHandler:complete];
        }
    }
}

#endif

- (NSMutableDictionary *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue
{
    NSString *str = self.stringByRemovingPercentEncoding;
    if (nil == str) {
        str = self;
    }
    // Explode based on outter glue
    NSArray<NSString *> *firstExplode = [str componentsSeparatedByString:outterGlue];
    
    // Explode based on inner glue
    NSMutableDictionary *returnDictionary = NSMutableDictionary.dictionary;
    for (NSInteger i = 0; i < firstExplode.count; ++i) {
        NSArray<NSString *> *secondExplode = [firstExplode[i] componentsSeparatedByString:innerGlue];
        if (secondExplode.count >= 2) {
            NSString *key = secondExplode[0].stringByRemovingPercentEncoding;
            if (nil == key) {
                continue;
            }
            
            NSString *value = nil;
            if (secondExplode.count == 2) {
                value = secondExplode[1];
                NSString *str = value.stringByRemovingPercentEncoding;
                if (nil != str) {
                    value = str;
                }
            } else {
                value = [firstExplode[i] substringFromIndex:secondExplode[0].length];
                NSString *str = value.stringByRemovingPercentEncoding;
                if (nil != str) {
                    value = str;
                }
            }
            if (nil == value) {
                continue;
            }
            
            returnDictionary[key] = value;
        }
    }
    
    return returnDictionary;
}

- (nullable NSString *)fixedFileExtension
{
    NSString *decodeUrl = self.stringByRemovingPercentEncoding;
    if (nil == decodeUrl) {
        decodeUrl = self;
    }
    
    NSString *ext = nil;
    if ([decodeUrl hasPrefix:@"http"]) {
        NSURL *url = [NSURL URLWithString:decodeUrl];
        if (url.path.length < 1) {
            if (url.query.length < 1) {
                return nil;
            }
        } else {
            ext = url.path;
        }
    } else {
        ext = decodeUrl.lastPathComponent;
    }
    
    // xx.tar.gz
    NSInteger begin = [ext rangeOfString:@"."].location;
    BOOL findeDot = nil != ext && begin != NSNotFound;
    if (findeDot) {
        ext = [ext substringFromIndex:begin + 1];
    } else {
        begin = [decodeUrl rangeOfString:@"?"].location;
        if (begin == NSNotFound) {
            return nil;
        } else {
            ext = [decodeUrl substringFromIndex:begin + 1];
        }
    }

    if (!findeDot) {
        // /Img/?img=1472541690-6672-2065-1.jpg&img_size=, self.pathExtension 为空
        NSInteger loc = [ext rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]].location;
        if (loc != NSNotFound) {
            ext = [ext substringFromIndex:loc+1];
        } else {
            return nil;
        }
    } 

    NSInteger loc = [ext rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"&,;(=?"]].location;
    if (loc != NSNotFound) {
        ext = [ext substringToIndex:loc];
    }
    
    if ([ext isEqualToString:@"."]) {
        return nil;
    }
    
    NSArray<NSString *> *exts = [ext componentsSeparatedByString:@"."];
    if (exts.count > 2) {
        exts = [exts subarrayWithRange:NSMakeRange(exts.count - 2, 2)];
        if ([exts.firstObject isEqualToString:@"tar"]/*exts.firstObject.isPureAlphabet*/) {
            ext = [exts componentsJoinedByString:@"."];
        } else {
            ext = exts.lastObject;
        }
    } else if (exts.count == 2) {
        if (exts[0].length < 1) {
            ext = exts[1];
        } else if (exts[1].length < 1) {
            ext = exts[0];
        } else if (![exts.firstObject isEqualToString:@"tar"]/*!exts[0].isPureAlphabet*/) {
            ext = exts[1];
        }
    }
    
    loc = [ext rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"&,;!#"]].location;
    if (loc != NSNotFound) {
        ext = [ext substringToIndex:loc];
    }
    
    if (NSNotFound != [ext rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/%"]].location) {
        return nil;
    }
    
    if (ext.isInteger && ![ext isEqualToString:@"323"]) { // text/h323
        return nil;
    }
    
    return ext.length < 1 ? nil : ext;
}


#pragma mark - pattern

- (NSString *)firstCharacter
{
    return self.length > 0 ? [self substringToIndex:1] : @"";
}

- (NSString *)clearSymbolAndWhiteString
{
    NSMutableCharacterSet *trimSet = [[NSMutableCharacterSet alloc] init];
    [trimSet formUnionWithCharacterSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    [trimSet formUnionWithCharacterSet:NSCharacterSet.punctuationCharacterSet];
    [trimSet formUnionWithCharacterSet:NSCharacterSet.controlCharacterSet];
    [trimSet formUnionWithCharacterSet:NSCharacterSet.symbolCharacterSet];
    
    // 去掉前后空格、换行符、标点等
    NSString *trimText = [self stringByTrimmingCharactersInSet:trimSet];
    // 去掉中间的空格
    trimText = [trimText stringByReplacingOccurrencesOfString:@"\x20" withString:@""];
    // 去掉中间的全角空格
    trimText = [trimText stringByReplacingOccurrencesOfString:@"　" withString:@""];
    
    return trimText;
}

- (BOOL)isPureNumber
{
    NSString *string = [self stringByTrimmingCharactersInSet:NSCharacterSet.decimalDigitCharacterSet];
    return string.length < 1 || [string isEqualToString:@"."];
}

- (BOOL)isInteger
{
    NSString *string = [self stringByTrimmingCharactersInSet:NSCharacterSet.decimalDigitCharacterSet];
    return string.length < 1;
}

- (BOOL)isPureAlphabet
{
    NSString *string = [self stringByTrimmingCharactersInSet:NSCharacterSet.letterCharacterSet];
    return string.length < 1;
}

- (BOOL)isValidIDCardNumberOfChina
{
    NSString *code = [self stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSUInteger length = code.length;
    if (length != 15 && length != 18) {
        return NO;
    }
    
    NSString *pureNumber = nil;
    if (length == 15) {
        pureNumber = code;
    } else {
        pureNumber = [code substringToIndex:length-1];
        NSString *last = [code substringFromIndex:length-1].lowercaseString;
        if (![last isEqualToString:@"x"] && !last.isPureNumber) {
            return NO;
        }
    }
    
    if (!pureNumber.isPureNumber) {
        return NO;
    }
    
    // 地区合法性
    NSArray *const areaCodes = @[@"11", @"12", @"13",@"14", @"15",
                                 @"21", @"22", @"23",
                                 @"31", @"32", @"33", @"34", @"35", @"36", @"37",
                                 @"41", @"42", @"43", @"44", @"45", @"46",
                                 @"50", @"51", @"52", @"53", @"54",
                                 @"61", @"62", @"63", @"64", @"65",
                                 @"71",
                                 @"81", @"82",
                                 @"91"];
    
    NSString *area = [code substringToIndex:2];
    if (![areaCodes containsObject:area]) {
        return NO;
    }
    
    // 出生日期合法性
    static NSString *const kLeapYearExp = @"^((01|03|05|07|08|10|12)(0[1-9]|[1-2][0-9]|3[0-1])|(04|06|09|11)(0[1-9]|[1-2][0-9]|30)|02(0[1-9]|[1-2][0-9]))$";
    static NSString *const kCommonYearExp = @"^((01|03|05|07|08|10|12)(0[1-9]|[1-2][0-9]|3[0-1])|(04|06|09|11)(0[1-9]|[1-2][0-9]|30)|02(0[1-9]|1[0-9]|2[0-8]))$";
    
    switch (length) {
        case 15: {
            NSInteger year = [code substringWithRange:NSMakeRange(6, 2)].integerValue + 1900;
            if (year <= 1850 || year >= 2200) {
                return NO;
            }
            BOOL isLeapYear = year%400 == 0 || (year%100 != 0 && year%4 == 0);
            NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:isLeapYear ? kLeapYearExp : kCommonYearExp
                                                                                 options:NSRegularExpressionCaseInsensitive
                                                                                   error:NULL];
            NSUInteger numberofMatch = [exp numberOfMatchesInString:code
                                                            options:NSMatchingReportProgress
                                                              range:NSMakeRange(8, 4)];
            
            return numberofMatch > 0;
        }
            
        case 18: {
            NSInteger year = [code substringWithRange:NSMakeRange(6, 4)].integerValue;
            if (year <= 1850 || year >= 2200) {
                return NO;
            }
            BOOL isLeapYear = year%400 == 0 || (year%100 != 0 && year%4 == 0);
            NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:isLeapYear ? kLeapYearExp : kCommonYearExp
                                                                                 options:NSRegularExpressionCaseInsensitive
                                                                                   error:NULL];
            NSUInteger numberofMatch = [exp numberOfMatchesInString:code
                                                            options:NSMatchingReportProgress
                                                              range:NSMakeRange(10, 4)];
            
            if (numberofMatch > 0) {
                static NSInteger s_validateCode[] = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
                static NSInteger s_digits[] = {1, 0, 10, 9, 8, 7, 6, 5, 4, 3, 2};
                
                NSInteger sum = 0;
                for (NSInteger i = 0; i < sizeof(s_validateCode)/sizeof(s_validateCode[0]); ++i) {
                    sum += s_validateCode[i] * [code substringWithRange:NSMakeRange(i, 1)].integerValue;
                }
                
                NSString *last = [code substringFromIndex:length-1];
                if ([last.lowercaseString isEqualToString:@"x"]) {
                    last = @"10";
                }
                
                return s_digits[sum % 11] == last.integerValue;
                
            } else {
                return NO;
            }
        }
            
        default:
            break;
    }
    
    return NO;
}


@end
