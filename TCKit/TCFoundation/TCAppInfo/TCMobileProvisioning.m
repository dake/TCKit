//
//  TCMobileProvisioning.m
//  TCKit
//
//  Created by dake on 16/2/23.
//  Copyright © 2016年 dake. All rights reserved.
//

#if !TARGET_OS_SIMULATOR && \
(defined(__TCKit__) && !defined(TC_IOS_PUBLISH)) || (!defined(__TCKit__) && defined(DEBUG))


#import "TCMobileProvisioning.h"
#import "NSObject+TCMapping.h"


#define MobileProvisioningAppIDName @"AppIDName"
#define MobileProvisioningApplicationIdentifierPrefix @"ApplicationIdentifierPrefix"
#define MobileProvisioningCreationDate @"CreationDate"
#define MobileProvisioningKeychainAccessGroups @"keychain-access-groups"
#define MobileProvisioningExpirationDate @"ExpirationDate"
#define MobileProvisioningName @"Name"
#define MobileProvisioningProvisionedDevices @"ProvisionedDevices"
#define MobileProvisioningTeamName @"TeamName"
#define MobileProvisioningGetTaskAllow @"get-task-allow"
#define MobileProvisioningApsEnvironment @"aps-environment"


@implementation TCMobileProvisioning

+ (NSDictionary *)tc_propertyNameMapping
{
    return @{@"apsEnvironment": MobileProvisioningApsEnvironment,
             @"developProvisioning": MobileProvisioningGetTaskAllow,
             @"keychainAccessGroups": MobileProvisioningKeychainAccessGroups};
}

+ (NSDictionary *)tc_propertyTypeFormat
{
    return @{@"CreationDate": @"yyyy-MM-dd'T'HH:mm:ssZ",
             @"ExpirationDate": @"yyyy-MM-dd'T'HH:mm:ssZ"};
}


- (TCMobileProvisionningPushConfiguration)pushConfiguration
{
    if ([_apsEnvironment isEqualToString:@"development"]) {
        return kTCMobileProvisionningPushConfigurationDevelopment;
    } else if ([_apsEnvironment isEqualToString:@"production"]) {
        return kTCMobileProvisionningPushConfigurationProduction;
    }
    
    return kTCMobileProvisionningPushConfigurationDisable;
}


#pragma mark -

+ (instancetype)defaultMobileProvisioning
{
    return [self tc_mappingWithDictionary:self.dictionaryWithDefaultMobileProvisioning];
}


+ (NSDictionary *)dictionaryWithDefaultMobileProvisioning
{
    // There is no provisioning profile in AppStore Apps or simulator Apps
    NSString *profilePath = [NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"];
    
    // Check provisioning profile existence
    if (nil != profilePath) {
        // Get hex representation
        NSData *profileData = [NSData dataWithContentsOfFile:profilePath];
        NSString *profileString = [NSString stringWithFormat:@"%@", profileData];
        
        // Remove brackets at beginning and end
        profileString = [profileString stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        profileString = [profileString stringByReplacingCharactersInRange:NSMakeRange(profileString.length - 1, 1) withString:@""];
        
        // Remove spaces
        profileString = [profileString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        // Convert hex values to readable characters
        NSMutableString *profileText = NSMutableString.string;
        for (NSUInteger i = 0; i < profileString.length; i += 2) {
            NSString *hexChar = [profileString substringWithRange:NSMakeRange(i, 2)];
            int value = 0;
            sscanf([hexChar cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
            [profileText appendFormat:@"%c", (char)value];
        }
        
        NSRange range1 = [profileText rangeOfString:@"<?xml"];
        if (range1.location != NSNotFound) {
            NSRange range2 = [profileText rangeOfString:@"</plist>"];
            if (range2.location != NSNotFound) {
                NSRange range = NSMakeRange(range1.location, range2.location + range2.length - range1.location);
                NSString *result = [profileText substringWithRange:range];
                return [self dictionaryWithMobileProvisioningString:result];
            }
        }
    }
    
    return nil;
}

+ (NSDictionary *)dictionaryWithMobileProvisioningString:(NSString *)rawMobileProvisionning
{
    NSMutableDictionary *dictionary = NSMutableDictionary.dictionary;
    NSArray *lines = [rawMobileProvisionning componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSUInteger i = 0; i < lines.count; ++i) {
        NSString *line = lines[i];
        if ([self lineString:line containsKey:MobileProvisioningAppIDName]) {
            NSString *nextLine = lines[i+1];
            NSString *appIDName = [self extractStringValueInLine:nextLine];
            if (appIDName.length > 0) {
                dictionary[MobileProvisioningAppIDName] = appIDName;
                continue;
            }
        }
        
        if ([self lineString:line containsKey:MobileProvisioningApplicationIdentifierPrefix]) {
            NSString *nextLine = lines[i+1];
            NSMutableArray *arryOfApplicationIdentifierPrefix = NSMutableArray.array;
            while ([nextLine rangeOfString:@"</array>"].location == NSNotFound) {
                NSString *value = [self extractStringValueInLine:nextLine];
                if (value.length > 0) {
                    [arryOfApplicationIdentifierPrefix addObject:value];
                }
                ++i;
                nextLine = lines[i];
            }
            
            dictionary[MobileProvisioningApplicationIdentifierPrefix] = arryOfApplicationIdentifierPrefix;
        }
        
        if ([self lineString:line containsKey:MobileProvisioningCreationDate]) {
            NSString *nextLine = lines[i+1];
            NSString *creationDate = [self extractDateValueInLine:nextLine];
            if (nil != creationDate) {
                dictionary[MobileProvisioningCreationDate] = creationDate;
                continue;
            }
        }
        
        if ([self lineString:line containsKey:MobileProvisioningExpirationDate]) {
            NSString *nextLine = lines[i+1];
            NSString *creationDate = [self extractDateValueInLine:nextLine];
            if (nil != creationDate) {
                dictionary[MobileProvisioningExpirationDate] = creationDate;
                continue;
            }
        }
        
        if ([self lineString:line containsKey:MobileProvisioningName]) {
            NSString *nextLine = lines[i+1];
            NSString *name = [self extractStringValueInLine:nextLine];
            if (nil != name) {
                dictionary[MobileProvisioningName] = name;
                continue;
            }
        }
        
        if ([self lineString:line containsKey:MobileProvisioningKeychainAccessGroups]) {
            NSString *nextLine = lines[i+1];
            NSMutableArray *arryOfProvisionedDevices = NSMutableArray.array;
            while ([nextLine rangeOfString:@"</array>"].location == NSNotFound) {
                NSString *value = [self extractStringValueInLine:nextLine];
                if (value.length > 0) {
                    [arryOfProvisionedDevices addObject:value];
                }
                
                ++i;
                nextLine = lines[i];
            }
            
            dictionary[MobileProvisioningKeychainAccessGroups] = arryOfProvisionedDevices;
            continue;
        }
        
        if ([self lineString:line containsKey:MobileProvisioningProvisionedDevices]) {
            NSString *nextLine = lines[i+1];
            NSMutableArray *arryOfProvisionedDevices = NSMutableArray.array;
            while ([nextLine rangeOfString:@"</array>"].location == NSNotFound) {
                NSString *value = [self extractStringValueInLine:nextLine];
                if (value.length > 0) {
                    [arryOfProvisionedDevices addObject:value];
                }
                
                ++i;
                nextLine = lines[i];
            }
            
            dictionary[MobileProvisioningProvisionedDevices] = arryOfProvisionedDevices;
            continue;
        }
        
        if ([self lineString:line containsKey:MobileProvisioningTeamName]) {
            NSString *nextLine = lines[i+1];
            NSString *creationDate = [self extractStringValueInLine:nextLine];
            if (nil != creationDate) {
                dictionary[MobileProvisioningTeamName] = creationDate;
                continue;
            }
        }
        
        if ([self lineString:line containsKey:MobileProvisioningGetTaskAllow]) {
            NSString *nextLine = lines[i+1];
            NSString *isDevMobileProvisioning = [self extractBoolValueInLine:nextLine];
            if (nil != isDevMobileProvisioning) {
                dictionary[MobileProvisioningGetTaskAllow] = isDevMobileProvisioning;
                continue;
            }
        }
        
        if ([self lineString:line containsKey:MobileProvisioningApsEnvironment]) {
            NSString *nextLine = lines[i+1];
            NSString *apsEnv = [self extractStringValueInLine:nextLine];
            if (nil != apsEnv) {
                dictionary[MobileProvisioningApsEnvironment] = apsEnv;
                continue;
            }
        }
    }
    
    return dictionary;
}


+ (BOOL)lineString:(NSString *)line containsKey:(NSString *)key
{
    return [line rangeOfString:[NSString stringWithFormat:@"<key>%@</key>", key]].location != NSNotFound;
}

+ (NSString *)extractStringValueInLine:(NSString *)line
{
    NSRange rangeStart = [line rangeOfString:@"<string>"];
    NSRange rangeEnd = [line rangeOfString:@"</string>"];
    if (rangeStart.location != NSNotFound && rangeEnd.location != NSNotFound) {
        return [line substringWithRange:NSMakeRange(rangeStart.location+rangeStart.length, rangeEnd.location - (rangeStart.location+rangeStart.length))];
    }
    
    return @"";
}

+ (NSString *)extractDateValueInLine:(NSString *)line
{
    NSRange rangeStart = [line rangeOfString:@"<date>"];
    NSRange rangeEnd = [line rangeOfString:@"</date>"];
    if (rangeStart.location != NSNotFound && rangeEnd.location != NSNotFound) {
        return [line substringWithRange:NSMakeRange(rangeStart.location+rangeStart.length, rangeEnd.location - (rangeStart.location+rangeStart.length))];
    }
    
    return @"";
}

+ (NSString *)extractBoolValueInLine:(NSString *)line
{
    NSRange rangeTrue = [line rangeOfString:@"true"];
    if (rangeTrue.location != NSNotFound) {
        return @"true";
    }
    
    return @"false";
}

@end

#endif
