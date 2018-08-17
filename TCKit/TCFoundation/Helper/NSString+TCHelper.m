//
//  NSString+TCHelper.m
//  TCKit
//
//  Created by dake on 16/2/18.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "NSString+TCHelper.h"

#include <netinet/in.h>
#include <arpa/inet.h>

#import <UIKit/UIKit.h>

@interface NSAttributedString (HTML)

+ (instancetype)attributedStringWithHTMLString:(NSString *)htmlString;

@end


@implementation NSString (TCHelper)

- (NSString *)reversedString
{
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:self.length];
    
    [self enumerateSubstringsInRange:NSMakeRange(0,self.length)
                             options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                              [reversedString appendString:substring];
                          }];
    return reversedString;
}

- (NSMutableDictionary *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue decodeInf:(BOOL)decodeInf
{
    // Explode based on outter glue
    NSArray<NSString *> *firstExplode = [self componentsSeparatedByString:outterGlue];
    if (firstExplode.count < 2 && [self componentsSeparatedByString:innerGlue].count < 2) {
        NSString *str = self.stringByRemovingPercentEncoding;
        if (nil != str) {
            firstExplode = [str componentsSeparatedByString:outterGlue];
        }
    }
    
    // Explode based on inner glue
    NSMutableDictionary *returnDictionary = NSMutableDictionary.dictionary;
    for (NSUInteger i = 0; i < firstExplode.count; ++i) {
        NSArray<NSString *> *secondExplode = [firstExplode[i] componentsSeparatedByString:innerGlue];
        if (secondExplode.count >= 2) {
            NSString *key = secondExplode[0].stringByRemovingPercentEncoding;
            if (nil == key) {
                continue;
            }
            
            NSString *value = nil;
            if (secondExplode.count == 2) {
                value = secondExplode[1];
            } else {
                value = [firstExplode[i] substringFromIndex:secondExplode[0].length + 1];
            }
            NSString *str = value.stringByRemovingPercentEncoding;
            while (decodeInf && nil != str) {
                @autoreleasepool {
                    NSString *tmp = str.stringByRemovingPercentEncoding;
                    if (nil == tmp || [tmp isEqualToString:str]) {
                        break;
                    }
                    str = tmp;
                }
            }
            if (nil != str) {
                value = str;
            }
            if (nil == value) {
                continue;
            }
            
            returnDictionary[key] = value;
        }
    }
    
    return returnDictionary;
}

- (NSString *)stringByAppendingPathExtensionMust:(NSString *)str
{
    if (nil == str || str.length < 1) {
        return self;
    }
    
    NSString *tmp = [self stringByAppendingPathExtension:str];
    if (nil != tmp) {
        return tmp;
    }
    
    return [self stringByAppendingFormat:@".%@", str];
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
        if (nil == url) {
            NSString *tmp = [decodeUrl stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
            if (nil != tmp) {
                url = [NSURL URLWithString:tmp];
            }
        }
        
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
    NSUInteger begin = [ext rangeOfString:@"."].location;
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
        NSUInteger loc = [ext rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]].location;
        if (loc != NSNotFound) {
            ext = [ext substringFromIndex:loc+1];
        } else {
            return nil;
        }
    }
    
    NSUInteger lastDot = [ext rangeOfString:@"." options:NSBackwardsSearch].location;
    if (lastDot == NSNotFound) {
        lastDot = 0;
    }
    NSUInteger loc = [ext rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"&,;(=?"] options:0 range:NSMakeRange(lastDot, ext.length - lastDot)].location;
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
    if (self.length < 1) {
        return NO;
    }
    NSString *str = [self stringByTrimmingCharactersInSet:NSCharacterSet.decimalDigitCharacterSet];
    return str.length < 1 || [str isEqualToString:@"."];
}

- (BOOL)isInteger
{
    if (self.length < 1) {
        return NO;
    }
    NSString *str = [self stringByTrimmingCharactersInSet:NSCharacterSet.decimalDigitCharacterSet];
    return str.length < 1;
}

- (BOOL)isPureAlphabet
{
    if (self.length < 1) {
        return NO;
    }
    NSString *str = [self stringByTrimmingCharactersInSet:NSCharacterSet.letterCharacterSet];
    return str.length < 1;
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
                for (NSUInteger i = 0; i < sizeof(s_validateCode)/sizeof(s_validateCode[0]); ++i) {
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


bool tc_is_ip_addr(char const *host, bool *ipv6)
{
    if (NULL == host) {
        return false;
    }
    struct sockaddr_in sin;
    bzero(&sin, sizeof(sin));
    if (1 == inet_pton(AF_INET, host, &sin)) {
        return true;
    }
    
    struct sockaddr_in6 sin6;
    bzero(&sin6, sizeof(sin6));
    
    bool ret = 1 == inet_pton(AF_INET6, host, &sin6);
    if (NULL != ipv6) {
        *ipv6 = ret;
    }
    return ret;
}

- (BOOL)isIPAddress
{
    return tc_is_ip_addr(self.UTF8String, NULL);
}

#pragma mark - 

+ (NSStringEncoding)encodingForIANACharset:(NSString *)iana
{
    NSStringEncoding encoding = kCFStringEncodingInvalidId;
    if (nil == iana) {
        return encoding;
    }
    
    CFStringEncoding cfcoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)iana);
    if (kCFStringEncodingInvalidId != cfcoding) {
        encoding = CFStringConvertEncodingToNSStringEncoding(cfcoding);
    }
    
    return encoding;
}

+ (nullable NSString *)IANACharsetForEncoding:(NSStringEncoding)encoding
{
    if (kCFStringEncodingInvalidId == encoding) {
        return nil;
    }
    
    CFStringEncoding cfcoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    if (kCFStringEncodingInvalidId == cfcoding) {
        return nil;
    }
    
    CFStringRef cStr = CFStringConvertEncodingToIANACharSetName(cfcoding);
    return NULL == cStr ? nil : (__bridge NSString *)cStr;
}

+ (nullable instancetype)stringWithData:(NSData *)data usedEncoding:(nullable NSStringEncoding *)enc
{
    if (nil == data) {
        return nil;
    }
    
    static NSMutableArray<NSNumber *> *s_tryEncodings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_tryEncodings = [NSMutableArray arrayWithArray:@[
                                                          @(NSUTF8StringEncoding),
                                                          
                                                          @(NSJapaneseEUCStringEncoding),
                                                          @(NSShiftJISStringEncoding),
                                                          ]];
        
        static CFStringEncoding const kEds[] = {kCFStringEncodingBig5_HKSCS_1999, kCFStringEncodingBig5, kCFStringEncodingHZ_GB_2312, kCFStringEncodingGB_18030_2000};
        
        for (NSUInteger i = 0; i < sizeof(kEds)/sizeof(kEds[0]); ++i) {
            NSStringEncoding ed = (NSStringEncoding)CFStringConvertEncodingToNSStringEncoding(kEds[i]);
            if (kCFStringEncodingInvalidId != ed) {
                [s_tryEncodings insertObject:@(ed) atIndex:1];
            }
        }
    });
    
    NSString *text = nil;
    for (NSNumber *ed in s_tryEncodings) {
        text = [[self alloc] initWithData:data encoding:ed.unsignedIntegerValue];// [NSString stringWithContentsOfURL:self.URL usedEncoding:NULL error:NULL];
        if (nil != text) {
            if (NULL != enc) {
                *enc = ed.unsignedIntegerValue;
            }
            break;
        }
    }
    
    return text;
}

- (NSString *)replaceUnicode
{
    if (self.length < 6) {
        return self;
    }
    if ([self rangeOfString:@"\\u" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        return self;
    }
    
    NSString *returnStr = nil;
    @autoreleasepool {
        NSData *data = nil;
        @autoreleasepool {
            NSMutableString *str = self.mutableCopy;
            [str replaceOccurrencesOfString:@"\\u" withString:@"\\U" options:kNilOptions range:NSMakeRange(0, str.length)];
            [str replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:kNilOptions range:NSMakeRange(0, str.length)];
            [str insertString:@"\"" atIndex:0];
            [str appendString:@"\""];
            data = [str dataUsingEncoding:NSUTF8StringEncoding];
        }
        returnStr = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:NULL];
    }
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}


// MARK: HTML

typedef struct {
    __unsafe_unretained NSString *escapeSequence;
    unichar uchar;
} HTMLEscapeMap;

// Taken from http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
// Ordered by uchar lowest to highest for bsearching
static HTMLEscapeMap gAsciiHTMLEscapeMap[] = {
    // A.2.2. Special characters
    { @"&quot;", 34 },
    { @"&amp;", 38 },
    { @"&apos;", 39 },
    { @"&lt;", 60 },
    { @"&gt;", 62 },
    
    // A.2.1. Latin-1 characters
    { @"&nbsp;", 160 },
    { @"&iexcl;", 161 },
    { @"&cent;", 162 },
    { @"&pound;", 163 },
    { @"&curren;", 164 },
    { @"&yen;", 165 },
    { @"&brvbar;", 166 },
    { @"&sect;", 167 },
    { @"&uml;", 168 },
    { @"&copy;", 169 },
    { @"&ordf;", 170 },
    { @"&laquo;", 171 },
    { @"&not;", 172 },
    { @"&shy;", 173 },
    { @"&reg;", 174 },
    { @"&macr;", 175 },
    { @"&deg;", 176 },
    { @"&plusmn;", 177 },
    { @"&sup2;", 178 },
    { @"&sup3;", 179 },
    { @"&acute;", 180 },
    { @"&micro;", 181 },
    { @"&para;", 182 },
    { @"&middot;", 183 },
    { @"&cedil;", 184 },
    { @"&sup1;", 185 },
    { @"&ordm;", 186 },
    { @"&raquo;", 187 },
    { @"&frac14;", 188 },
    { @"&frac12;", 189 },
    { @"&frac34;", 190 },
    { @"&iquest;", 191 },
    { @"&Agrave;", 192 },
    { @"&Aacute;", 193 },
    { @"&Acirc;", 194 },
    { @"&Atilde;", 195 },
    { @"&Auml;", 196 },
    { @"&Aring;", 197 },
    { @"&AElig;", 198 },
    { @"&Ccedil;", 199 },
    { @"&Egrave;", 200 },
    { @"&Eacute;", 201 },
    { @"&Ecirc;", 202 },
    { @"&Euml;", 203 },
    { @"&Igrave;", 204 },
    { @"&Iacute;", 205 },
    { @"&Icirc;", 206 },
    { @"&Iuml;", 207 },
    { @"&ETH;", 208 },
    { @"&Ntilde;", 209 },
    { @"&Ograve;", 210 },
    { @"&Oacute;", 211 },
    { @"&Ocirc;", 212 },
    { @"&Otilde;", 213 },
    { @"&Ouml;", 214 },
    { @"&times;", 215 },
    { @"&Oslash;", 216 },
    { @"&Ugrave;", 217 },
    { @"&Uacute;", 218 },
    { @"&Ucirc;", 219 },
    { @"&Uuml;", 220 },
    { @"&Yacute;", 221 },
    { @"&THORN;", 222 },
    { @"&szlig;", 223 },
    { @"&agrave;", 224 },
    { @"&aacute;", 225 },
    { @"&acirc;", 226 },
    { @"&atilde;", 227 },
    { @"&auml;", 228 },
    { @"&aring;", 229 },
    { @"&aelig;", 230 },
    { @"&ccedil;", 231 },
    { @"&egrave;", 232 },
    { @"&eacute;", 233 },
    { @"&ecirc;", 234 },
    { @"&euml;", 235 },
    { @"&igrave;", 236 },
    { @"&iacute;", 237 },
    { @"&icirc;", 238 },
    { @"&iuml;", 239 },
    { @"&eth;", 240 },
    { @"&ntilde;", 241 },
    { @"&ograve;", 242 },
    { @"&oacute;", 243 },
    { @"&ocirc;", 244 },
    { @"&otilde;", 245 },
    { @"&ouml;", 246 },
    { @"&divide;", 247 },
    { @"&oslash;", 248 },
    { @"&ugrave;", 249 },
    { @"&uacute;", 250 },
    { @"&ucirc;", 251 },
    { @"&uuml;", 252 },
    { @"&yacute;", 253 },
    { @"&thorn;", 254 },
    { @"&yuml;", 255 },
    
    // A.2.2. Special characters cont'd
    { @"&OElig;", 338 },
    { @"&oelig;", 339 },
    { @"&Scaron;", 352 },
    { @"&scaron;", 353 },
    { @"&Yuml;", 376 },
    
    // A.2.3. Symbols
    { @"&fnof;", 402 },
    
    // A.2.2. Special characters cont'd
    { @"&circ;", 710 },
    { @"&tilde;", 732 },
    
    // A.2.3. Symbols cont'd
    { @"&Alpha;", 913 },
    { @"&Beta;", 914 },
    { @"&Gamma;", 915 },
    { @"&Delta;", 916 },
    { @"&Epsilon;", 917 },
    { @"&Zeta;", 918 },
    { @"&Eta;", 919 },
    { @"&Theta;", 920 },
    { @"&Iota;", 921 },
    { @"&Kappa;", 922 },
    { @"&Lambda;", 923 },
    { @"&Mu;", 924 },
    { @"&Nu;", 925 },
    { @"&Xi;", 926 },
    { @"&Omicron;", 927 },
    { @"&Pi;", 928 },
    { @"&Rho;", 929 },
    { @"&Sigma;", 931 },
    { @"&Tau;", 932 },
    { @"&Upsilon;", 933 },
    { @"&Phi;", 934 },
    { @"&Chi;", 935 },
    { @"&Psi;", 936 },
    { @"&Omega;", 937 },
    { @"&alpha;", 945 },
    { @"&beta;", 946 },
    { @"&gamma;", 947 },
    { @"&delta;", 948 },
    { @"&epsilon;", 949 },
    { @"&zeta;", 950 },
    { @"&eta;", 951 },
    { @"&theta;", 952 },
    { @"&iota;", 953 },
    { @"&kappa;", 954 },
    { @"&lambda;", 955 },
    { @"&mu;", 956 },
    { @"&nu;", 957 },
    { @"&xi;", 958 },
    { @"&omicron;", 959 },
    { @"&pi;", 960 },
    { @"&rho;", 961 },
    { @"&sigmaf;", 962 },
    { @"&sigma;", 963 },
    { @"&tau;", 964 },
    { @"&upsilon;", 965 },
    { @"&phi;", 966 },
    { @"&chi;", 967 },
    { @"&psi;", 968 },
    { @"&omega;", 969 },
    { @"&thetasym;", 977 },
    { @"&upsih;", 978 },
    { @"&piv;", 982 },
    
    // A.2.2. Special characters cont'd
    { @"&ensp;", 8194 },
    { @"&emsp;", 8195 },
    { @"&thinsp;", 8201 },
    { @"&zwnj;", 8204 },
    { @"&zwj;", 8205 },
    { @"&lrm;", 8206 },
    { @"&rlm;", 8207 },
    { @"&ndash;", 8211 },
    { @"&mdash;", 8212 },
    { @"&lsquo;", 8216 },
    { @"&rsquo;", 8217 },
    { @"&sbquo;", 8218 },
    { @"&ldquo;", 8220 },
    { @"&rdquo;", 8221 },
    { @"&bdquo;", 8222 },
    { @"&dagger;", 8224 },
    { @"&Dagger;", 8225 },
    // A.2.3. Symbols cont'd
    { @"&bull;", 8226 },
    { @"&hellip;", 8230 },
    
    // A.2.2. Special characters cont'd
    { @"&permil;", 8240 },
    
    // A.2.3. Symbols cont'd
    { @"&prime;", 8242 },
    { @"&Prime;", 8243 },
    
    // A.2.2. Special characters cont'd
    { @"&lsaquo;", 8249 },
    { @"&rsaquo;", 8250 },
    
    // A.2.3. Symbols cont'd
    { @"&oline;", 8254 },
    { @"&frasl;", 8260 },
    
    // A.2.2. Special characters cont'd
    { @"&euro;", 8364 },
    
    // A.2.3. Symbols cont'd
    { @"&image;", 8465 },
    { @"&weierp;", 8472 },
    { @"&real;", 8476 },
    { @"&trade;", 8482 },
    { @"&alefsym;", 8501 },
    { @"&larr;", 8592 },
    { @"&uarr;", 8593 },
    { @"&rarr;", 8594 },
    { @"&darr;", 8595 },
    { @"&harr;", 8596 },
    { @"&crarr;", 8629 },
    { @"&lArr;", 8656 },
    { @"&uArr;", 8657 },
    { @"&rArr;", 8658 },
    { @"&dArr;", 8659 },
    { @"&hArr;", 8660 },
    { @"&forall;", 8704 },
    { @"&part;", 8706 },
    { @"&exist;", 8707 },
    { @"&empty;", 8709 },
    { @"&nabla;", 8711 },
    { @"&isin;", 8712 },
    { @"&notin;", 8713 },
    { @"&ni;", 8715 },
    { @"&prod;", 8719 },
    { @"&sum;", 8721 },
    { @"&minus;", 8722 },
    { @"&lowast;", 8727 },
    { @"&radic;", 8730 },
    { @"&prop;", 8733 },
    { @"&infin;", 8734 },
    { @"&ang;", 8736 },
    { @"&and;", 8743 },
    { @"&or;", 8744 },
    { @"&cap;", 8745 },
    { @"&cup;", 8746 },
    { @"&int;", 8747 },
    { @"&there4;", 8756 },
    { @"&sim;", 8764 },
    { @"&cong;", 8773 },
    { @"&asymp;", 8776 },
    { @"&ne;", 8800 },
    { @"&equiv;", 8801 },
    { @"&le;", 8804 },
    { @"&ge;", 8805 },
    { @"&sub;", 8834 },
    { @"&sup;", 8835 },
    { @"&nsub;", 8836 },
    { @"&sube;", 8838 },
    { @"&supe;", 8839 },
    { @"&oplus;", 8853 },
    { @"&otimes;", 8855 },
    { @"&perp;", 8869 },
    { @"&sdot;", 8901 },
    { @"&lceil;", 8968 },
    { @"&rceil;", 8969 },
    { @"&lfloor;", 8970 },
    { @"&rfloor;", 8971 },
    { @"&lang;", 9001 },
    { @"&rang;", 9002 },
    { @"&loz;", 9674 },
    { @"&spades;", 9824 },
    { @"&clubs;", 9827 },
    { @"&hearts;", 9829 },
    { @"&diams;", 9830 }
};

// Taken from http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
// This is table A.2.2 Special Characters
static HTMLEscapeMap gUnicodeHTMLEscapeMap[] = {
    // C0 Controls and Basic Latin
    { @"&quot;", 34 },
    { @"&amp;", 38 },
    { @"&apos;", 39 },
    { @"&lt;", 60 },
    { @"&gt;", 62 },
    
    // Latin Extended-A
    { @"&OElig;", 338 },
    { @"&oelig;", 339 },
    { @"&Scaron;", 352 },
    { @"&scaron;", 353 },
    { @"&Yuml;", 376 },
    
    // Spacing Modifier Letters
    { @"&circ;", 710 },
    { @"&tilde;", 732 },
    
    // General Punctuation
    { @"&ensp;", 8194 },
    { @"&emsp;", 8195 },
    { @"&thinsp;", 8201 },
    { @"&zwnj;", 8204 },
    { @"&zwj;", 8205 },
    { @"&lrm;", 8206 },
    { @"&rlm;", 8207 },
    { @"&ndash;", 8211 },
    { @"&mdash;", 8212 },
    { @"&lsquo;", 8216 },
    { @"&rsquo;", 8217 },
    { @"&sbquo;", 8218 },
    { @"&ldquo;", 8220 },
    { @"&rdquo;", 8221 },
    { @"&bdquo;", 8222 },
    { @"&dagger;", 8224 },
    { @"&Dagger;", 8225 },
    { @"&permil;", 8240 },
    { @"&lsaquo;", 8249 },
    { @"&rsaquo;", 8250 },
    { @"&euro;", 8364 },
};


// Utility function for Bsearching table above
static int EscapeMapCompare(const void *ucharVoid, const void *mapVoid) {
    const unichar *uchar = (const unichar*)ucharVoid;
    const HTMLEscapeMap *map = (const HTMLEscapeMap*)mapVoid;
    int val;
    if (*uchar > map->uchar) {
        val = 1;
    } else if (*uchar < map->uchar) {
        val = -1;
    } else {
        val = 0;
    }
    return val;
}

- (NSString *)tc_stringByEscapingHTMLUsingTable:(HTMLEscapeMap*)table
                                         ofSize:(NSUInteger)size
                                escapingUnicode:(BOOL)escapeUnicode {
    NSUInteger length = self.length;
    if (length < 1) {
        return self;
    }
    
    NSMutableString *finalString = NSMutableString.string;
    NSMutableData *data2 = [NSMutableData dataWithCapacity:sizeof(unichar) * length];
    
    // this block is common between GTMNSString+HTML and GTMNSString+XML but
    // it's so short that it isn't really worth trying to share.
    const unichar *buffer = CFStringGetCharactersPtr((CFStringRef)self);
    if (!buffer) {
        // We want this buffer to be autoreleased.
        NSMutableData *data = [NSMutableData dataWithLength:length * sizeof(UniChar)];
        if (!data) {
            return nil;
        }
        [self getCharacters:data.mutableBytes];
        buffer = data.bytes;
    }
    
    if (NULL == buffer || nil == data2) {
        return nil;
    }
    
    unichar *buffer2 = (unichar *)[data2 mutableBytes];
    
    CFIndex buffer2Length = 0;
    for (NSUInteger i = 0; i < length; ++i) {
        HTMLEscapeMap *val = bsearch(&buffer[i], table,
                                     size / sizeof(HTMLEscapeMap),
                                     sizeof(HTMLEscapeMap), EscapeMapCompare);
        if (val || (escapeUnicode && buffer[i] > 127)) {
            if (buffer2Length > 0) {
                CFStringAppendCharacters((CFMutableStringRef)finalString,
                                         buffer2,
                                         buffer2Length);
                buffer2Length = 0;
            }
            if (val) {
                [finalString appendString:val->escapeSequence];
            }
            else {
                [finalString appendFormat:@"&#%d;", buffer[i]];
            }
        } else {
            buffer2[buffer2Length] = buffer[i];
            buffer2Length += 1;
        }
    }
    if (buffer2Length > 0) {
        CFStringAppendCharacters((CFMutableStringRef)finalString,
                                 buffer2,
                                 buffer2Length);
    }
    return finalString;
}

- (NSString *)stringByEscapingForHTML
{
    return [self tc_stringByEscapingHTMLUsingTable:gUnicodeHTMLEscapeMap
                                            ofSize:sizeof(gUnicodeHTMLEscapeMap)
                                   escapingUnicode:NO];
}

- (NSString *)stringByEscapingForAsciiHTML
{
    return [self tc_stringByEscapingHTMLUsingTable:gAsciiHTMLEscapeMap
                                            ofSize:sizeof(gAsciiHTMLEscapeMap)
                                   escapingUnicode:YES];
}

- (NSString *)stringByUnescapingHTML
{
    NSRange range = NSMakeRange(0, self.length);
    NSRange subrange = [self rangeOfString:@"&" options:NSBackwardsSearch range:range];

    // if no ampersands, we've got a quick way out
    if (subrange.length == 0) return self;
    NSMutableString *finalString = [NSMutableString stringWithString:self];
    do {
        NSRange semiColonRange = NSMakeRange(subrange.location, NSMaxRange(range) - subrange.location);
        semiColonRange = [self rangeOfString:@";" options:0 range:semiColonRange];
        range = NSMakeRange(0, subrange.location);
        // if we don't find a semicolon in the range, we don't have a sequence
        if (semiColonRange.location == NSNotFound) {
            continue;
        }
        NSRange escapeRange = NSMakeRange(subrange.location, semiColonRange.location - subrange.location + 1);
        NSString *escapeString = [self substringWithRange:escapeRange];
        NSUInteger length = [escapeString length];
        // a squence must be longer than 3 (&lt;) and less than 11 (&thetasym;)
        if (length > 3 && length < 11) {
            if ([escapeString characterAtIndex:1] == '#') {
                unichar char2 = [escapeString characterAtIndex:2];
                if (char2 == 'x' || char2 == 'X') {
                    // Hex escape squences &#xa3;
                    NSString *hexSequence = [escapeString substringWithRange:NSMakeRange(3, length - 4)];
                    NSScanner *scanner = [NSScanner scannerWithString:hexSequence];
                    unsigned value;
                    if ([scanner scanHexInt:&value] &&
                        value < USHRT_MAX &&
                        value > 0
                        && [scanner scanLocation] == length - 4) {
                        unichar uchar = (unichar)value;
                        NSString *charString = [NSString stringWithCharacters:&uchar length:1];
                        [finalString replaceCharactersInRange:escapeRange withString:charString];
                    }

                } else {
                    // Decimal Sequences &#123;
                    NSString *numberSequence = [escapeString substringWithRange:NSMakeRange(2, length - 3)];
                    NSScanner *scanner = [NSScanner scannerWithString:numberSequence];
                    int value;
                    if ([scanner scanInt:&value] &&
                        value < USHRT_MAX &&
                        value > 0
                        && [scanner scanLocation] == length - 3) {
                        unichar uchar = (unichar)value;
                        NSString *charString = [NSString stringWithCharacters:&uchar length:1];
                        [finalString replaceCharactersInRange:escapeRange withString:charString];
                    }
                }
            } else {
                // "standard" sequences
                for (unsigned i = 0; i < sizeof(gAsciiHTMLEscapeMap) / sizeof(HTMLEscapeMap); ++i) {
                    if ([escapeString isEqualToString:gAsciiHTMLEscapeMap[i].escapeSequence]) {
                        [finalString replaceCharactersInRange:escapeRange withString:[NSString stringWithCharacters:&gAsciiHTMLEscapeMap[i].uchar length:1]];
                        break;
                    }
                }
            }
        }
    } while ((subrange = [self rangeOfString:@"&" options:NSBackwardsSearch range:range]).length != 0);
    return finalString;
}

@end
