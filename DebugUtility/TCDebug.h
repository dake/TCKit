//
//  TCDebug.h
//  TCKit
//
//  Created by dake on 13-1-30.
//  Copyright (c) 2013年 dake. All rights reserved.
//


#if !defined(TC_IOS_DEBUG) && (defined(DEBUG) || defined(_DEBUG) || defined(__DEBUG))
#define TC_IOS_DEBUG
#endif


#ifndef TARGET_IS_EXTENSION

#import "iConsole.h"

#ifdef TC_IOS_DEBUG

// info
#define DLog_i(fmt, ...) \
[NSClassFromString(@"iConsole") info:@"%@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__]

// warning
#define DLog_w(fmt, ...) \
[NSClassFromString(@"iConsole") warn:@"%@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
 __LINE__, \
 __PRETTY_FUNCTION__,## __VA_ARGS__]

// error
#define DLog_e(fmt, ...) \
[NSClassFromString(@"iConsole") error:@"%@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__]

// crash
#define DLog_c(fmt, ...) \
[NSClassFromString(@"iConsole") crash:@"%@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__]

#define DLog DLog_i
#define RLog DLog

#ifdef NSLog
#undef NSLog
#endif

#ifndef NSLog
#define NSLog DLog_i
#endif

#else // TC_IOS_DEBUG

#define DLog(...)   ;
#define DLog_i(...) ;
#define DLog_w(...) ;
#define DLog_e(...) ;
#define DLog_c(...) ;


#ifndef TC_IOS_PUBLISH

#define RLog(fmt, ...) \
[NSClassFromString(@"iConsole") info:@"%@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__]

#ifdef NSLog
#undef NSLog
#endif

#ifndef NSLog
#define NSLog RLog
#endif

#else // TC_IOS_PUBLISH

#define RLog(...) ;

#ifdef NSLog
#undef NSLog
#endif

#define NSLog(...) ;

#endif // TC_IOS_PUBLISH
#endif // TC_IOS_DEBUG


#else // TARGET_IS_EXTENSION

#ifdef TC_IOS_DEBUG

// info
#define DLog_i(fmt, ...) \
NSLog(@"INFO: %@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__)

// warning
#define DLog_w(fmt, ...) \
NSLog(@"🚸WARNING: %@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__)

// error
#define DLog_e(fmt, ...) \
NSLog(@"‼️ERROR: %@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__)

// crash
#define DLog_c(fmt, ...) \
NSLog(@"❌CRASH: %@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__)

#define DLog DLog_i
#define RLog DLog

#else // TC_IOS_DEBUG

#define DLog(...)   ;
#define DLog_i(...) ;
#define DLog_w(...) ;
#define DLog_e(...) ;
#define DLog_c(...) ;


#ifndef TC_IOS_PUBLISH

#define RLog(fmt, ...) \
NSLog(@"⛔️⛔️⛔️INFO: %@(%d)\n%s: " fmt , [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
__LINE__, \
__PRETTY_FUNCTION__,## __VA_ARGS__)

//#ifdef NSLog
//#undef NSLog
//#endif
//
//#ifndef NSLog
//#define NSLog RLog
//#endif

#else // TC_IOS_PUBLISH

#define RLog(...) ;

#ifdef NSLog
#undef NSLog
#endif

#define NSLog(...) ;

#endif // TC_IOS_PUBLISH
#endif // TC_IOS_DEBUG



#endif // TARGET_IS_EXTENSION
