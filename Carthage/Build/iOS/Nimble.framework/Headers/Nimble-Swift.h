// Generated by Apple Swift version 3.0 (swiftlang-800.0.46.2 clang-800.0.38)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if defined(__has_include) && __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if defined(__has_attribute) && __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if defined(__has_attribute) && __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
# if defined(__has_feature) && __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if defined(__has_feature) && __has_feature(modules)
@import ObjectiveC;
@import Foundation;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"

/**
  Encapsulates the failure message that matchers can report to the end user.
  This is shared state between Nimble and matchers that mutate this value.
*/
SWIFT_CLASS("_TtC6Nimble14FailureMessage")
@interface FailureMessage : NSObject
@property (nonatomic, copy) NSString * _Nonnull expected;
@property (nonatomic, copy) NSString * _Nullable actualValue;
@property (nonatomic, copy) NSString * _Nonnull to;
@property (nonatomic, copy) NSString * _Nonnull postfixMessage;
@property (nonatomic, copy) NSString * _Nonnull postfixActual;
/**
  An optional message that will be appended as a new line and provides additional details
  about the failure. This message will only be visible in the issue navigator / in logs but
  not directly in the source editor since only a single line is presented there.
*/
@property (nonatomic, copy) NSString * _Nullable extendedMessage;
@property (nonatomic, copy) NSString * _Nullable userDescription;
@property (nonatomic, copy) NSString * _Nonnull stringValue;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
- (nonnull instancetype)initWithStringValue:(NSString * _Nonnull)stringValue OBJC_DESIGNATED_INITIALIZER;
@end


/**
  Protocol for types that support only beEmpty(), haveCount() matchers
*/
SWIFT_PROTOCOL("_TtP6Nimble13NMBCollection_")
@protocol NMBCollection
@property (nonatomic, readonly) NSInteger count;
@end


SWIFT_PROTOCOL("_TtP6Nimble13NMBComparable_")
@protocol NMBComparable
- (NSComparisonResult)NMB_compare:(id <NMBComparable> _Null_unspecified)otherObject;
@end


/**
  Protocol for types that support contain() matcher.
*/
SWIFT_PROTOCOL("_TtP6Nimble12NMBContainer_")
@protocol NMBContainer
- (BOOL)containsObject:(id _Nonnull)anObject;
@end

@protocol NMBMatcher;

SWIFT_CLASS("_TtC6Nimble14NMBExpectation")
@interface NMBExpectation : NSObject
- (nonnull instancetype)initWithActualBlock:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock negative:(BOOL)negative file:(NSString * _Nonnull)file line:(NSUInteger)line OBJC_DESIGNATED_INITIALIZER;
@property (nonatomic, readonly, copy) NMBExpectation * _Nonnull (^ _Nonnull withTimeout)(NSTimeInterval);
@property (nonatomic, readonly, copy) void (^ _Nonnull to)(id <NMBMatcher> _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toWithDescription)(id <NMBMatcher> _Nonnull, NSString * _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toNot)(id <NMBMatcher> _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toNotWithDescription)(id <NMBMatcher> _Nonnull, NSString * _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull notTo)(id <NMBMatcher> _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull notToWithDescription)(id <NMBMatcher> _Nonnull, NSString * _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toEventually)(id <NMBMatcher> _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toEventuallyWithDescription)(id <NMBMatcher> _Nonnull, NSString * _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toEventuallyNot)(id <NMBMatcher> _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toEventuallyNotWithDescription)(id <NMBMatcher> _Nonnull, NSString * _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toNotEventually)(id <NMBMatcher> _Nonnull);
@property (nonatomic, readonly, copy) void (^ _Nonnull toNotEventuallyWithDescription)(id <NMBMatcher> _Nonnull, NSString * _Nonnull);
+ (void)failWithMessage:(NSString * _Nonnull)message file:(NSString * _Nonnull)file line:(NSUInteger)line;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end

@class SourceLocation;

/**
  Objective-C interface to the Swift variant of Matcher.
*/
SWIFT_PROTOCOL("_TtP6Nimble10NMBMatcher_")
@protocol NMBMatcher
- (BOOL)matches:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
- (BOOL)doesNotMatch:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
@end


SWIFT_CLASS("_TtC6Nimble23NMBObjCBeCloseToMatcher")
@interface NMBObjCBeCloseToMatcher : NSObject <NMBMatcher>
- (BOOL)matches:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualExpression failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
- (BOOL)doesNotMatch:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualExpression failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
@property (nonatomic, readonly, copy) NMBObjCBeCloseToMatcher * _Nonnull (^ _Nonnull within)(double);
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


SWIFT_CLASS("_TtC6Nimble14NMBObjCMatcher")
@interface NMBObjCMatcher : NSObject <NMBMatcher>
- (BOOL)matches:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
- (BOOL)doesNotMatch:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)satisfyAnyOfMatcher:(NSArray<NMBObjCMatcher *> * _Nonnull)matchers;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)endWithMatcher:(id _Nonnull)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beNilMatcher;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beEmptyMatcher;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beIdenticalToMatcher:(NSObject * _Nullable)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beginWithMatcher:(id _Nonnull)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beGreaterThanOrEqualToMatcher:(id <NMBComparable> _Nullable)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)containMatcher:(NSArray<NSObject *> * _Nonnull)expected;
@end

@class NMBObjCRaiseExceptionMatcher;

@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCRaiseExceptionMatcher * _Nonnull)raiseExceptionMatcher;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beGreaterThanMatcher:(id <NMBComparable> _Nullable)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beLessThanMatcher:(id <NMBComparable> _Nullable)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (id <NMBMatcher> _Nonnull)equalMatcher:(NSObject * _Nonnull)expected;
@end

@class NSString;

@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (id <NMBMatcher> _Nonnull)matchMatcher:(NSString * _Nonnull)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (id <NMBMatcher> _Nonnull)beAKindOfMatcher:(Class _Nonnull)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)allPassMatcher:(NMBObjCMatcher * _Nonnull)matcher;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (id <NMBMatcher> _Nonnull)beAnInstanceOfMatcher:(Class _Nonnull)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beLessThanOrEqualToMatcher:(id <NMBComparable> _Nullable)expected;
@end

@class NSNumber;

@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCBeCloseToMatcher * _Nonnull)beCloseToMatcher:(NSNumber * _Nonnull)expected within:(double)within;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)haveCountMatcher:(NSNumber * _Nonnull)expected;
@end


@interface NMBObjCMatcher (SWIFT_EXTENSION(Nimble))
+ (NMBObjCMatcher * _Nonnull)beTruthyMatcher;
+ (NMBObjCMatcher * _Nonnull)beFalsyMatcher;
+ (NMBObjCMatcher * _Nonnull)beTrueMatcher;
+ (NMBObjCMatcher * _Nonnull)beFalseMatcher;
@end

@class NSDictionary;
@class NSException;

SWIFT_CLASS("_TtC6Nimble28NMBObjCRaiseExceptionMatcher")
@interface NMBObjCRaiseExceptionMatcher : NSObject <NMBMatcher>
- (BOOL)matches:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
- (BOOL)doesNotMatch:(NSObject * _Null_unspecified (^ _Nonnull)(void))actualBlock failureMessage:(FailureMessage * _Nonnull)failureMessage location:(SourceLocation * _Nonnull)location;
@property (nonatomic, readonly, copy) NMBObjCRaiseExceptionMatcher * _Nonnull (^ _Nonnull named)(NSString * _Nonnull);
@property (nonatomic, readonly, copy) NMBObjCRaiseExceptionMatcher * _Nonnull (^ _Nonnull reason)(NSString * _Nullable);
@property (nonatomic, readonly, copy) NMBObjCRaiseExceptionMatcher * _Nonnull (^ _Nonnull userInfo)(NSDictionary * _Nullable);
@property (nonatomic, readonly, copy) NMBObjCRaiseExceptionMatcher * _Nonnull (^ _Nonnull satisfyingBlock)(void (^ _Nullable)(NSException * _Nonnull));
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


/**
  Protocol for types that support beginWith(), endWith(), beEmpty() matchers
*/
SWIFT_PROTOCOL("_TtP6Nimble20NMBOrderedCollection_")
@protocol NMBOrderedCollection <NMBCollection>
- (NSInteger)indexOfObject:(id _Nonnull)anObject;
@end


SWIFT_CLASS("_TtC6Nimble11NMBStringer")
@interface NMBStringer : NSObject
+ (NSString * _Nonnull)stringify:(id _Nullable)obj;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


@interface NSArray (SWIFT_EXTENSION(Nimble)) <NMBContainer>
@end


@interface NSArray (SWIFT_EXTENSION(Nimble)) <NMBOrderedCollection>
@end


@interface NSArray (SWIFT_EXTENSION(Nimble))
@property (nonatomic, readonly, copy) NSString * _Nonnull testDescription;
@end


@interface NSDictionary (SWIFT_EXTENSION(Nimble)) <NMBCollection>
@end


@interface NSHashTable (SWIFT_EXTENSION(Nimble)) <NMBCollection>
@end


@interface NSIndexSet (SWIFT_EXTENSION(Nimble)) <NMBCollection>
@end


@interface NSIndexSet (SWIFT_EXTENSION(Nimble))
@property (nonatomic, readonly, copy) NSString * _Nonnull testDescription;
@end


@interface NSMapTable (SWIFT_EXTENSION(Nimble)) <NMBCollection>
@end


@interface NSNumber (SWIFT_EXTENSION(Nimble))
@end


@interface NSNumber (SWIFT_EXTENSION(Nimble)) <NMBComparable>
- (NSComparisonResult)NMB_compare:(id <NMBComparable> _Null_unspecified)otherObject;
@end


@interface NSNumber (SWIFT_EXTENSION(Nimble))
@property (nonatomic, readonly, copy) NSString * _Nonnull testDescription;
@end


@interface NSSet (SWIFT_EXTENSION(Nimble)) <NMBCollection>
@end


@interface NSSet (SWIFT_EXTENSION(Nimble)) <NMBContainer>
@end


@interface NSString (SWIFT_EXTENSION(Nimble)) <NMBComparable>
- (NSComparisonResult)NMB_compare:(id <NMBComparable> _Null_unspecified)otherObject;
@end


SWIFT_CLASS("_TtC6Nimble14SourceLocation")
@interface SourceLocation : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull file;
@property (nonatomic, readonly) NSUInteger line;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@property (nonatomic, readonly, copy) NSString * _Nonnull description;
@end

#pragma clang diagnostic pop
