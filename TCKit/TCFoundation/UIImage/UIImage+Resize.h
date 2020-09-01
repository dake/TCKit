//
//  UIImage+Resize.h
//  TCKit
//
//  Created by dake on 13-12-12.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_INLINE CGRect TC_CGRectFloorIntegral(CGRect rect)
{
    return CGRectMake((size_t)rect.origin.x, (size_t)rect.origin.y, (size_t)rect.size.width, (size_t)rect.size.height);
}

// width 8对齐
extern size_t TC_FixedWidth(size_t width);


@class ALAssetRepresentation;

@interface UIImage (Resize)

- (UIImage *)fixOrientationToUpAndBGRA;

- (UIImage *)fixOrientationToUp;


/**
 @brief	比例缩放图片至希望的像素 (有最大边限制)
 
 @param pixelSize [IN] 像素大小
 @param maxWidth [IN] 每边最大像素大小
 
 @return 比例缩放的结果图，同原图imageOrientaion一致
 */
- (UIImage *)scaleToPixel:(CGFloat)pixelSize maxWidth:(NSInteger)maxWidth;

- (CGSize)calculateSizeScaleToPixel:(CGFloat)pixelSize maxWidth:(NSInteger)maxWidth;
+ (CGSize)calculateSize:(CGSize)srcSize scaleToPixel:(CGFloat)pixelSize maxWidth:(NSInteger)maxWidth;

/**
 @brief	比例缩放图片至希望的像素
 
 @param pixelSize [IN] 像素大小
 
 @return 比例缩放的结果图，同原图imageOrientaion一致
 */
- (UIImage *)scaleToPixel:(CGFloat)pixelSize;

/**
 @brief	比例缩放至小边 <= minSize
 
 @param minSize [IN] 希望的小边大小，单位：像素
 
 @return  原图小边 <= minSize 返回原图，否则返回比例缩放的结果图，同原图imageOrientaion一致
 */
- (UIImage *)scaleToMinSize:(CGFloat)minSize;
- (UIImage *)scaleToMinSize:(CGFloat)minSize pixelAlign:(BOOL)pixelAlign;


/**
 @brief	缩放并裁减为方图
 以小边为基准缩放，居中裁减大边
 
 @param size [IN] 希望的方图大小， 单位：点
 
 @return 方图，同原图imageOrientaion一致
 */
- (UIImage *)scaleAndCutToSquare:(CGFloat)size;
- (UIImage *)scaleAndCutToSize:(CGSize)size;



/**
 @brief	裁出rect区域图片
 
 @param rect [IN] 裁减区域，单位：点
 
 @return 同原图imageOrientaion一致的结果图
 */
- (UIImage *)cropInRect:(CGRect)rect;

/**
 @brief	缩放至size尺寸图片
 
 @param dstSize [IN] 目标尺寸，单位：像素
 
 @return fix to UIImageOrientationUp
 */
- (UIImage *)resizedImageToSize:(CGSize)dstSize;

// ratio 宽高比
- (UIImage *)resizedImageToRatio:(CGFloat)ratio;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0

+ (UIImage *)imageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation withMaxSide:(CGFloat)size;

#endif



/**
 @brief	compress image to jpg data
 
 @param bytes [IN] <#bytes description#>
 
 @return nil if expected cmpression not archived
 */
- (NSData *)JPGDataForCompression:(NSUInteger)bytes;



- (UIImage *)blurImage;
- (UIImage *)blurImageWithMinSideSize:(size_t)minSize;

@end
