/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct _TCSwizzleInput {
    __unsafe_unretained Class klass;
    SEL srcSel;
    SEL dstSel;
    BOOL isClassMethod;
    
} TCSwizzleInput;

extern BOOL tcSwizzleMethod(TCSwizzleInput input, _Nullable id block, _Nullable IMP *_Nullable origIMP, NSError **err);



@interface NSObject (TCUtilities)

@property (nullable, nonatomic, strong) id tcUserInfo;

+ (BOOL)tc_swizzle:(SEL)aSelector;
+ (BOOL)tc_swizzle:(SEL)aSelector to:(_Nullable SEL)bSelector;

+ (BOOL)currentClassRespondToSelector:(SEL)sel;
+ (BOOL)currentClassInstanceRespondToSelector:(SEL)sel;


// Selector Utilities
- (NSInvocation *)invocationWithSelectorAndArguments:(SEL)selector, ...;
- (BOOL)performSelector:(SEL)selector withReturnValueAndArguments:(void *)result, ...;
- (const char *)returnTypeForSelector:(SEL)selector;

// Request return value from performing selector
- (nullable id)objectByPerformingSelectorWithArguments:(SEL)selector, ...;
- (nullable __autoreleasing id)objectByPerformingSelector:(SEL)selector withObject:(_Nullable id)object1 andObject:(_Nullable id)object2;
- (id)objectByPerformingSelector:(SEL)selector withObject:(_Nullable id)object1;
- (id)objectByPerformingSelector:(SEL)selector;

// Delay Utilities
+ (void)performBlock:(dispatch_block_t)block afterDelay:(NSTimeInterval)delay;
- (void)performBlock:(dispatch_block_t)block afterDelay:(NSTimeInterval)delay;

- (void)performSelector:(SEL)selector withCPointer:(void *)cPointer afterDelay:(NSTimeInterval)delay;
- (void)performSelector:(SEL)selector withInt:(int)intValue afterDelay:(NSTimeInterval)delay;
- (void)performSelector:(SEL)selector withFloat:(float)floatValue afterDelay:(NSTimeInterval)delay;
- (void)performSelector:(SEL)selector withBool:(BOOL)boolValue afterDelay:(NSTimeInterval)delay;
- (void)performSelector:(SEL)selector afterDelay:(NSTimeInterval)delay;
- (void)performSelector:(SEL)selector withDelayAndArguments:(NSTimeInterval)delay, ...;


#pragma mark - DEBUG

#ifdef DEBUG

// Access to object essentials for run-time checks. Stored by class in dictionary.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *tc_selectors;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *tc_properties;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *tc_ivars;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *tc_protocols;


// Return all superclasses of object
+ (NSArray<Class> *)superclasses;
- (NSArray<Class> *)superclasses;

// Examine
+ (NSString *)dump;
- (NSString *)dump;

+ (NSArray<NSString *> *)getPropertyListForClass;

// Check for properties, ivar. Use respondsToSelector: and conformsToProtocol: as well
- (BOOL)hasProperty:(NSString *)propertyName;
- (BOOL)hasIvar:(NSString *)ivarName;
+ (BOOL)classExists:(NSString *)className;

// Choose the first selector that the object responds to
- (nullable SEL)chooseSelector:(SEL)aSelector, ...;

#endif

- (BOOL)isProperty:(NSString *)propertyName confirm:(Protocol *)protocol;

@end


#pragma mark - BKAssociatedObjects

@interface NSObject (BKAssociatedObjects)

/** Strongly associates an object with the reciever.
 
 The associated value is retained as if it were a property
 synthesized with `nonatomic` and `retain`.
 
 Using retained association is strongly recommended for most
 Objective-C object derivative of NSObject, particularly
 when it is subject to being externally released or is in an
 `NSAutoreleasePool`.
 
 @param value Any object.
 @param key A unique key pointer.
 */
- (void)bk_associateValue:(nullable id)value withKey:(const void *)key;

/** Strongly associates an object with the receiving class.
 
 @see associateValue:withKey:
 @param value Any object.
 @param key A unique key pointer.
 */
+ (void)bk_associateValue:(nullable id)value withKey:(const void *)key;

/** Strongly, thread-safely associates an object with the reciever.
 
 The associated value is retained as if it were a property
 synthesized with `atomic` and `retain`.
 
 Using retained association is strongly recommended for most
 Objective-C object derivative of NSObject, particularly
 when it is subject to being externally released or is in an
 `NSAutoreleasePool`.
 
 @see associateValue:withKey:
 @param value Any object.
 @param key A unique key pointer.
 */
- (void)bk_atomicallyAssociateValue:(nullable id)value withKey:(const void *)key;

/** Strongly, thread-safely associates an object with the receiving class.
 
 @see associateValue:withKey:
 @param value Any object.
 @param key A unique key pointer.
 */
+ (void)bk_atomicallyAssociateValue:(nullable id)value withKey:(const void *)key;

/** Associates a copy of an object with the reciever.
 
 The associated value is copied as if it were a property
 synthesized with `nonatomic` and `copy`.
 
 Using copied association is recommended for a block or
 otherwise `NSCopying`-compliant instances like NSString.
 
 @param value Any object, pointer, or value.
 @param key A unique key pointer.
 */
- (void)bk_associateCopyOfValue:(nullable id)value withKey:(const void *)key;

/** Associates a copy of an object with the receiving class.
 
 @see associateCopyOfValue:withKey:
 @param value Any object, pointer, or value.
 @param key A unique key pointer.
 */
+ (void)bk_associateCopyOfValue:(nullable id)value withKey:(const void *)key;

/** Thread-safely associates a copy of an object with the reciever.
 
 The associated value is copied as if it were a property
 synthesized with `atomic` and `copy`.
 
 Using copied association is recommended for a block or
 otherwise `NSCopying`-compliant instances like NSString.
 
 @see associateCopyOfValue:withKey:
 @param value Any object, pointer, or value.
 @param key A unique key pointer.
 */
- (void)bk_atomicallyAssociateCopyOfValue:(nullable id)value withKey:(const void *)key;

/** Thread-safely associates a copy of an object with the receiving class.
 
 @see associateCopyOfValue:withKey:
 @param value Any object, pointer, or value.
 @param key A unique key pointer.
 */
+ (void)bk_atomicallyAssociateCopyOfValue:(nullable id)value withKey:(const void *)key;

/** Weakly associates an object with the reciever.
 
 A weak association will cause the pointer to be set to zero
 or nil upon the disappearance of what it references;
 in other words, the associated object is not kept alive.
 
 @param value Any object.
 @param key A unique key pointer.
 */
- (void)bk_weaklyAssociateValue:(nullable __autoreleasing id)value withKey:(const void *)key;

/** Weakly associates an object with the receiving class.
 
 @see weaklyAssociateValue:withKey:
 @param value Any object.
 @param key A unique key pointer.
 */
+ (void)bk_weaklyAssociateValue:(nullable __autoreleasing id)value withKey:(const void *)key;

/** Returns the associated value for a key on the reciever.
 
 @param key A unique key pointer.
 @return The object associated with the key, or `nil` if not found.
 */
- (nullable id)bk_associatedValueForKey:(const void *)key;

/** Returns the associated value for a key on the receiving class.
 
 @see associatedValueForKey:
 @param key A unique key pointer.
 @return The object associated with the key, or `nil` if not found.
 */
+ (nullable id)bk_associatedValueForKey:(const void *)key;

/** Returns the reciever to a clean state by removing all
 associated objects, releasing them if necessary. */
- (void)bk_removeAllAssociatedObjects;

/** Returns the recieving class to a clean state by removing
 all associated objects, releasing them if necessary. */
+ (void)bk_removeAllAssociatedObjects;

@end


NS_ASSUME_NONNULL_END
