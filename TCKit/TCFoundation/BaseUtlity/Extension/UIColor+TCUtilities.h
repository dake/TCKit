// Erica Sadun 

// Thanks to Poltras, Millenomi, Eridius, Nownot, WhatAHam, jberry,
// and everyone else who helped out but whose name is inadvertantly omitted

/*
 BSD License.
 
 This work 'as-is' I provide.
 No warranty express or implied.
 I've done my best,
 to debug and test.
 Liability for damages denied.
 */

/*
 Current outstanding request list: (NONE)
 
 Requests recently added:
 Layton at PolarBearFarm - color descriptions 
 e.g. (UIColor.warmGrayWithHintOfBlueTouchOfRedAndSplashOfYellowColor)
 Added: Auto color descriptions, especially using xkcd 
 
 Kevin / Eridius 
 UIColor needs a method that takes 2 colors and gives a third complementary one
 new kevinColorWithColor: method

 Adjustable colors: brighter, cooler, warmer, etc.
 Added: Various tweakers, warmth property, temperature stuff 
 */

/*
 
 Update checklist:
 
 UInt32 -> uint32_t
 float -> CGFloat
 int -> NSInteger except w/ simple for loops
 fmax, fmin -> cgfmax, cgfmin
 unit clamping -> cgfunitclamp
 
 */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Color Space
extern CGColorSpaceRef tcDeviceRGBSpace(void);
extern CGColorSpaceRef tcDeviceGraySpace(void);

extern UIColor *tcRandomColor(void);
extern UIColor *tcInterpolateColors(UIColor *c1, UIColor *c2, CGFloat percent);

@interface UIColor (TCUtilities)

#ifndef __IPHONE_13_0

@property (class, nonatomic, readonly) UIColor *systemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *secondarySystemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *tertiarySystemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *secondarySystemGroupedBackgroundColor;
@property (class, nonatomic, readonly) UIColor *systemGroupedBackgroundColor;

@property (class, nonatomic, readonly) UIColor *separatorColor;
@property (class, nonatomic, readonly) UIColor *placeholderTextColor;


+ (UIColor *)colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *traitCollection))dynamicProvider;

#endif


+ (nullable instancetype)colorWithLight:(UIColor *_Nullable)light dark:(UIColor *_Nullable)dark;

#pragma mark - Color Wheel
+ (nullable UIImage *)colorWheelOfSize:(CGFloat)side border:(BOOL)yorn;

#pragma mark - Color Space
+ (NSString *)colorSpaceString:(CGColorSpaceModel)model;
@property (nonatomic, readonly) NSString *colorSpaceString;
@property (nonatomic, readonly) CGColorSpaceModel colorSpaceModel;
@property (nonatomic, readonly) BOOL canProvideRGBComponents;
@property (nonatomic, readonly) BOOL usesMonochromeColorspace;
@property (nonatomic, readonly) BOOL usesRGBColorspace;

#pragma mark - Color Conversion
+ (void)hue:(CGFloat)h saturation:(CGFloat)s brightness:(CGFloat)v toRed:(CGFloat *__nullable)pR green:(CGFloat *__nullable)pG blue:(CGFloat *__nullable)pB;
+ (void)red:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b toHue:(CGFloat *__nullable)pH saturation:(CGFloat *__nullable)pS brightness:(CGFloat *__nullable)pV;
extern void tcRGB2YUV_f(CGFloat r, CGFloat g, CGFloat b, CGFloat *__nullable y, CGFloat *__nullable u, CGFloat *__nullable v);
extern void tcYUV2RGB_f(CGFloat y, CGFloat u, CGFloat v, CGFloat *__nullable r, CGFloat *__nullable g, CGFloat *__nullable b);

//  public domain functions by Darel Rex Finley, 2006
extern void tcRGBtoHSP(CGFloat  R, CGFloat  G, CGFloat  B, CGFloat *H, CGFloat *S, CGFloat *P);
extern void tcHSPtoRGB(CGFloat  H, CGFloat  S, CGFloat  P, CGFloat *R, CGFloat *G, CGFloat *B);
@property (nonatomic, readonly) CGFloat perceivedBrightness;

#pragma mark - Color Components
// With the exception of -alpha, these properties will function
// correctly only if this color is an RGB or white color.
// In these cases, canProvideRGBComponents returns YES.
@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;
@property (nonatomic, readonly) CGFloat alpha;

@property (nonatomic, readonly) CGFloat premultipliedRed;
@property (nonatomic, readonly) CGFloat premultipliedGreen;
@property (nonatomic, readonly) CGFloat premultipliedBlue;

+ (UIColor *)colorWithCyan:(CGFloat)c magenta:(CGFloat)m yellow:(CGFloat)y black:(CGFloat)k;
- (void)toC:(CGFloat *__nullable)cyan toM:(CGFloat *__nullable)magenta toY:(CGFloat *__nullable)yellow toK:(CGFloat *__nullable)black;
- (void)toH:(CGFloat *__nullable)hue toW:(CGFloat *__nullable)white toB:(CGFloat *__nullable)black;

@property (nonatomic, readonly) CGFloat cyanChannel;
@property (nonatomic, readonly) CGFloat magentaChannel;
@property (nonatomic, readonly) CGFloat yellowChannel;
@property (nonatomic, readonly) CGFloat blackChannel;
@property (nonatomic, readonly) NSArray<NSNumber *> *cmyk;

@property (nonatomic, readonly) Byte redByte;
@property (nonatomic, readonly) Byte greenByte;
@property (nonatomic, readonly) Byte blueByte;
@property (nonatomic, readonly) Byte alphaByte;
@property (nonatomic, readonly) Byte whiteByte;
@property (nonatomic, readonly) NSData *colorBytes;
@property (nonatomic, readonly) NSData *premultipledColorBytes;

@property (nonatomic, readonly) CGFloat white;
@property (nonatomic, readonly) CGFloat luminance; // 0 ~ 1

@property (nonatomic, readonly) CGFloat hue; // [0, 360)
@property (nonatomic, readonly) CGFloat saturation;
@property (nonatomic, readonly) CGFloat brightness;


@property (nonatomic, readonly) uint32_t rgbHex;
@property (nonatomic, readonly) uint32_t rgbaHex;
@property (nonatomic, readonly) uint32_t argbHex;

// @[@(r), @(g), @(b), @(a)]
- (nullable NSArray<NSNumber *> *)arrayFromRGBAComponents;

// Return a grey-scale representation of the color
- (instancetype)colorByLuminanceMapping;

#pragma mark - Alternative Expression
// Grays return 0. Fully saturated return 1
@property (nonatomic, readonly) CGFloat colorfulness;
// Ranges from 0..1, cold (BLUE) to hot (YELLOW)
@property (nonatomic, readonly) CGFloat warmth;

#pragma mark - Building
// Build colors by comparison
- (instancetype)adjustWarmth:(CGFloat)delta;
- (instancetype)adjustBrightness:(CGFloat)delta;
- (instancetype)adjustSaturation:(CGFloat)delta;
- (instancetype)adjustHue:(CGFloat)delta;

#pragma mark - Sorting
// Sorting -- Natural sorting choices
- (NSComparisonResult)compareWarmth:(UIColor *)anotherColor;
- (NSComparisonResult)compareColorfulness:(UIColor *)anotherColor;
- (NSComparisonResult)compareHue:(UIColor *)anotherColor;
- (NSComparisonResult)compareSaturation:(UIColor *)anotherColor;
- (NSComparisonResult)compareBrightness:(UIColor *)anotherColor;

#pragma mark - Distance
// Color Distance
// return 0 ~ 1
- (CGFloat)luminanceDistanceFrom:(UIColor *)anotherColor;
// return 0 ~ √3
- (CGFloat)distanceFrom:(UIColor *)anotherColor;
- (BOOL)isEqualToColor:(UIColor *)anotherColor;

#pragma mark - Math
// Arithmetic operations on the color
- (nullable instancetype)colorByMultiplyingByRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (nullable instancetype)colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (nullable instancetype)colorByLighteningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (nullable instancetype)colorByDarkeningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

- (nullable instancetype)colorByMultiplyingBy:(CGFloat)f;
- (nullable instancetype)colorByAdding:(CGFloat)f;
- (nullable instancetype)colorByLighteningTo:(CGFloat)f;
- (nullable instancetype)colorByDarkeningTo:(CGFloat)f;

- (nullable instancetype)colorByMultiplyingByColor:(UIColor *)color;
- (nullable instancetype)colorByAddingColor:(UIColor *)color;
- (nullable instancetype)colorByLighteningToColor:(UIColor *)color;
- (nullable instancetype)colorByDarkeningToColor:(UIColor *)color;

- (nullable instancetype)colorByInterpolatingToColor:(UIColor *)color byFraction:(CGFloat)fraction;

- (instancetype)colorWithBrightness:(CGFloat)brightness;
- (instancetype)colorWithSaturation:(CGFloat)saturation;
- (instancetype)colorWithHue:(CGFloat)hue;

// Related colors
- (instancetype)contrastingColor;          // A good contrasting color: will be either black or white
- (instancetype)complementaryColor;        // A complementary color that should look good with this color
- (NSArray<UIColor *> *)triadicColors;                // Two colors that should look good with this color
- (NSArray<UIColor *> *)analogousColorsWithStepAngle:(CGFloat)stepAngle pairCount:(NSUInteger)pairs;    // Multiple pairs of colors

- (instancetype)kevinColorWithColor:(UIColor *)secondColor; // see Eridius request

#pragma mark - Strings
// String support
@property (nullable, nonatomic, readonly) NSString *stringValue;
// "12345FE8"
@property (nullable, nonatomic, readonly) NSString *rgbaHexStringValue;
@property (nullable, nonatomic, readonly) NSString *rgbHexStringValue;
@property (nullable, nonatomic, readonly) NSString *argbHexStringValue;
@property (nonatomic, readonly) NSString *valueString;
// {r, g, b, a} --> {0.3, 1, 0.5, 1}
+ (nullable instancetype)colorWithString:(NSString *)string;
// "0x65ce00" or "#0x65ce00" or "0x65ce00" or "#0x65ce00"
+ (nullable instancetype)colorWithRGBHexString:(NSString *)stringToConvert;
+ (nullable instancetype)colorWithRGBHex:(uint32_t)hex;

// "0xff65ce00" or "#0xff65ce00" or "ff65ce00" or "#ff65ce00"
+ (nullable instancetype)colorWithARGBHexString:(NSString *)stringToConvert;
+ (nullable instancetype)colorWithRGBAHexString:(NSString *)stringToConvert;
+ (nullable instancetype)colorWithARGBHex:(uint32_t)hex;
+ (nullable instancetype)colorWithRGBAHex:(uint32_t)hex;

#pragma mark - Temperature
// Temperature support -- preliminary
+ (instancetype)colorWithKelvin:(CGFloat)kelvin;
+ (NSDictionary<NSString *, NSNumber *> *)kelvinDictionary;
@property (nonatomic, readonly) CGFloat colorTemperature;

#pragma mark - Random
// Random Color
+ (instancetype)randomColor;
+ (instancetype)randomDarkColor:(CGFloat)scaleFactor;
+ (instancetype)randomLightColor:(CGFloat)scaleFactor;

@end

@interface UIImage (UIColor_Expanded)

@property (nullable, nonatomic, readonly) CGColorSpaceRef colorSpace;
@property (nonatomic, readonly) CGColorSpaceModel colorSpaceModel;
@property (nonatomic, readonly) NSString *colorSpaceString;

@end


#pragma mark - 

NS_INLINE UIColor *RGB_A(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/255.0f];
}

NS_INLINE UIColor *RGB(unsigned char r, unsigned char g, unsigned char b)
{
    return RGB_A(r, g, b, 255);
}

NS_INLINE UIColor *RGBHex(uint32_t hex)
{
    return [UIColor colorWithRGBHex:hex];
}

NS_INLINE UIColor *RGBAHex(uint32_t hex)
{
    return [UIColor colorWithRGBAHex:hex];
}

NS_INLINE UIColor *ARGBHex(uint32_t hex)
{
    return [UIColor colorWithARGBHex:hex];
}


NS_ASSUME_NONNULL_END
