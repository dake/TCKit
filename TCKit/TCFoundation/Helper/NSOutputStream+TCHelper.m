//
//  NSOutputStream+TCHelper.m
//  TCFoundation
//
//  Created by dake on 2017/12/15.
//  Copyright © 2017年 PixelCyber. All rights reserved.
//

#import "NSOutputStream+TCHelper.h"

@implementation NSOutputStream (TCHelper)

- (NSInteger)syncWrite:(const uint8_t *)buffer length:(NSUInteger)len
{
    NSUInteger size = len;
    NSUInteger writedSize = 0;
    do {
        NSInteger wSize = [self write:buffer+writedSize maxLength:size];
        if (wSize > 0) {
            writedSize += (NSUInteger)wSize;
            size -= (NSUInteger)wSize;
        }
        if (size < 1 || (wSize < 1 && !self.hasSpaceAvailable)) {
            return (NSInteger)writedSize;
        }
    } while (true);
}

@end


@implementation NSFileHandle (TCHelper)

- (nullable NSData *)tc_readDataToEndOfFileAndReturnError:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self readDataToEndOfFileAndReturnError:error];
    } else {
        return [self readDataToEndOfFile];
    }
}

- (nullable NSData *)tc_readDataUpToLength:(NSUInteger)length error:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self readDataUpToLength:length error:error];
    } else {
        return [self readDataOfLength:length];
    }
}

- (BOOL)tc_writeData:(NSData *)data error:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self writeData:data error:error];
    } else {
        [self writeData:data];
        return YES;
    }
}

- (BOOL)tc_getOffset:(out unsigned long long *)offsetInFile error:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self getOffset:offsetInFile error:error];
    } else {
        if (NULL == offsetInFile) {
            return NO;
        }
        *offsetInFile = self.offsetInFile;
        return YES;
    }
}

- (BOOL)tc_seekToEndReturningOffset:(out unsigned long long *_Nullable)offsetInFile error:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self seekToEndReturningOffset:offsetInFile error:error];
    } else {
        unsigned long long offet = self.seekToEndOfFile;
        if (NULL != offsetInFile) {
            *offsetInFile = offet;
        }
        return YES;
    }
}

- (BOOL)tc_seekToOffset:(unsigned long long)offset error:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self seekToOffset:offset error:error];
    } else {
        [self seekToFileOffset:offset];
        return YES;
    }
}

- (BOOL)tc_truncateAtOffset:(unsigned long long)offset error:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self truncateAtOffset:offset error:error];
    } else {
        [self truncateFileAtOffset:offset];
        return YES;
    }
}

- (BOOL)tc_synchronizeAndReturnError:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self synchronizeAndReturnError:error];
    } else {
        [self synchronizeFile];
        return YES;
        
    }
}

- (BOOL)tc_closeAndReturnError:(out NSError **)error
{
    if (@available(iOS 13, *)) {
        return [self closeAndReturnError:error];
    } else {
        [self closeFile];
        return YES;
    }
}

@end


#import "NSURL+TCHelper.h"


@interface TCRangeInputStream ()

@property (nonatomic, assign, readwrite) NSRange range;

@property (atomic, assign) NSStreamStatus innerStatus;
@property (atomic, assign) NSUInteger readLen;
@property (atomic, assign) BOOL reading;

@property (nonatomic, strong) NSURL *innerFileURL;
@property (nonatomic, assign) FILE *rawFile;
//@property (nonatomic, assign) int rawFileDescriptor;
@property (nonatomic, strong) NSData *rawData;

@end

@implementation TCRangeInputStream
{
@private
    FILE *_handle;
    NSError *_streamError;
}

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        _rawFileDescriptor = -1;
//    }
//    return self;
//}

+ (nullable instancetype)inputStreamWithData:(NSData *)data range:(NSRangePointer _Nullable)rangePointer
{
    NSCParameterAssert(data);
    NSUInteger const len = data.length;
    NSRange range = NSMakeRange(0, len);
    if (NULL != rangePointer) {
        NSRange r = *rangePointer;
        if (r.location == NSNotFound) {
            return nil;
        }
        
        range = NSIntersectionRange(r, range);
        if (range.location == NSNotFound) {
            return nil;
        }
        
        *rangePointer = range;
    }
    
    NSData *subData = data;
    if (range.location > 0 || NSMaxRange(range) < len) {
        subData = [NSData dataWithBytesNoCopy:((uint8_t *)data.bytes + range.location) length:range.length freeWhenDone:NO];
    }

    TCRangeInputStream *stream = [self inputStreamWithData:subData];
    stream.range = range;
    stream.rawData = data;
    return stream;
}

+ (nullable instancetype)inputStreamWithFileURL:(NSURL *)url range:(NSRangePointer _Nullable)rangePointer
{
    NSCParameterAssert(url);
    NSRange range = NSMakeRange(0, (NSUInteger)url.contentSizeInByte);
    if (NULL != rangePointer) {
        NSRange r = *rangePointer;
        if (r.location == NSNotFound) {
            return nil;
        }
        
        range = NSIntersectionRange(r, range);
        if (range.location == NSNotFound) {
            return nil;
        }
        
        *rangePointer = range;
    }
    
    TCRangeInputStream *stream = [self.alloc init];
    stream.range = range;
    stream.innerFileURL = url;
    return stream;
}

+ (nullable instancetype)inputStreamWithFile:(FILE *)file size:(NSUInteger)size range:(NSRangePointer _Nullable)rangePointer
{
    NSCParameterAssert(file);
    NSRange range = NSMakeRange(0, size);
    if (NULL != rangePointer) {
        NSRange r = *rangePointer;
        if (r.location == NSNotFound) {
            return nil;
        }
        
        range = NSIntersectionRange(r, range);
        if (range.location == NSNotFound) {
            return nil;
        }
        
        *rangePointer = range;
    }
    
    TCRangeInputStream *stream = [self.alloc init];
    stream.range = range;
    stream.rawFile = file;
    return stream;
}

//+ (nullable instancetype)inputStreamWithFileDescriptor:(int)file size:(NSUInteger)size range:(NSRangePointer _Nullable)rangePointer
//{
//    NSRange range = NSMakeRange(0, size);
//    if (NULL != rangePointer) {
//        NSRange r = *rangePointer;
//        if (r.location == NSNotFound) {
//            return nil;
//        }
//
//        range = NSIntersectionRange(r, range);
//        if (range.location == NSNotFound) {
//            return nil;
//        }
//
//        *rangePointer = range;
//    }
//
//    TCRangeInputStream *stream = [self.alloc init];
//    stream.range = range;
//    stream.rawFile = file;
//    return stream;
//}

- (void)dealloc
{
    if (NULL != _handle) {
        [self close];
    }
}

- (void)open
{
    NSCParameterAssert(nil != _innerFileURL || nil != _rawData || NULL != _rawFile);
    if (nil != _innerFileURL || NULL != _rawFile) {
        if (NULL != _handle || NSStreamStatusNotOpen != self.innerStatus) {
            return;
        }
        
        self.innerStatus = NSStreamStatusOpening;
        NSError *err = nil;
        if (NULL != _rawFile) {
            _handle = _rawFile;
        } else {
            _handle = fopen(_innerFileURL.fileSystemRepresentation, "r");
        }
        if (NULL != _handle) {
            if (_range.location > 0 || _rawFile == _handle) {
                if (0 != fseek(_handle, (long)_range.location, SEEK_SET)) {
                    err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
                    NSCParameterAssert(nil == err);
                    if (_rawFile != _handle) {
                        fclose(_handle);
                    }
                    _handle = NULL;
                }
            }
        } else {
            err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        }
        if (NULL == _handle) {
            _streamError = err;
            self.innerStatus = NSStreamStatusError;
        } else {
            self.innerStatus = NSStreamStatusOpen;
        }
    } else {
        [super open];
    }
}

- (void)close
{
    if (NULL != _handle) {
        self.innerStatus = NSStreamStatusClosed;
        if (_rawFile != _handle) {
            fclose(_handle);
        }
        _handle = NULL;
    }
    
    if (nil != _rawData) {
        [super close];
    }
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    if (NULL == _handle) {
        if ((nil != _innerFileURL || NULL != _rawFile) && !self.hasBytesAvailable) {
            return 0;
        }
        return [super read:buffer maxLength:len];
    }
    
    self.reading = YES;
    BOOL readEnd = self.readLen + len >= _range.length;
    NSUInteger toReadLen = readEnd ? (_range.length - self.readLen) : len;
    
    size_t ret_len = fread(buffer, 1, toReadLen, _handle);
    NSCParameterAssert(ret_len > 0);
    self.readLen += ret_len;
    if (ret_len < toReadLen) {
        _streamError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        self.innerStatus = NSStreamStatusError;
        if (_rawFile != _handle) {
            fclose(_handle);
        }
        _handle = NULL;
    } else if (readEnd) {
        self.innerStatus = NSStreamStatusAtEnd;
        if (_rawFile != _handle) {
            fclose(_handle);
        }
        _handle = NULL;
    }
    self.reading = NO;
    return (NSInteger)ret_len;
}

- (BOOL)getBuffer:(uint8_t**)buffer length:(NSUInteger*)len
{
    if (nil == _handle) {
        if ((nil != _innerFileURL || NULL != _rawFile) && !self.hasBytesAvailable) {
            return NO;
        }
        return [super getBuffer:buffer length:len];
    }
    
    // TODO: read
    return NO;
}

- (BOOL)hasBytesAvailable
{
    if (nil != _innerFileURL || NULL != _rawFile) {
        if (NSStreamStatusError == self.innerStatus || NSStreamStatusAtEnd == self.innerStatus) {
            return NO;
        }
        return self.readLen < _range.length;
    }
    return [super hasBytesAvailable];
}

- (NSStreamStatus)streamStatus
{
    if (nil != _innerFileURL || NULL != _rawFile) {
        if (self.reading) {
            // This status would be returned if code on another thread were to call streamStatus on the stream while a read:maxLength: call (NSInputStream) was in progress
            return NSStreamStatusReading;
        }
        return self.innerStatus;
    }
    return [super streamStatus];
}

- (NSError *)streamError
{
    return _streamError ?: [super streamError];
}

@end
