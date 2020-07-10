//
//  TCHTTPStreamPolicy.m
//  TCKit
//
//  Created by dake on 16/3/28.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPStreamPolicy.h"
#import "TCHTTPRequestHelper.h"
#import "NSURLSessionTask+TCResumeDownload.h"

@implementation TCHTTPStreamPolicy


- (NSString *)downloadIdentifier
{
    if (nil == _downloadIdentifier) {
        _downloadIdentifier = [TCHTTPRequestHelper MD5_16:self.request.apiUrl];
    }
    return _downloadIdentifier;
}

- (NSURL *)downloadResumeCacheDirectory
{
    if (nil == _downloadResumeCacheDirectory) {
        NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TCHTTPRequestResumeCache"];
        if (![NSFileManager.defaultManager createDirectoryAtPath:dir
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:NULL]) {
            NSCAssert(false, @"create directory failed.");
            dir = nil;
        }
        
        _downloadResumeCacheDirectory = nil != dir ? [NSURL fileURLWithPath:dir] : nil;
    }
    
    return _downloadResumeCacheDirectory;
}

- (void)purgeResumeData
{
    [self.request.requestTask tc_purgeResumeData];
}



@end
