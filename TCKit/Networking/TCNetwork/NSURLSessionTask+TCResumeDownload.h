//
//  NSURLSessionTask+TCResumeDownload.h
//  TCKit
//
//  Created by dake on 16/1/9.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSURLSessionTask (TCResumeDownload)

// for persistent resume download
@property (nonatomic, copy) NSString *tc_resumeIdentifier;
@property (nonatomic, strong) NSURL *tc_resumeCacheDirectory;

// must called by task return by -[NSURLSession downloadTaskWith***] like methods.
- (BOOL)tc_makePersistentResumeCapable;

// autoHash YES
+ (nullable NSData *)tc_resumeDataWithIdentifier:(NSString *)identifier inDirectory:(nullable NSURL *)subpath autoHash:(BOOL)autoHash;

// call this, while NSURLSessionDownloadTask failed with error: NSPOSIXErrorDomain, code = 2. etc..
+ (void)tc_purgeResumeDataWithIdentifier:(NSString *)identifier inDirectory:(nullable NSURL *)subpath autoHash:(BOOL)autoHash;
- (void)tc_purgeResumeData;

@end

NS_ASSUME_NONNULL_END
