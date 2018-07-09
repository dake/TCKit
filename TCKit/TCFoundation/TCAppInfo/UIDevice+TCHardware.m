/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

/** Thanks to
https://github.com/Ekhoo/Device/
 https://github.com/lmirosevic/GBDeviceInfo
 */

#import "UIDevice+TCHardware.h"

#import <sys/socket.h> // Per msqr
#import <sys/sysctl.h>
#import <net/if_dl.h>
#import <mach/mach.h>

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <netdb.h>

#include <sys/param.h>
#include <sys/mount.h>
#import <netinet/in.h>
//#import "route.h"      /*the very same from google-code*/
#include <resolv.h>
#include <dns.h>


#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>


static NSString *s_device_names[kTCDeviceCount] = {

    [kTCDeviceUnknown] = @"Unknown iOS device",
    
    // iPhone
    [kTCDevice1GiPhone] = @"iPhone 1G",
    [kTCDevice3GiPhone] = @"iPhone 3G",
    [kTCDevice3GSiPhone] = @"iPhone 3GS",
    [kTCDevice4iPhone] = @"iPhone 4",
    [kTCDevice4SiPhone] = @"iPhone 4S",
    [kTCDevice5iPhone] = @"iPhone 5",
    [kTCDevice5CiPhone] = @"iPhone 5C",
    [kTCDevice5SiPhone] = @"iPhone 5S",
    [kTCDevice6iPhone] = @"iPhone 6",
    [kTCDevice6PlusiPhone] = @"iPhone 6 Plus",
    [kTCDeviceSEiPhone] = @"iPhone SE",
    [kTCDevice6SiPhone] = @"iPhone 6S",
    [kTCDevice6SPlusiPhone] = @"iPhone 6S Plus",
    
    [kTCDevice7iPhone] = @"iPhone 7",
    [kTCDevice7PlusiPhone] = @"iPhone 7 Plus",
    
    [kTCDevice8iPhone] = @"iPhone 8",
    [kTCDevice8PlusiPhone] = @"iPhone 8 Plus",
    [kTCDeviceXiPhone] = @"iPhone X",
    
    [kTCDeviceUnknowniPhone] = @"Unknown iPhone",
    
    // iPod
    [kTCDevice1GiPod] = @"iPod touch 1G",
    [kTCDevice2GiPod] = @"iPod touch 2G",
    [kTCDevice3GiPod] = @"iPod touch 3G",
    [kTCDevice4GiPod] = @"iPod touch 4G",
    [kTCDevice5GiPod] = @"iPod touch 5G",
    [kTCDevice6GiPod] = @"iPod touch 6G",
    [kTCDeviceUnknowniPod] = @"Unknown iPod",
    
    // iPad
    [kTCDevice1GiPad] = @"iPad 1G",
    [kTCDevice2GiPad] = @"iPad 2G",
    [kTCDevice3GiPad] = @"iPad 3G",
    [kTCDevice4GiPad] = @"iPad 4G",
    [kTCDevice5GiPad] = @"iPad 5G",
    
    // iPad mini
    [kTCDevice1GiPadMini] = @"iPad Mini 1G",
    [kTCDevice2GiPadMini] = @"iPad Mini 2G",
    [kTCDevice3GiPadMini] = @"iPad Mini 3G",
    [kTCDevice4GiPadMini] = @"iPad Mini 4G",
    
    // ipad Air
    [kTCDevice1GiPadAir] = @"iPad Air 1G",
    [kTCDevice2GiPadAir] = @"iPad Air 2G",
    [kTCDeviceUnknowniPad] = @"Unknown iPad",
    
    // ipad pro
    [kTCDevice1GiPadPro9_7] = @"iPad Pro 1G 9.7-inch",
    [kTCDevice1GiPadPro12_9] = @"iPad Pro 1G 12.9-inch",
    
    [kTCDevice1GiPadPro10_5] = @"iPad Pro 1G 10.5-inch",
    [kTCDevice2GiPadPro12_9] = @"iPad Pro 2G 12.9-inch",
    
    // apple TV
    [kTCDeviceAppleTV2] = @"Apple TV 2G",
    [kTCDeviceAppleTV3] = @"Apple TV 3G",
    [kTCDeviceAppleTV4] = @"Apple TV 4G",
    [kTCDeviceUnknownAppleTV] = @"Unknown Apple TV",
    
    // simulator
    [kTCDeviceSimulator] = @"iPhone Simulator",
    [kTCDeviceSimulatoriPhone] = @"iPhone Simulator",
    [kTCDeviceSimulatoriPad] = @"iPad Simulator",
    [kTCDeviceSimulatorAppleTV] = @"Apple TV Simulator",
};

@implementation UIDevice (TCHardware)


- (unsigned long long)appUsedMemory
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? (unsigned long long)info.resident_size : 0; // size in bytes
}

- (unsigned long long)appFreeMemory
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return (unsigned long long)(vm_stat.free_count * pagesize);
}


#pragma mark - sysctlbyname utils

- (NSString *)getSysInfoByName:(char *)typeSpecifier
{
    size_t size = 0;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = @(answer);

    free(answer);
    return results;
}

- (NSString *)platform
{
    return [self getSysInfoByName:"hw.machine"];
}


// Thanks, Tom Harrington (Atomicbird)
- (NSString *)hwmodel
{
    return [self getSysInfoByName:"hw.model"];
}


#pragma mark - sysctl utils

- (NSUInteger)getSysInfo:(int)typeSpecifier
{
    NSUInteger results = 0;
    size_t size = sizeof(results);
    int mib[] = {CTL_HW, typeSpecifier};
    sysctl(mib, sizeof(mib)/sizeof(mib[0]), &results, &size, NULL, 0);
    return results;
}

- (NSUInteger)cpuFrequency
{
    return [self getSysInfo:HW_CPU_FREQ];
}

- (NSUInteger)busFrequency
{
    return [self getSysInfo:HW_BUS_FREQ];
}

- (NSUInteger)cpuCount
{
    return [self getSysInfo:HW_NCPU];
}

- (NSUInteger)totalMemory
{
    return [self getSysInfo:HW_PHYSMEM];
}

- (NSUInteger)userMemory
{
    return [self getSysInfo:HW_USERMEM];
}

- (NSUInteger)maxSocketBufferSize
{
    return [self getSysInfo:KIPC_MAXSOCKBUF];
}


#pragma mark - platform type and name utils

- (TCDevicePlatform)platformType
{
    NSString *platform = self.platform;

    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"])         return kTCDevice1GiPhone;
    else if ([platform isEqualToString:@"iPhone1,2"])    return kTCDevice3GiPhone;
    else if ([platform hasPrefix:@"iPhone2"])            return kTCDevice3GSiPhone;
    else if ([platform hasPrefix:@"iPhone3"])            return kTCDevice4iPhone;
    else if ([platform hasPrefix:@"iPhone4"])            return kTCDevice4SiPhone;
    else if ([platform hasPrefix:@"iPhone5"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 2) {
            return kTCDevice5iPhone;
        } else if (subVersion <= 4) {
            return kTCDevice5CiPhone;
        }
    }
    else if ([platform hasPrefix:@"iPhone6"])            return kTCDevice5SiPhone;
    else if ([platform hasPrefix:@"iPhone7,1"])          return kTCDevice6PlusiPhone;
    else if ([platform hasPrefix:@"iPhone7,2"])          return kTCDevice6iPhone;
    else if ([platform hasPrefix:@"iPhone8,1"])          return kTCDevice6SiPhone;
    else if ([platform hasPrefix:@"iPhone8,2"])          return kTCDevice6SPlusiPhone;
    else if ([platform hasPrefix:@"iPhone8,4"])          return kTCDeviceSEiPhone;
    
    else if ([platform hasPrefix:@"iPhone9"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (1 == subVersion || 3 == subVersion) {
            return kTCDevice7iPhone;
        } else if (2 == subVersion || 4 == subVersion) {
            return kTCDevice7PlusiPhone;
        }
    }
    else if ([platform hasPrefix:@"iPhone10"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        switch (subVersion) {
            case 1:
            case 4:
                return kTCDevice8iPhone;
                
            case 2:
            case 5:
                return kTCDevice8PlusiPhone;
                
            case 3:
            case 6:
                return kTCDeviceXiPhone;
                
            default:
                break;
        }
    }
    
    // iPod
    else if ([platform hasPrefix:@"iPod1"])              return kTCDevice1GiPod;
    else if ([platform hasPrefix:@"iPod2"])              return kTCDevice2GiPod;
    else if ([platform hasPrefix:@"iPod3"])              return kTCDevice3GiPod;
    else if ([platform hasPrefix:@"iPod4"])              return kTCDevice4GiPod;
    else if ([platform hasPrefix:@"iPod5"])              return kTCDevice5GiPod;
    else if ([platform hasPrefix:@"iPod7"])              return kTCDevice6GiPod;

    // iPad
    else if ([platform hasPrefix:@"iPad1"])              return kTCDevice1GiPad;
    else if ([platform hasPrefix:@"iPad2"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 4) {
            return kTCDevice2GiPad;
        } else if (subVersion <= 7) {
            return kTCDevice1GiPadMini;
        }
    }
    else if ([platform hasPrefix:@"iPad3"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 3) {
            return kTCDevice3GiPad;
        } else if (subVersion <= 6) {
            return kTCDevice4GiPad;
        }
    }
    else if ([platform hasPrefix:@"iPad4"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 3) {
            return kTCDevice1GiPadAir;
        } else if (subVersion <= 6) {
            return kTCDevice2GiPadMini;
        } else if (subVersion <= 9) {
            return kTCDevice3GiPadMini;
        }
    }
    else if ([platform hasPrefix:@"iPad5"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 2) {
            return kTCDevice4GiPadMini;
        } else if (subVersion <= 4) {
            return kTCDevice2GiPadAir;
        }
    }
    else if ([platform hasPrefix:@"iPad6"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 4) {
            return kTCDevice1GiPadPro9_7;
        } else if (subVersion >= 7 && subVersion <= 8) {
            return kTCDevice1GiPadPro12_9;
        } else if (subVersion >= 11 && subVersion <= 12) {
            return kTCDevice5GiPad;
        }
    }
    else if ([platform hasPrefix:@"iPad7"]) {
        NSInteger subVersion = [[[platform componentsSeparatedByString:@","] lastObject] integerValue];
        if (subVersion <= 2) {
            return kTCDevice2GiPadPro12_9;
        } else if (subVersion <= 4) {
            return kTCDevice1GiPadPro10_5;
        }
    }
    
    // Apple TV
    else if ([platform hasPrefix:@"AppleTV2"])           return kTCDeviceAppleTV2;
    else if ([platform hasPrefix:@"AppleTV3"])           return kTCDeviceAppleTV3;
    
    // Simulator thanks Jordan Breeding
    else if ([platform hasSuffix:@"86"] || [platform isEqualToString:@"x86_64"]) {
        switch (UI_USER_INTERFACE_IDIOM()) {
            case UIUserInterfaceIdiomPad: return kTCDeviceSimulatoriPad;
            case UIUserInterfaceIdiomPhone: return kTCDeviceSimulatoriPhone;
            default:
                break;
        }
    }

    if ([platform hasPrefix:@"iPhone"])             return kTCDeviceUnknowniPhone;
    if ([platform hasPrefix:@"iPod"])               return kTCDeviceUnknowniPod;
    if ([platform hasPrefix:@"iPad"])               return kTCDeviceUnknowniPad;
    if ([platform hasPrefix:@"AppleTV"])            return kTCDeviceUnknownAppleTV;
    
    return kTCDeviceUnknown;
}

- (NSString *)platformString
{
    TCDevicePlatform type = self.platformType;
    if (type < kTCDeviceUnknown || type >= kTCDeviceCount) {
        type = kTCDeviceUnknown;
    }
    
    if (type == kTCDeviceUnknown ||
        type == kTCDeviceUnknowniPhone ||
        type == kTCDeviceUnknowniPod ||
        type == kTCDeviceUnknowniPad ||
        type == kTCDeviceUnknownAppleTV) {
        return self.platform;
    }
    
    return s_device_names[type];
}

- (TCDeviceScreen)deivceScreen
{
    CGSize size = UIScreen.mainScreen.bounds.size;
    CGFloat screenHeight = MAX(size.height, size.width);
    
    if (screenHeight == 480.0f) {
        return kTCDeviceScreen3Dot5inch;
    } else if (screenHeight == 568.0f) {
        return kTCDeviceScreen4inch;
    } else if (screenHeight == 667.0f) {
        return UIScreen.mainScreen.scale > 2.9f ? kTCDeviceScreen5Dot5inch : kTCDeviceScreen4Dot7inch;
    } else if (screenHeight == 736.0f) {
        return kTCDeviceScreen5Dot5inch;
    } else {
        return kTCDeviceScreenUnknown;
    }
}

- (BOOL)hasRetinaDisplay
{
    return UIScreen.mainScreen.scale >= 2.0f;
}

- (TCDeviceFamily)deviceFamily
{
    NSString *platform = self.platform;
    if ([platform hasPrefix:@"iPhone"]) return kTCDeviceFamilyiPhone;
    if ([platform hasPrefix:@"iPod"]) return kTCDeviceFamilyiPod;
    if ([platform hasPrefix:@"iPad"]) return kTCDeviceFamilyiPad;
    if ([platform hasPrefix:@"AppleTV"]) return kTCDeviceFamilyAppleTV;
    
    return kTCDeviceFamilyUnknown;
}

- (BOOL)cellularAccessable
{
    CTTelephonyNetworkInfo *ctInfo = [[CTTelephonyNetworkInfo alloc] init];
    return nil != ctInfo.subscriberCellularProvider && nil != ctInfo.subscriberCellularProvider.carrierName && nil != ctInfo.currentRadioAccessTechnology;
}

// https://stackoverflow.com/questions/7101206/know-if-ios-device-has-cellular-data-capabilities
- (BOOL)hasCellular
{
    static BOOL s_detected = NO;
    static BOOL s_found = NO;
    
    if (s_detected) {
        return s_found;
    }
    
    s_detected = YES;
    struct ifaddrs *addrs = NULL;
    struct ifaddrs const *cursor = NULL;
    
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        while (cursor != NULL) {
            if (NULL == cursor->ifa_name) {
                continue;
            }
            if (0 == strcmp(cursor->ifa_name, "pdp_ip0")) {
                s_found = YES;
                break;
            }
            cursor = cursor->ifa_next;
        }
        
        if (NULL != addrs) {
            freeifaddrs(addrs);
        }
    }
    return s_found;
}

#pragma mark - MAC addy
// Return the local MAC addy
// Courtesy of FreeBSD hackers email list
// Accidentally munged during previous update. Fixed thanks to mlamb.
- (NSString *)macaddress
{
    int mib[] = {
        CTL_NET,
        AF_ROUTE,
        0,
        AF_LINK,
        NET_RT_IFLIST,
        0
    };
    u_int size = sizeof(mib)/sizeof(mib[0]);
    
    if ((mib[5] = (int)if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return nil;
    }
    
    size_t len = 0;
    if (sysctl(mib, size, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return nil;
    }
    
    char *buf = malloc(len);
    if (buf == NULL) {
        printf("Error: Memory allocation error\n");
        return nil;
    }
    
    if (sysctl(mib, size, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2\n");
        free(buf); // Thanks, Remy "Psy" Demerest
        return nil;
    }
    
    struct if_msghdr *ifm = (struct if_msghdr *)buf;
    struct sockaddr_dl *sdl = (struct sockaddr_dl *)(ifm + 1);
    unsigned char *ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];

    free(buf);
    return outstring;
}

#pragma mark -

//static in_port_t get_in_port(const struct sockaddr *sa)
//{
//    if (sa->sa_family == AF_INET) {
//        return (((struct sockaddr_in*)sa)->sin_port);
//    }
//    
//    return (((struct sockaddr_in6*)sa)->sin6_port);
//}

+ (NSString *)stringFromSockAddr:(const struct sockaddr *)addr includeService:(BOOL)includeService
{
    if (NULL == addr) {
        return nil;
    }
    // FIXME: ipv6
    NSString *string = nil;
    char hostBuffer[NI_MAXHOST] = {0};
    char serviceBuffer[NI_MAXSERV] = {0};
    if (getnameinfo(addr, addr->sa_len, hostBuffer, sizeof(hostBuffer), serviceBuffer, sizeof(serviceBuffer), NI_NUMERICHOST | NI_NUMERICSERV | NI_NOFQDN) >= 0) {
        string = includeService ? [NSString stringWithFormat:@"%s:%s", hostBuffer, serviceBuffer] : @(hostBuffer);
    }
    return string;
}

+ (BOOL)isIpv6Available
{
    __block BOOL ipv6Available = NO;
    [self enumerateNetworkInterfaces:^(struct ifaddrs *addr, BOOL *stop) {
        unsigned int flags = addr->ifa_flags;
        if ((flags & (IFF_UP|IFF_RUNNING)) != (IFF_UP|IFF_RUNNING)) {
            return;
        }
        if (addr->ifa_addr->sa_family == AF_INET6){
            char ip[INET6_ADDRSTRLEN];
            const char *str = inet_ntop(AF_INET6, &(((struct sockaddr_in6 *)addr->ifa_addr)->sin6_addr), ip, INET6_ADDRSTRLEN);
            
            NSString *address = @(str);
            NSArray *addressComponents = [address componentsSeparatedByString:@":"];
            if (![addressComponents.firstObject isEqualToString:@"fe80"]){ // fe80 prefix in link-local ip
                ipv6Available = YES;
                *stop = YES;
            }
        }
    }];
    
    return ipv6Available;
}

+ (BOOL)isIpv4Available
{
    __block BOOL ipv4Available = NO;
    [self enumerateNetworkInterfaces:^(struct ifaddrs *addr, BOOL *stop) {
        unsigned int flags = addr->ifa_flags;
        if ((flags & (IFF_UP|IFF_RUNNING)) != (IFF_UP|IFF_RUNNING)) {
            return;
        }
        if (addr->ifa_addr->sa_family == AF_INET) {
            ipv4Available = YES;
            *stop = YES;
        }
    }];
    
    return ipv4Available;
}

+ (void)enumerateNetworkInterfaces:(void (^)(struct ifaddrs *addr, BOOL *stop))block
{
    if (nil == block) {
        return;
    }
    
    struct ifaddrs *interfaces = NULL;
    if (0 != getifaddrs(&interfaces)) {
        if (NULL != interfaces) {
            freeifaddrs(interfaces);
        }
        return;
    }
    
    struct ifaddrs *addr = interfaces;
    BOOL stop = NO;
    while (addr != NULL && !stop) {
//        unsigned int flags = addr->ifa_flags;
//        // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
//        if ((flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING)) {
//            block(addr, &stop);
//        }
        block(addr, &stop);
        
        addr = addr->ifa_next;
    }
    
    freeifaddrs(interfaces);
}

+ (NSString *)ipFromInterface:(TCNetworkInterfaceType)type
{
    static NSString *kMap[] = {
        [kTCNetworkInterfaceTypeLoopback] = @"lo0",
        [kTCNetworkInterfaceTypeCellular] = @"pdp_ip0",
        [kTCNetworkInterfaceTypeWiFi] = @"en0",
        [kTCNetworkInterfaceTypeHotspot] = @"bridge100",
        [kTCNetworkInterfaceTypeUSB] = @"en2",
        [kTCNetworkInterfaceTypeBluetooth] = @"en3",
        
        [kTCNetworkInterfaceTypeNEVPN] = @"utun1",
        [kTCNetworkInterfaceTypePersonalVPN] = @"ipsec0",
    };
    
    if (type < 0 || type >= kTCNetworkInterfaceTypeCount) {
        return nil;
    }
    
    if ((kTCNetworkInterfaceTypeUSB == type || kTCNetworkInterfaceTypeBluetooth == type)
        // iPod, iPad, >= iOS11
        && !UIDevice.currentDevice.hasCellular
        && [UIDevice.currentDevice.systemVersion compare:@"11" options:NSNumericSearch] != NSOrderedAscending) {
        if (kTCNetworkInterfaceTypeUSB == type) {
            type = kTCNetworkInterfaceTypeBluetooth;
        } else {
            type = kTCNetworkInterfaceTypeUSB;
        }
    }
    
    NSString *ifType = kMap[type];
    __block NSString *ip = nil;
    [self enumerateNetworkInterfaces:^(struct ifaddrs * _Nonnull addr, BOOL * _Nonnull stop) {
        unsigned int flags = addr->ifa_flags;
        if ((flags & (IFF_UP|IFF_RUNNING)) != (IFF_UP|IFF_RUNNING)) {
            return;
        }
        
        if (NULL != addr->ifa_netmask && NULL != addr->ifa_addr && NULL != addr->ifa_name && [@(addr->ifa_name) isEqualToString:ifType]) {
            NSString *tmp = [self stringFromSockAddr:addr->ifa_addr includeService:NO];
            if (nil != tmp) {
                ip = tmp;
                if (addr->ifa_addr->sa_family == AF_INET) {
                    *stop = YES;
                }
            }
        }
    }];
    return ip;
}


#pragma mark -

- (void)sysDNSServersIpv4:(NSArray<NSString *> **)ipv4 ipv6: (NSArray<NSString *> **)ipv6
{
    if (ipv4 == NULL && ipv6 == NULL) {
        return;
    }
    
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);
    if (result != 0) {
        res_ndestroy(res);
        free(res);
        return;
    }
    
    union res_9_sockaddr_union *addr_union = malloc((size_t)res->nscount * sizeof(union res_9_sockaddr_union));
    if (NULL == addr_union) {
        res_ndestroy(res);
        free(res);
        return;
    }
    res_getservers(res, addr_union, res->nscount);
    
    NSMutableArray *ipv4s = NSMutableArray.array;
    NSMutableArray *ipv6s = NSMutableArray.array;
    
    @autoreleasepool {
        for (int i = 0; i < res->nscount; i++) {
            
            if (addr_union[i].sin.sin_family == AF_INET) {
                char str[INET_ADDRSTRLEN + 1] = {'\0'};
                if (NULL != inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), str, INET_ADDRSTRLEN)) {
                    NSString *address = @(str);
                    if (address.length > 0) {
                        [ipv4s addObject:address];
                    }
                }
            } else if (addr_union[i].sin6.sin6_family == AF_INET6) {
                char str[INET6_ADDRSTRLEN + 1] = {'\0'};
                if (NULL != inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), str, INET6_ADDRSTRLEN)) {
                    NSString *address = @(str);
                    if (address.length > 0) {
                        [ipv6s addObject:address];
                    }
                }
            }
        }
        free(addr_union);
        res_ndestroy(res);
        free(res);
    }
    if (ipv4s.count > 0 && NULL != ipv4) {
        *ipv4 = ipv4s.copy;
    }
    
    if (ipv6s.count > 0 && NULL != ipv6) {
        *ipv6 = ipv6s.copy;
    }
}


- (NSArray<NSString *> *)dnsAddresses
{
    NSArray *ipv4Dns = nil;
    NSArray *ipv6Dns = nil;
    [self sysDNSServersIpv4:&ipv4Dns ipv6:&ipv6Dns];
    NSMutableArray *dnsServers = NSMutableArray.array;
    [dnsServers addObjectsFromArray:ipv4Dns];
    [dnsServers addObjectsFromArray:ipv6Dns];
    
    return dnsServers.count > 0 ? dnsServers : nil;
}

- (BOOL)isVPNON
{
    CFDictionaryRef dicRef = CFNetworkCopySystemProxySettings();
    if (NULL == dicRef) {
        return NO;
    }
    NSDictionary *dic = (__bridge_transfer NSDictionary *)dicRef;
    if (dic.count < 1) {
        return NO;
    }
    NSArray *keys = [dic[@"__SCOPED__"] allKeys];
    for (NSString *key in keys) {
        if ([key rangeOfString:@"tap"].location != NSNotFound ||
            [key rangeOfString:@"tun"].location != NSNotFound ||
            [key rangeOfString:@"ipsec"].location != NSNotFound ||
            [key rangeOfString:@"ppp"].location != NSNotFound) {
            return YES;;
        }
    }
    return NO;
}

- (void)HTTPProxy:(NSString **)host port:(NSNumber **)port
{
    CFDictionaryRef dicRef = CFNetworkCopySystemProxySettings();
    if (NULL == dicRef) {
        return;
    }
    
    NSDictionary *dic = (__bridge_transfer NSDictionary *)dicRef;
    if (dic.count < 1) {
        return;
    }
    NSString *proxy = dic[(id)kCFNetworkProxiesHTTPProxy];
    if (proxy.length > 0) {
        if (NULL != host) {
            *host = proxy;
        }
        if (NULL != port) {
            *port = dic[(id)kCFNetworkProxiesHTTPPort];
        }
        return;
    }
    
    dic = [dic[@"__SCOPED__"] allValues].firstObject;
    proxy = dic[(id)kCFNetworkProxiesHTTPProxy];
    if (proxy.length > 0) {
        if (NULL != host) {
            *host = proxy;
        }
        if (NULL != port) {
            *port = dic[(id)kCFNetworkProxiesHTTPPort];
        }
        return;
    }
}
// #define ROUNDUP(a) \
((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))
//- (NSString *)gatewayIPAddress
//{
//    NSString *address = nil;
//
//    /* net.route.0.inet.flags.gateway */
//    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET,
//        NET_RT_FLAGS, RTF_GATEWAY};
//    size_t l = 0;
//    struct rt_msghdr * rt;
//    struct sockaddr * sa;
//    struct sockaddr * sa_tab[RTAX_MAX];
//    int i;
//    int r = -1;
//
//    if (sysctl(mib, sizeof(mib)/sizeof(mib[0]), 0, &l, 0, 0) < 0 || l < 1) {
//        return address;
//    }
//
//    char *buf = malloc(l);
//    if (sysctl(mib, sizeof(mib)/sizeof(mib[0]), buf, &l, 0, 0) < 0) {
//        return address;
//    }
//
//    for (char *p=buf; p<buf+l; p+=rt->rtm_msglen) {
//        rt = (struct rt_msghdr *)p;
//        sa = (struct sockaddr *)(rt + 1);
//        for (i=0; i<RTAX_MAX; i++) {
//            if (rt->rtm_addrs & (1 << i)) {
//                sa_tab[i] = sa;
//                sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
//            } else {
//                sa_tab[i] = NULL;
//            }
//        }
//
//        if(((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
//           && sa_tab[RTAX_DST]->sa_family == AF_INET
//           && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
//            unsigned char octet[4]  = {0,0,0,0};
//            int i;
//            for (i=0; i<4; i++) {
//                octet[i] = ( ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr >> (i*8) ) & 0xFF;
//            }
//            if (((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
//                in_addr_t addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
//                r = 0;
//                address = [NSString stringWithFormat:@"%s", inet_ntoa(*((struct in_addr*)&addr))];
//                break;
//            }
//        }
//    }
//    free(buf);
//    return address;
//}

// https://www.cnblogs.com/mobilefeng/p/4977783.html
- (void)fetchMemoryStatistics:(void (^)(size_t total, size_t wired, size_t active, size_t inactive, size_t free))block
{
    // Get Page Size
    int mib[2];
    vm_size_t page_size = 0;
    size_t len = 0;
    
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    len = sizeof(page_size);
    
    if (host_page_size(mach_host_self(), &page_size) != KERN_SUCCESS) {
        NSLog(@"Failed to get page size");
    }
    
    // Get Memory Size
    mib[0] = CTL_HW;
    mib[1] = HW_MEMSIZE;
    size_t ram = 0;
    len = sizeof(ram);
    if (sysctl(mib, 2, &ram, &len, NULL, 0)) {
        NSLog(@"Failed to get ram size");
    }
    
    // Get Memory Statistics
    //    vm_statistics_data_t vm_stats;
    //    mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
    vm_statistics64_data_t vm_stats;
    mach_msg_type_number_t info_count64 = HOST_VM_INFO64_COUNT;
    //    kern_return_t kern_return = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stats, &info_count);
    kern_return_t kern_return = host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vm_stats, &info_count64);
    if (kern_return != KERN_SUCCESS) {
        NSLog(@"Failed to get VM statistics!");
    }
    
    //    double vm_total = vm_stats.wire_count + vm_stats.active_count + vm_stats.inactive_count + vm_stats.free_count;
    size_t vm_wire = vm_stats.wire_count;
    size_t vm_active = vm_stats.active_count;
    size_t vm_inactive = vm_stats.inactive_count;
    size_t vm_free = vm_stats.free_count;
    
    if (nil != block) {
        block(ram, vm_wire * page_size, vm_active * page_size, vm_inactive * page_size, vm_free * page_size);
    }
}

- (void)diskTotalSpace:(uint64_t *)pTotal freeSpace:(uint64_t *)pFree
{
    struct statfs buf;
    if (statfs("/var", &buf) >= 0) {
        if (NULL != pTotal) {
            *pTotal = (uint64_t)buf.f_bsize * buf.f_blocks;
        }
        if (NULL != pFree) {
            *pFree = (uint64_t)buf.f_bsize * buf.f_bfree;
        }
    }
}

- (float)cpuUsage
{
    kern_return_t kr;
    mach_msg_type_number_t count;
    static host_cpu_load_info_data_t previous_info = {0, 0, 0, 0};
    host_cpu_load_info_data_t info;
    
    count = HOST_CPU_LOAD_INFO_COUNT;
    
    kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&info, &count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    natural_t user   = info.cpu_ticks[CPU_STATE_USER] - previous_info.cpu_ticks[CPU_STATE_USER];
    natural_t nice   = info.cpu_ticks[CPU_STATE_NICE] - previous_info.cpu_ticks[CPU_STATE_NICE];
    natural_t system = info.cpu_ticks[CPU_STATE_SYSTEM] - previous_info.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t idle   = info.cpu_ticks[CPU_STATE_IDLE] - previous_info.cpu_ticks[CPU_STATE_IDLE];
    natural_t total  = user + nice + system + idle;
    previous_info    = info;
    
    return (user + nice + system) * 100.0f / total;
}

- (NSDate *)systemUpTime
{
    struct timeval boottime;
    size_t len = sizeof(boottime);
    static int mib[] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, sizeof(mib)/sizeof(mib[0]), &boottime, &len, NULL, 0) < 0) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:boottime.tv_sec];
}


@end
