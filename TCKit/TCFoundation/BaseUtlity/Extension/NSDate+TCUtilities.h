/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook 3.x and beyond
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, TCDateFormatType) {
    kTCDateFormatTypeISO8601,
    kTCDateFormatTypeATOM = kTCDateFormatTypeISO8601, // colon
    kTCDateFormatTypeW3C = kTCDateFormatTypeATOM, // colon
    kTCDateFormatTypeRFC3339 = kTCDateFormatTypeATOM,
    
    kTCDateFormatTypeRFC822,
    kTCDateFormatTypeRFC2822 = kTCDateFormatTypeRFC822,
    kTCDateFormatTypeRFC1123 = kTCDateFormatTypeRFC2822,
    kTCDateFormatTypeRFCRSS = kTCDateFormatTypeRFC1123,
    
    kTCDateFormatTypeRFC850,
    kTCDateFormatTypeASCTIME,
    kTCDateFormatTypeUnix,
    kTCDateFormatTypeRuby,
};

NS_ASSUME_NONNULL_BEGIN


/*
 2010-07-09T16:13:30+12:00
 2011-01-11T11:11:11+0000
 2011-01-26T19:06:43Z
 */
extern NSString *const kTCDateISO8601ReadFormat;

/*
 2010-07-09T16:13:30.3+12:00
 2011-01-11T11:11:11.322+0000
 2011-01-26T19:06:43.554Z
 */
extern NSString *const kTCDateISO8601SubReadFormat;

/*
 2011-01-26T19:06:43Z
 */
extern NSString *const kTCDateISO8601WriteZuluFormat;

/*
 2011-01-26T19:06:43.554Z
 */
extern NSString *const kTCDateISO8601WriteSubZuluFormat;

/*
 2010-07-09T16:13:30+0000
 */
extern NSString *const kTCDateISO8601WriteZoneFormat;

/*
 2011-01-11T11:11:11.322+0000
 */
extern NSString *const kTCDateISO8601WriteSubZoneFormat;

/*
 2010-07-09T16:13:30+00:00
 ATOM
 */
extern NSString *const kTCDateISO8601WriteColonZoneFormat;

/*
 2011-01-11T11:11:11.322+00:00
 */
extern NSString *const kTCDateISO8601WriteSubColonZoneFormat;


/*
 Wed, 02 Oct 2002 08:00:00 EST
 Wed, 02 Oct 2002 13:00:00 GMT
 Wed, 02 Oct 2002 15:00:00 +0200
 
 
 With the short timezone formats as specified by z (=zzz) or v (=vvv), there can be a lot of ambiguity. For example, "ET" for Eastern Time" could apply to different time zones in many different regions. To improve formatting and parsing reliability, the short forms are only used in a locale if the "cu" (commonly used) flag is set for the locale. Otherwise, only the long forms are used (for both formatting and parsing).
 
 For the "en" locale (= "en_US"), the cu flag is set for metazones such as Alaska, America_Central, America_Eastern, America_Mountain, America_Pacific, Atlantic, Hawaii_Aleutian, and GMT. It is not set for Europe_Central.
 
 However, for the "en_GB" locale, the cu flag is set for Europe_Central.
 
 So a formatter set for short timezone style "z" or "zzz" and locale "en" or "en_US" will not parse "CEST" or "CET", but if the locale is instead set to "en_GB" it will parse those. The "GMT" style will be parsed by all.
 
 If the formatter is set for the long timezone style "zzzz", and the locale is any of "en", "en_US", or "en_GB", then any of the following will be parsed, because they are unambiguous: "Pacific Daylight Time" "Central European Summer Time" "Central European Time"
 
 */
extern NSString *const kTCDateRFC1123Format;

/*
 Monday, 15-Aug-05 15:52:01 UTC
 */
extern NSString *const kTCDateRFC850Format;

/*
 Wed Oct 2 15:00:00 2002
 */
extern NSString *const kTCDateASCFormat;

/*
 Mon Jan 2 15:04:05 MST 2006
 Mon Jun 09 21:59:59 UTC 2025
 */
extern NSString *const kTCDateUnixFormat;

/*
 Mon Jan 02 15:04:05 -0700 2006
 */
extern NSString *const kTCDateRubyFormat;

@interface NSDateFormatter (TCHelper)

- (void)updateFormatForType:(TCDateFormatType)type fmt:(NSString *)fmt timeZone:(NSTimeZone *_Nullable)timeZone;

@end


extern NSInteger const D_MINUTE;
extern NSInteger const D_HOUR;
extern NSInteger const D_DAY;
extern NSInteger const D_WEEK;
extern NSInteger const D_YEAR;

@interface NSDate (TCUtilities)

+ (NSCalendar *)currentCalendar; // avoid bottlenecks
+ (NSDateFormatter *)dateFormatter;


// Relative dates from the current date
+ (instancetype)dateTomorrow;
+ (instancetype)dateYesterday;
+ (instancetype)dateWithDaysFromNow:(NSInteger)days;
+ (instancetype)dateWithDaysBeforeNow:(NSInteger)days;
+ (instancetype)dateWithHoursFromNow:(NSInteger)dHours;
+ (instancetype)dateWithHoursBeforeNow:(NSInteger)dHours;
+ (instancetype)dateWithMinutesFromNow:(NSInteger)dMinutes;
+ (instancetype)dateWithMinutesBeforeNow:(NSInteger)dMinutes;

// Short string utilities
- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle;
- (NSString *)stringWithFormat:(NSString *)format;

@property (nonatomic, readonly) NSString *shortString;
@property (nonatomic, readonly) NSString *shortDateString;
@property (nonatomic, readonly) NSString *shortTimeString;
@property (nonatomic, readonly) NSString *mediumString;
@property (nonatomic, readonly) NSString *mediumDateString;
@property (nonatomic, readonly) NSString *mediumTimeString;
@property (nonatomic, readonly) NSString *longString;
@property (nonatomic, readonly) NSString *longDateString;
@property (nonatomic, readonly) NSString *longTimeString;

// Comparing dates
- (BOOL)isEqualToDateIgnoringTime:(NSDate *)aDate;

- (BOOL)isToday;
- (BOOL)isTomorrow;
- (BOOL)isYesterday;

- (BOOL)isSameWeekAsDate:(NSDate *)aDate;
- (BOOL)isThisWeek;
- (BOOL)isNextWeek;
- (BOOL)isLastWeek;

- (BOOL)isSameMonthAsDate:(NSDate *)aDate;
- (BOOL)isThisMonth;
- (BOOL)isNextMonth;
- (BOOL)isLastMonth;

- (BOOL)isSameYearAsDate:(NSDate *)aDate;
- (BOOL)isThisYear;
- (BOOL)isNextYear;
- (BOOL)isLastYear;

- (BOOL)isEarlierThanDate:(NSDate *)aDate;
- (BOOL)isLaterThanDate:(NSDate *)aDate;

- (BOOL)isInFuture;
- (BOOL)isInPast;

// Date roles
- (BOOL)isTypicallyWorkday;
- (BOOL)isTypicallyWeekend;

// Adjusting dates
- (instancetype)dateByAddingYears:(NSInteger)dYears;
- (instancetype)dateBySubtractingYears:(NSInteger)dYears;
- (instancetype)dateByAddingMonths:(NSInteger)dMonths;
- (instancetype)dateBySubtractingMonths:(NSInteger)dMonths;
- (instancetype)dateByAddingDays:(NSInteger)dDays;
- (instancetype)dateBySubtractingDays:(NSInteger)dDays;
- (instancetype)dateByAddingHours:(NSInteger)dHours;
- (instancetype)dateBySubtractingHours:(NSInteger)dHours;
- (instancetype)dateByAddingMinutes:(NSInteger)dMinutes;
- (instancetype)dateBySubtractingMinutes:(NSInteger)dMinutes;

// Date extremes
- (instancetype)dateAtStartOfYear;
- (instancetype)dateAtStartOfMonth;
- (instancetype)dateAtStartOfDay;
- (instancetype)dateAtEndOfDay;

// Retrieving intervals
- (NSInteger)minutesAfterDate:(NSDate *)aDate;
- (NSInteger)minutesBeforeDate:(NSDate *)aDate;
- (NSInteger)hoursAfterDate:(NSDate *)aDate;
- (NSInteger)hoursBeforeDate:(NSDate *)aDate;
- (NSInteger)daysAfterDate:(NSDate *)aDate;
- (NSInteger)daysBeforeDate:(NSDate *)aDate;
- (NSInteger)distanceInDaysToDate:(NSDate *)anotherDate;

// Decomposing dates
@property (nonatomic, readonly) NSInteger nearestHour;
@property (nonatomic, readonly) NSInteger hour;
@property (nonatomic, readonly) NSInteger minute;
@property (nonatomic, readonly) NSInteger seconds;
@property (nonatomic, readonly) NSInteger nanosecond;
@property (nonatomic, readonly) NSInteger day;
@property (nonatomic, readonly) NSInteger month;
@property (nonatomic, readonly) NSInteger weekOfYear;
@property (nonatomic, readonly) NSInteger weekOfMonth;
@property (nonatomic, readonly) NSInteger weekday;
@property (nonatomic, readonly) NSInteger nthWeekday; // e.g. 2nd Tuesday of the month == 2
@property (nonatomic, readonly) NSInteger year;

@end

NS_ASSUME_NONNULL_END
