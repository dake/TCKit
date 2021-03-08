#import <UIKit/UIKit.h>
#import <ifaddrs.h>
#import <net/if.h>

typedef NS_ENUM(NSInteger, TCDevicePlatform) {
    kTCDeviceUnknown = 0,
    
    kTCDeviceSimulator,
    kTCDeviceSimulatoriPhone,
    kTCDeviceSimulatoriPad,
    kTCDeviceSimulatorAppleTV,
    
    
    kTCDevice1GiPhone, // 3.5
    kTCDevice3GiPhone, // 3.5
    kTCDevice3GSiPhone, // 3.5
    
    kTCDevice4iPhone, // 3.5
    kTCDevice4SiPhone, // 3.5
    
    kTCDevice5iPhone, // 4
    kTCDevice5CiPhone, // 4
    kTCDevice5SiPhone, // 4
    
    kTCDevice6iPhone, // 4.7
    kTCDevice6PlusiPhone, // 5.5
    
    kTCDeviceSEiPhone, // 4
    kTCDevice6SiPhone, // 4.7
    kTCDevice6SPlusiPhone, // 5.5
    
    kTCDevice7iPhone, // 4.7
    kTCDevice7PlusiPhone, // 5.5
    
    kTCDevice8iPhone, // 4.7
    kTCDevice8PlusiPhone, // 5.5
    kTCDeviceXiPhone, // 5.8
    
    // 2018
    kTCDeviceiPhoneXR, // 6.1
    kTCDeviceiPhoneXS, // 5.8
    kTCDeviceiPhoneXSMax, // 6.5
    
    // 2020
    kTCDeviceSE2iPhone, // 4.7
    
    // 2019
    kTCDevice11iPhone, // 6.1
    kTCDevice11iPhonePro, // 5.8
    kTCDevice11iPhoneProMax, // 6.5
    
    // 2020
    kTCDevice12iPhoneMini, // 5.4
    kTCDevice12iPhone, // 6.1
    kTCDevice12iPhonePro, // 6.1
    kTCDevice12iPhoneProMax, // 6.7
    
    kTCDevice1GiPod,
    kTCDevice2GiPod,
    kTCDevice3GiPod,
    kTCDevice4GiPod,
    kTCDevice5GiPod,
    kTCDevice6GiPod,
    kTCDevice7GiPod,
    
    kTCDevice1GiPad, // 9.7
    kTCDevice2GiPad, // 9.7
    kTCDevice1GiPadMini, // 7.9
    
    kTCDevice3GiPad, // 9.7
    kTCDevice4GiPad, // 9.7
    kTCDevice5GiPad, // 9.7
    
    kTCDevice1GiPadAir, // 9.7
    kTCDevice2GiPadMini, // 7.9
    kTCDevice3GiPadMini, // 7.9
    kTCDevice4GiPadMini, // 7.9
     
    kTCDevice2GiPadAir, // 9.7
    
    kTCDevice1GiPadPro9_7,
    kTCDevice1GiPadPro10_5,
    
    kTCDevice1GiPadPro12_9,
    kTCDevice2GiPadPro12_9,
    
    kTCDevice5GiPadMini, // 7.9
    kTCDevice3GiPadAir, // 10.5
    
    
    // 2018
    kTCDevice6GiPad, // 9.7
    kTCDevice1GiPadPro11,
    kTCDevice1GiPadPro11_1TB,
    kTCDevice3GiPadPro12_9,
    kTCDevice3GiPadPro12_9_1TB,
    
    // 2019
    kTCDevice7GiPad, // 10.2
    kTCDevice2GiPadPro11,
    kTCDevice4GiPadPro12_9,
    
    // 2020
    kTCDevice8GiPad, // 10.2
    kTCDevice4GiPadAir, // 10.9
    
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
    kTCDeviceFamilyCarplay,
};

typedef NS_ENUM(NSInteger, TCDeviceScreen) {
    kTCDeviceScreenUnknown = 0,
    
    kTCDeviceScreen3_5inch, // 320 x 480 pt
    kTCDeviceScreen4inch, // 320 x 568 pt
    kTCDeviceScreen4_7inch, // 375 x 667 pt
    kTCDeviceScreen5_5inch, // 414 x 736 pt
    kTCDeviceScreen5_8inch, // 375 x 812 pt
    
    kTCDeviceScreen6_1inch, // 390 x 844 pt
    kTCDeviceScreen6_5inch, // 414pt x 896 pt
    kTCDeviceScreen6_7inch, // 428 x 926 pt
    
    kTCDeviceScreen7_9inch,
    kTCDeviceScreen9_7inch,
    kTCDeviceScreen10_5inch,
    kTCDeviceScreen11inch,
    kTCDeviceScreen12_9inch,
    
    
    kTCDeviceScreenBigger,
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
+ (void)HTTPSProxy:(NSString *_Nullable __autoreleasing * _Nullable)host port:(NSNumber *_Nullable __autoreleasing * _Nullable)port;

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
    kTCNetworkInterfaceTypeWiFi, // en0, mac: en1
    kTCNetworkInterfaceTypeHotspot, // bridge100
    
    kTCNetworkInterfaceTypeEthernet,// mac: en0
    kTCNetworkInterfaceTypeCable, // en2, iOS 11 iPod: en3, mac :en8
    kTCNetworkInterfaceTypeBluetooth, // en3, iOS 11 iPod: en2
    
    kTCNetworkInterfaceTypeNEVPN, // utun1, ios13: utun5, ios14: utun2
    kTCNetworkInterfaceTypePersonalVPN, // ipsec0
    
    kTCNetworkInterfaceTypeCount,
};

+ (TCNetworkInterfaceType)interfaceTypeWithName:(NSString *)name;
+ (nullable NSString *)ipFromInterface:(TCNetworkInterfaceType)type ipv6:(BOOL *_Nullable)ipv6;
+ (nullable NSString *)ipFromInterface:(TCNetworkInterfaceType)type destination:(BOOL)destination ipv6:(BOOL *_Nullable)ipv6;

@end

NS_ASSUME_NONNULL_END
