//
//  NSOutputStream+TCHelper.h
//  TCFoundation
//
//  Created by dake on 2017/12/15.
//  Copyright © 2017年 PixelCyber. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSOutputStream (TCHelper)

- (NSInteger)syncWrite:(const uint8_t *)buffer length:(NSUInteger)len;

@end


@interface NSFileHandle (TCHelper)

- (nullable NSData *)tc_readDataToEndOfFileAndReturnError:(out NSError **)error;

- (nullable NSData *)tc_readDataUpToLength:(NSUInteger)length error:(out NSError **)error;

- (BOOL)tc_writeData:(NSData *)data error:(out NSError **)error;

- (BOOL)tc_getOffset:(out unsigned long long *)offsetInFile error:(out NSError **)error;

- (BOOL)tc_seekToEndReturningOffset:(out unsigned long long *_Nullable)offsetInFile error:(out NSError **)error;

- (BOOL)tc_seekToOffset:(unsigned long long)offset error:(out NSError **)error;

- (BOOL)tc_truncateAtOffset:(unsigned long long)offset error:(out NSError **)error;

- (BOOL)tc_synchronizeAndReturnError:(out NSError **)error;

- (BOOL)tc_closeAndReturnError:(out NSError **)error;

@end


@interface TCRangeInputStream : NSInputStream

@property (nonatomic, assign, readonly) NSRange range;

+ (nullable instancetype)inputStreamWithData:(NSData *)data range:(NSRangePointer _Nullable)rangePointer;
+ (nullable instancetype)inputStreamWithFileURL:(NSURL *)url range:(NSRangePointer _Nullable)rangePointer;
+ (nullable instancetype)inputStreamWithFile:(FILE *)file size:(NSUInteger)size range:(NSRangePointer _Nullable)rangePointer;
//+ (nullable instancetype)inputStreamWithFileDescriptor:(int)file size:(NSUInteger)size range:(NSRangePointer _Nullable)rangePointer;

@end

NS_ASSUME_NONNULL_END
