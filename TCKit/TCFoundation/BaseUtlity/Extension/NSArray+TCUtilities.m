/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import "NSArray+TCUtilities.h"

#if ! __has_feature(objc_arc)
#error this file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

/*
 Thanks to August Joki, Emanuele Vulcano, BlueLlama, Optimo, jtbandes
 
 To add Math Extensions like sum, product?
 */


@implementation NSArray (TCUtilities)


#pragma mark - Utility

- (id)topObject
{
    return self.lastObject;
}

- (instancetype)reversed
{
    return self.reverseObjectEnumerator.allObjects;
}

- (instancetype)sorted
{
    return [self sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
}

- (instancetype)sortedCaseInsensitive
{
    return [self sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2];
    }];
}


#pragma mark - Set theory

- (instancetype)uniqueElements
{
    return [NSOrderedSet orderedSetWithArray:self].array;
}

- (instancetype)unionWithArray:(NSArray *)anArray
{
    NSMutableOrderedSet *set1 = [NSMutableOrderedSet orderedSetWithArray:self];
    NSMutableOrderedSet *set2 = [NSMutableOrderedSet orderedSetWithArray:anArray];
    
    [set1 unionOrderedSet:set2];
    
    return set1.array.copy;
}

- (instancetype)intersectionWithArray:(NSArray *)anArray
{
    NSMutableOrderedSet *set1 = [NSMutableOrderedSet orderedSetWithArray:self];
    NSMutableOrderedSet *set2 = [NSMutableOrderedSet orderedSetWithArray:anArray];
    
    [set1 intersectOrderedSet:set2];
    
    return set1.array.copy;
}

- (instancetype)differenceToArray:(NSArray *)anArray
{
    NSMutableOrderedSet *set1 = [NSMutableOrderedSet orderedSetWithArray:self];
    NSMutableOrderedSet *set2 = [NSMutableOrderedSet orderedSetWithArray:anArray];
    
    [set1 minusOrderedSet:set2];
    
    return set1.array.copy;
}


#pragma mark - Lisp

- (instancetype)map:(MapBlock)aBlock
{
    if (nil == aBlock) {
        return self;
    }
    
    NSMutableArray *resultArray = NSMutableArray.array;
    for (id object in self) {
        id result = aBlock(object);
        [resultArray addObject:result ?: NSNull.null];
    }
    return resultArray.count > 0 ? resultArray.copy : nil;
}

- (instancetype)collect:(TestingBlock)aBlock
{
    if (nil == aBlock) {
        return self;
    }
    
    NSMutableArray *resultArray = NSMutableArray.array;
    for (id object in self) {
        if (aBlock(object)) {
            [resultArray addObject:object];
        }
    }
    return resultArray.count > 0 ? resultArray.copy : nil;
}

- (instancetype)reject:(TestingBlock)aBlock
{
    if (nil == aBlock) {
        return self;
    }
    
    NSMutableArray *resultArray = NSMutableArray.array;
    for (id object in self) {
        if (!aBlock(object)) {
            [resultArray addObject:object];
        }
    }
    return resultArray.count > 0 ? resultArray.copy : nil;
}

@end


#pragma mark - Mutable UtilityExtensions

@implementation NSMutableArray (TCUtilities)

- (instancetype)reverse
{
    for (NSUInteger i = 0; i < self.count/2; ++i) {
        [self exchangeObjectAtIndex:i withObjectAtIndex:(self.count-(i+1))];
    }
    return self;
}

- (void)replaceObjectIdenticalTo:(id)obj withObject:(id)anObject
{
    NSIndexSet *indexes = [self indexesOfObjectsPassingTest:^BOOL(id  _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj == value;
    }];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [self replaceObjectAtIndex:idx withObject:anObject];
    }];
}

//// Make sure to run srandom([NSDate.date timeIntervalSince1970]); or similar somewhere in your program
//- (NSMutableArray *) scramble
//{
//	for (int i=0; i<([self count]-2); i++) 
//		[self exchangeObjectAtIndex:i withObjectAtIndex:(i+(random()%([self count]-i)))];
//	return self;
//}

@end


#pragma mark - StackAndQueueExtensions

@implementation NSMutableArray (TC_StackAndQueueExtensions)

- (id)popObject
{
    if (self.count < 1) {
        return nil;
    }
	
    id lastObject = self.lastObject;
    [self removeLastObject];
    return lastObject;
}

- (instancetype)pushObject:(id)object
{
    [self addObject:object];
	return self;
}

- (instancetype)pushObjects:(id)object, ...
{
    if (nil == object) {
        return self;
    }
	id obj = object;
	va_list objects;
	va_start(objects, object);
	do {
		[self addObject:obj];
		obj = va_arg(objects, id);
	} while (nil != obj);
	va_end(objects);
	return self;
}

- (id)pullObject
{
    if (self.count < 1) {
        return nil;
    }
	
	id firstObject = self.firstObject;
	[self removeObjectAtIndex:0];
	return firstObject;
}

@end


@implementation NSDictionary (TCUtilities)

- (id)valueForCaseInsensitiveKey:(NSString *)key
{
    NSCParameterAssert(key);
    if (nil == key) {
        return nil;
    }
    
    NSString *usedKey = nil;
    for (NSString *rawKey in self.allKeys) {
        if (0 == [rawKey compare:key options:NSCaseInsensitiveSearch]) {
            usedKey = rawKey;
            break;
        }
    }
    
    return nil != usedKey ? self[usedKey] : nil;
}

@end

@implementation NSMutableDictionary (TCUtilities)

- (void)removeValueForCaseInsensitiveKey:(NSString *)key
{
    NSCParameterAssert(key);
    if (nil == key) {
        return;
    }
    
    NSString *usedKey = key;
    for (NSString *rawKey in self.allKeys) {
        if (0 == [rawKey compare:key options:NSCaseInsensitiveSearch]) {
            usedKey = rawKey;
            break;
        }
    }
    
    [self removeObjectForKey:usedKey];
}

@end
