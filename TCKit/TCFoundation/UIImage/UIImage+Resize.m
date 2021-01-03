 //
//  UIImage+Resize.m
//  TCKit
//
//  Created by dake on 13-12-12.
//  Copyright (c) 2013年 dake. All rights reserved.
//


#import "UIImage+Resize.h"
#import "UIImage+CGImage.h"

#import <ImageIO/ImageIO.h>
//#import <AssetsLibrary/AssetsLibrary.h>
#import <Accelerate/Accelerate.h>

#if ! __has_feature(objc_arc)
#error this file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

static NSInteger const kTCWidthPixelAlign = 8;

size_t TC_FixedWidth(size_t width)
{
    return width > kTCWidthPixelAlign * 10 ? (width - width % kTCWidthPixelAlign) : width;
}


static CGImageRef TC_CGImageCreateOrientationUp(UIImage *img, CGBitmapInfo destBitmapInfo)
{
    CGSize pixelSize = CGSizeMake(img.size.width * img.scale, img.size.height * img.scale);
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    UIImageOrientation orientation = img.imageOrientation;
    switch (orientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, pixelSize.width, pixelSize.height);
            transform = CGAffineTransformRotate(transform, (CGFloat)M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, pixelSize.width, 0);
            transform = CGAffineTransformRotate(transform, (CGFloat)M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, pixelSize.height);
            transform = CGAffineTransformRotate(transform, (CGFloat)-M_PI_2);
            break;
        default:
            break;
    }
    
    switch (orientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, pixelSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, pixelSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    if (CGAffineTransformIsIdentity(transform)) {
        return CGImageRetain(img.CGImage);
    }
    
    CGImageRef imageRef = img.CGImage;
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, (size_t)pixelSize.width, (size_t)pixelSize.height, 8, ((size_t)pixelSize.width) * 4, colorSpace, destBitmapInfo);
    CGColorSpaceRelease(colorSpace);
    CGContextConcatCTM(ctx, transform);
    
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationDefault);
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return cgimg;
}

@implementation UIImage (Resize)


- (UIImage *)fixOrientationToUpAndBGRA
{
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(self.CGImage);
    
    if ([UIImage isDefaultBitMapOrder:bitmapInfo] && self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    CGContextRef ctx = [UIImage createImageContextWithImage:self];
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    UIImage *resutImg = [UIImage imageWithCGImage:cgimg scale:self.scale orientation:UIImageOrientationUp];
    CGImageRelease(cgimg);
    
#ifndef TC_IOS_PUBLISH
    bitmapInfo = CGImageGetBitmapInfo(resutImg.CGImage);
    if (![UIImage isDefaultBitMapOrder:bitmapInfo] || resutImg.imageOrientation != UIImageOrientationUp) {
        NSCAssert(false, @"input image is not BGRA");
    }
#endif
    return resutImg;
}

- (UIImage *)fixOrientationToUp
{
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    CGImageRef cgimg = TC_CGImageCreateOrientationUp(self, CGImageGetBitmapInfo(self.CGImage));
    UIImage *resutImg = [UIImage imageWithCGImage:cgimg scale:self.scale orientation:UIImageOrientationUp];
    CGImageRelease(cgimg);
    
    return resutImg;
}


+ (CGSize)calculateSize:(CGSize)srcSize scaleToPixel:(CGFloat)pixelSize maxWidth:(NSInteger)maxWidth
{
    CGFloat width = srcSize.width;
    CGFloat height = srcSize.height;
    
    CGFloat ratio = (CGFloat)sqrt(pixelSize/(width * height));
    CGFloat w = width;
    CGFloat h = height;
    
//    if (ratio < 1.0f) {
        w *= ratio;
        h *= ratio;
//    }
    
    CGFloat bigger = MAX(w, h);
    if (bigger > maxWidth) {
        CGFloat ratio2 = maxWidth / bigger;
        w *= ratio2;
        h *= ratio2;
    }
    
    size_t fix_w = TC_FixedWidth((size_t)w);
    size_t fix_h = (size_t)(h / w * fix_w);
    
    return CGSizeMake(fix_w, fix_h);
}

- (CGSize)calculateSizeScaleToPixel:(CGFloat)pixelSize maxWidth:(NSInteger)maxWidth
{
    CGSize size = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
    if (maxWidth == NSIntegerMax && ABS(size.width * size.height - pixelSize) <= 2.0f) {
        return size;
    }
    return [self.class calculateSize:size scaleToPixel:pixelSize maxWidth:maxWidth];
}

- (UIImage *)scaleToPixel:(CGFloat)pixelSize maxWidth:(NSInteger)maxWidth
{
    CGSize size = [self calculateSizeScaleToPixel:pixelSize maxWidth:maxWidth];
    
//    if (self.size.width * self.scale <= size.width) {
//        // FIXME: 原图width 可能不是 8 像素对齐
//        return self;
//    }
    
    CGFloat w = CGImageGetWidth(self.CGImage);
    CGFloat h = CGImageGetHeight(self.CGImage);
    
    CGSize rawSize;
    if (w >= h) {
        rawSize.width = MAX(size.width, size.height);
        rawSize.height = MIN(size.width, size.height);
    } else {
        rawSize.width = MIN(size.width, size.height);
        rawSize.height = MAX(size.width, size.height);
    }
    
    CGContextRef ctx = [UIImage createImageContext:rawSize];
    CGRect rect = TC_CGRectFloorIntegral(CGRectMake(0, 0, rawSize.width, rawSize.height));
    if (rect.size.width * rect.size.height > 1024 * 1024) {
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    }
    
    CGContextDrawImage(ctx, rect, self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    UIImage *scaledImage = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imgRef);
    
    return scaledImage;
}

- (UIImage *)scaleToPixel:(CGFloat)pixelSize
{
    return [self scaleToPixel:pixelSize maxWidth:NSIntegerMax];
}

- (UIImage *)scaleToMinSize:(CGFloat)minSize
{
    return [self scaleToMinSize:minSize pixelAlign:YES];
}

- (UIImage *)scaleToMinSize:(CGFloat)minSize pixelAlign:(BOOL)pixelAlign
{
    CGFloat width = self.size.width * self.scale;
    CGFloat height = self.size.height * self.scale;
    CGFloat ratio = minSize / MIN(width, height);
    
    if (ABS(ratio - 1.0f) <= 1e-4) {
        return self;
    }
    
    width *= ratio;
    height *= ratio;
    
    CGFloat w = CGImageGetWidth(self.CGImage);
    CGFloat h = CGImageGetHeight(self.CGImage);
    
    CGSize rawSize;
    if (w >= h) {
        rawSize.width = MAX(width, height);
        rawSize.height = MIN(width, height);
    } else {
        rawSize.width = MIN(width, height);
        rawSize.height = MAX(width, height);
    }
    
    if (pixelAlign) {
        size_t fix_w = TC_FixedWidth((size_t)rawSize.width);
        size_t fix_h = (size_t)(rawSize.height / rawSize.width * fix_w);
        rawSize = CGSizeMake(fix_w, fix_h);
    }
    
    CGContextRef ctx = [UIImage createImageContext:rawSize];
    CGRect rect = TC_CGRectFloorIntegral(CGRectMake(0, 0, rawSize.width, rawSize.height));
    if (rect.size.width * rect.size.height > 1024 * 1024) {
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    }
    CGContextDrawImage(ctx, rect, self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    UIImage *scaledImage = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imgRef);
    
    return scaledImage;
}

- (UIImage *)scaleAndCutToSquare:(CGFloat)asize
{
    return [self scaleAndCutToSize:CGSizeMake(asize, asize)];
}

- (UIImage *)scaleAndCutToSize:(CGSize)size
{
    CGSize imgSize = self.size;
    if (imgSize.width <= 0 || imgSize.height <= 0) {
        return nil;
    }
    
    BOOL horizon = imgSize.width / imgSize.height >= 1.0f;

    CGFloat scale = self.scale;
    CGSize dstSize = CGSizeMake(size.width * scale, size.height * scale);
    UIImage *img = [self scaleToMinSize:horizon ? dstSize.height : dstSize.width pixelAlign:NO];
    if (nil == img) {
        return nil;
    }
    
    CGSize pixelSize = img.pixelSize;
    CGFloat width = pixelSize.width;
    CGFloat height = pixelSize.height;
    
    CGFloat x = (width - dstSize.width) * 0.5f;
    if (x >= 0) {
        width = dstSize.width;
    } else {
        x = 0;
    }
    
    CGFloat y = (height - dstSize.height) * 0.5f;
    if (y >= 0) {
        height = dstSize.height;
    } else {
        y = 0;
    }
    
    scale = img.scale;
    return [img cropInRect:CGRectMake(x / scale, y / scale, width / scale, height / scale)];
}


// 根据 orientation 映射到 CGImage的 pixel rect
- (CGRect)calibrateRect:(CGRect)rect inImage:(UIImage *)image
{
    CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
    
    // 左下角为旋转原点
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            
            break;
            
        case UIImageOrientationDown:

            transform = CGAffineTransformTranslate(transform, width, height);
            transform = CGAffineTransformRotate(transform, (CGFloat)M_PI);
            break;
            
        case UIImageOrientationLeft: // rotate right
            
            transform = CGAffineTransformTranslate(transform, width, 0.0);
            transform = CGAffineTransformRotate(transform, (CGFloat)M_PI_2);
            break;
            
        case UIImageOrientationRight: // rotate left

            transform = CGAffineTransformTranslate(transform, 0.0, height);
            transform = CGAffineTransformRotate(transform, (CGFloat)-M_PI_2);
            break;
            
        case UIImageOrientationUpMirrored: // flip H
        
            transform = CGAffineTransformTranslate(transform, width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDownMirrored: // flip V
        
            transform = CGAffineTransformTranslate(transform, 0.0, height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: // flip V, rotate right
        
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            transform = CGAffineTransformRotate(transform, (CGFloat)-M_PI_2);
            break;
            
        case UIImageOrientationRightMirrored: // flip H, rotate right
        
            transform = CGAffineTransformTranslate(transform, width, height);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, (CGFloat)-M_PI_2);
            break;
            
        default:
            break;
    }

    return TC_CGRectFloorIntegral(CGRectApplyAffineTransform(rect, transform));
}

- (UIImage *)cropInRect:(CGRect)rect
{
    CGRect pixelRect = rect;
    CGFloat scale = self.scale;
    pixelRect.origin.x *= scale;
    pixelRect.origin.y *= scale;
    pixelRect.size.width *= scale;
    pixelRect.size.height *= scale;
    
    CGRect fixRect = [self calibrateRect:pixelRect inImage:self];
    CGSize size = CGSizeMake(CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage));
    CGContextRef ctx = [UIImage createImageContext:fixRect.size];
    if (fixRect.size.width * fixRect.size.height <= 256 * 256) {
        CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    } else {
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    }
    CGContextDrawImage(ctx, CGRectMake(-fixRect.origin.x, fixRect.origin.y+fixRect.size.height-size.height, size.width, size.height), self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    UIImage *output = self;
    if (NULL != imgRef && imgRef != self.CGImage) {
        output = [UIImage imageWithCGImage:imgRef scale:output.scale orientation:output.imageOrientation];
    }
    
    CGImageRelease(imgRef);
    
    return output;
}

- (UIImage *)resizedImageToSize:(CGSize)dstSize
{
	CGImageRef imgRef = self.CGImage;
	// the below values are regardless of orientation : for UIImages from Camera, width>height (landscape)
	CGSize  srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef)); // not equivalent to self.size (which is dependant on the imageOrientation)!
    
    /* Don't resize if we already meet the required destination size. */
    if (CGSizeEqualToSize(srcSize, dstSize)) {
        return self;
    }
    
	// We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    UIImageOrientation orientation = self.imageOrientation;
    
    switch (orientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcSize.width, srcSize.height);
            transform = CGAffineTransformRotate(transform, (CGFloat)M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, srcSize.width, 0);
            transform = CGAffineTransformRotate(transform, (CGFloat)M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, srcSize.height);
            transform = CGAffineTransformRotate(transform, (CGFloat)-M_PI_2);
            break;
        default:
            break;
    }
    
    switch (orientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, srcSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
	// The actual resize: draw the image on a new context, applying a transform matrix
	CGContextRef context = [UIImage createImageContext:dstSize];
    if (NULL == context) {
        return nil;
    }
    
    CGFloat scaleRatio = dstSize.width / srcSize.width;
	CGContextScaleCTM(context, scaleRatio, scaleRatio);
	CGContextConcatCTM(context, transform);
    
	// we use srcSize (and not dstSize) as the size to specify is in user space (and we use the CTM to apply a scaleRatio)
	CGContextDrawImage(context, CGRectMake(0, 0, srcSize.width, srcSize.height), imgRef);
    CGImageRef resImgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *resizedImage = self;
    if (NULL != resImgRef) {
        resizedImage = [UIImage imageWithCGImage:resImgRef scale:self.scale orientation:UIImageOrientationUp];
        CGImageRelease(resImgRef);
    }
    
	return resizedImage;
}

- (UIImage *)resizedImageToRatio:(CGFloat)ratio
{
    CGSize pixelSize = self.pixelSize;
    CGFloat h1 = MAX(pixelSize.width, pixelSize.height);
    CGFloat w1 = h1 * ratio;
    
    CGContextRef ctx = [UIImage createImageContext:CGSizeMake(w1, h1)];
    CGRect rect = CGRectMake(0, 0, w1, h1);
    CGContextDrawImage(ctx, rect, self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    UIImage *scaledImage = self;
    if (NULL != imgRef) {
        scaledImage = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
        CGImageRelease(imgRef);
    }
    
    return scaledImage;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0

+ (UIImage *)imageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation withMaxSide:(CGFloat)size
{
    UIImage *result = nil;
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc((sizeof(uint8_t) * (size_t)assetRepresentation.size));
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:(NSUInteger)assetRepresentation.size error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];
        
        free(buffer);
    }
    
    if (data.length > 0) {
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
        NSMutableDictionary *options = NSMutableDictionary.dictionary;
        options[(NSString *)kCGImageSourceShouldAllowFloat] = (NSNumber *)kCFBooleanTrue;
        options[(NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = (NSNumber *)kCFBooleanTrue;
        options[(NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(size);
        //[options setObject:(id)kCFBooleanTrue forKey:(__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform];
        
        CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
        if (NULL != imageRef) {
            result = [UIImage imageWithCGImage:imageRef scale:assetRepresentation.scale orientation:(UIImageOrientation)assetRepresentation.orientation];
            CGImageRelease(imageRef);
        }
        
        if (NULL != sourceRef) {
            CFRelease(sourceRef);
        }
    }
    
    return result;
}

#endif

- (NSData *)JPGDataForCompression:(NSUInteger)bytes
{
    if (bytes < 1) {
        return nil;
    }
    
    CGFloat compressQuality = 1.0f;
    static const CGFloat kMinQuality = 0.4f;
    static const CGFloat kQualityDelta = 0.2f;
    
    NSData *data = nil;
    
    do {
        @autoreleasepool {
            data = UIImageJPEGRepresentation(self.fixOrientationToUp, compressQuality);
            if (data.length <= bytes) {
                break;
            }
            compressQuality = MAX(compressQuality - kQualityDelta, kMinQuality);
        }
    } while (compressQuality > kMinQuality);
    
    if (nil != data && data.length > bytes) {
        data = nil;
    }
    
    return data;
}

- (UIImage *)blurImage
{
    size_t w = CGImageGetWidth(self.CGImage);
    size_t h = CGImageGetHeight(self.CGImage);
    return [self blurImageWithMinSideSize:(size_t)(MIN(w, h) * 0.5f)];
}

- (UIImage *)blurImageWithMinSideSize:(size_t)minSize
{
    if (minSize <= 0) {
        return nil;
    }
    
    CGImageRef img = self.CGImage;
    size_t w = CGImageGetWidth(img);
    size_t h = CGImageGetHeight(img);
    
    // scale image to smaller
    vImage_Buffer saBuffer;
    if (w > h) {
        saBuffer.height = minSize;
        saBuffer.width = (size_t)(minSize * w * 1.0f / h);
    } else {
        saBuffer.width = minSize;
        saBuffer.height = (size_t)(minSize * h * 1.0f / w);
    }
    saBuffer.rowBytes = saBuffer.width * 4;
    saBuffer.data = malloc(saBuffer.rowBytes * saBuffer.height);
    if (saBuffer.data == NULL) {
        return nil;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(saBuffer.data,
                                                    saBuffer.width,
                                                    saBuffer.height,
                                                    8,
                                                    saBuffer.rowBytes,
                                                    colorSpace,
                                                    [UIImage defaultBitMapOrder]);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, saBuffer.width, saBuffer.height), img);
    CGContextRelease(contextRef);
    
    
    // fill the top and bottom
    
    vImage_Buffer inBuffer;
    if (saBuffer.width > saBuffer.height) {
        inBuffer.width = saBuffer.width;
        inBuffer.height = (typeof(inBuffer.height))(saBuffer.height / 0.75f);
    } else {
        if (saBuffer.height * 0.75f - saBuffer.width < 0) {
            inBuffer.height = saBuffer.height;
            inBuffer.width = saBuffer.width;
        } else {
            inBuffer.height = saBuffer.height;
            inBuffer.width = (typeof(inBuffer.width))(saBuffer.height * 0.75f);
        }
    }
    inBuffer.rowBytes = inBuffer.width * 4;
    inBuffer.data = malloc(inBuffer.rowBytes * inBuffer.height);
    if (inBuffer.data == NULL) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    
    vImageScale_ARGB8888(&saBuffer, &inBuffer, NULL, kvImageEdgeExtend);
    free(saBuffer.data);
    saBuffer.data = NULL;
    
    // create vImage_Buffer for output
    vImage_Buffer outBuffer = inBuffer;
    outBuffer.data = malloc(outBuffer.rowBytes * outBuffer.height);
    if (outBuffer.data == NULL) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    
    // perform convolution
    static CGFloat const blur = 1.f;
    uint32_t boxSize = (uint32_t)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    vImage_Error error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend)
    ?: vImageBoxConvolve_ARGB8888(&outBuffer, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend)
    ?: vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    free(inBuffer.data);
    inBuffer.data = NULL;
    if (error) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             [UIImage defaultBitMapOrder]);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    free(outBuffer.data);
    
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    

    return returnImage;
}

@end
