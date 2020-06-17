#import <UIKit/UIKit.h>
#import <ifaddrs.h>
#import <net/if.h>

typedef NS_ENUM(NSInteger, TCDevicePlatform) {
    kTCDeviceUnknown = 0,
    
    kTCDeviceSimulator,
    kTCDeviceSimulatoriPhone,
    kTCDeviceSimulatoriPad,
    kTCDeviceSimulatorAppleTV,
    
    
    kTCDevice1GiPhone,
    kTCDevice3GiPhone,
    kTCDevice3GSiPhone,
    
    kTCDevice4iPhone,
    kTCDevice4SiPhone,
    
    kTCDevice5iPhone,
    kTCDevice5CiPhone,
    kTCDevice5SiPhone,
    
    kTCDevice6iPhone,
    kTCDevice6PlusiPhone,
    
    kTCDeviceSEiPhone,
    kTCDevice6SiPhone,
    kTCDevice6SPlusiPhone,
    
    kTCDevice7iPhone,
    kTCDevice7PlusiPhone,
    
    kTCDevice8iPhone,
    kTCDevice8PlusiPhone,
    kTCDeviceXiPhone,
    
    // 2018
    kTCDeviceXR,
    kTCDeviceXS,
    kTCDeviceXSMax,
    
    // 2020
    kTCDeviceSE2iPhone,
    
    // 2019
    kTCDevice11,
    kTCDevice11Pro,
    kTCDevice11ProMax,
    
    kTCDevice1GiPod,
    kTCDevice2GiPod,
    kTCDevice3GiPod,
    kTCDevice4GiPod,
    kTCDevice5GiPod,
    kTCDevice6GiPod,
    kTCDevice7GiPod,
    
    kTCDevice1GiPad,
    kTCDevice2GiPad,
    kTCDevice1GiPadMini,
    
    kTCDevice3GiPad,
    kTCDevice4GiPad,
    kTCDevice5GiPad,
    
    kTCDevice1GiPadAir,
    kTCDevice2GiPadMini,
    kTCDevice3GiPadMini,
    kTCDevice4GiPadMini,
    
    kTCDevice2GiPadAir,
    
    kTCDevice1GiPadPro9_7,
    kTCDevice1GiPadPro10_5,
    
    kTCDevice1GiPadPro12_9,
    kTCDevice2GiPadPro12_9,
    
    kTCDevice5GiPadMini,
    kTCDevice3GiPadAir,
    
    
    // 2018
    kTCDevice6GiPad,
    kTCDevice1GiPadPro11,
    kTCDevice1GiPadPro11_1TB,
    kTCDevice3GiPadPro12_9,
    kTCDevice3GiPadPro12_9_1TB,
    
    // 2019
    kTCDevice7GiPad,
    kTCDevice2GiPadPro11,
    kTCDevice4GiPadPro12_9,
    
    kTCDeviceAppleTV2,
    kTCDeviceAppleTV3,
    kTCDeviceAppleTV4,
    
    kTCDeviceUnknowniPhone,
    kTCDeviceUnknowniPod,
    kTCDeviceUnknowniPad,
    kTCDeviceUnknownAppleTV,
    
    
    kTCDeviceCount,
};

typedef NS_ENUM(NSInteger, TCDeviceFamily) {
    kTCDeviceFamilyUnknown = 0,
    kTCDeviceFamilyiPhone,
    kTCDeviceFamilyiPod,
    kTCDeviceFamilyiPad,
    kTCDeviceFamilyAppleTV,
};

typedef NS_ENUM(NSInteger, TCDeviceScreen) {
    kTCDeviceScreenUnknown = 0,
    kTCDeviceScreen3_5inch,
    kTCDeviceScreen4inch,
    kTCDeviceScreen4_7inch,
    kTCDeviceScreen5_5inch,
    kTCDeviceScreen5_8inch,
    
    kTCDeviceScreen6_1inch,
    kTCDeviceScreen6_5inch,
    
    kTCDeviceScreen7_9inch,
    kTCDeviceScreen9_7inch,
    kTCDeviceScreen10_5inch,
    kTCDeviceScreen11inch,
    kTCDeviceScreen12_9inch,
};


NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (TCHardware)

+ (nullable NSString *)versionModel;
+ (nullable NSString *)platform;
+ (nullable NSString *)hwmodel;
+ (TCDevicePlatform)platformType;
+ (nullable NSString *)platformString;
+ (TCDeviceScreen)screenMode;
+ (nullable NSString *)screenInchString;

+ (NSUInteger)cpuFrequency;
+ (NSUInteger)busFrequency;
+ (NSUInteger)cpuCount;
+ (NSUInteger)totalMemory;
+ (NSUInteger)userMemory;

+ (unsigned long long)appUsedMemory;
+ (unsigned long long)appFreeMemory;

/*
+ (nullable NSString *)macaddress;
+ (nullable NSString *)macaddress:(const char *)ifname;
 */

+ (nullable NSArray<NSString *> *)dnsAddresses;
+ (void)sysDNSServersIpv4:(NSArray<NSString *> * _Nullable __autoreleasing *_Nullable)ipv4 ipv6: (NSArray<NSString *> * _Nullable __autoreleasing *_Nullable)ipv6;

//- (NSString *)gatewayIPAddress;
+ (void)HTTPProxy:(NSString *_Nullable __autoreleasing * _Nullable)host port:(NSNumber *_Nullable __autoreleasing * _Nullable)port;

+ (void)fetchMemoryStatistics:(void (^)(size_t total, size_t wired, size_t active, size_t inactive, size_t free))block;
+ (nullable NSDate *)systemUpTime;
+ (float)cpuUsage;
+ (BOOL)diskTotalSpace:(uint64_t *_Nullable)pTotal freeSpace:(uint64_t *_Nullable)pFree error:(NSError **)error;
+ (BOOL)isVPNOn;

+ (BOOL)hasRetinaDisplay;
+ (TCDeviceFamily)deviceFamily;
+ (BOOL)hasCellular;
+ (BOOL)cellularAccessable;


#pragma mark -

+ (BOOL)isIpv4Available;
+ (BOOL)isIpv6Available;

// enumerate running IPv4, IPv6 interfaces. Skip the loopback interface.
+ (void)enumerateNetworkInterfaces:(void (^)(struct ifaddrs *addr, BOOL *stop))block;

+ (nullable NSString *)stringFromSockAddr:(const struct sockaddr *)addr includeService:(BOOL)includeService;

typedef NS_ENUM(NSInteger, TCNetworkInterfaceType) {
    kTCNetworkInterfaceTypeUnknown = -1,
    kTCNetworkInterfaceTypeLoopback = 0, // lo0
    kTCNetworkInterfaceTypeCellular, // pdp_ip0
    kTCNetworkInterfaceTypeWiFi, // en0
    kTCNetworkInterfaceTypeHotspot, // bridge100
    kTCNetworkInterfaceTypeUSB, // en2, iOS 11 iPod: en3
    kTCNetworkInterfaceTypeBluetooth, // en3, iOS 11 iPod: en2
    
    kTCNetworkInterfaceTypeNEVPN, // utun1
    kTCNetworkInterfaceTypePersonalVPN, // ipsec0
    
    kTCNetworkInterfaceTypeCount,
};

+ (nullable NSString *)ipFromInterface:(TCNetworkInterfaceType)type;

@end

NS_ASSUME_NONNULL_END
