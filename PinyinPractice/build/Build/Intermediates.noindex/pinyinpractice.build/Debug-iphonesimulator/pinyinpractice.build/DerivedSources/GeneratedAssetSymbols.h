#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"bicraw.pinyinpractice";

/// The "MidnightGreen" asset catalog color resource.
static NSString * const ACColorNameMidnightGreen AC_SWIFT_PRIVATE = @"MidnightGreen";

/// The "PrimaryBackground" asset catalog color resource.
static NSString * const ACColorNamePrimaryBackground AC_SWIFT_PRIVATE = @"PrimaryBackground";

/// The "PrimaryText" asset catalog color resource.
static NSString * const ACColorNamePrimaryText AC_SWIFT_PRIVATE = @"PrimaryText";

/// The "SecondaryBackground" asset catalog color resource.
static NSString * const ACColorNameSecondaryBackground AC_SWIFT_PRIVATE = @"SecondaryBackground";

/// The "SecondaryText" asset catalog color resource.
static NSString * const ACColorNameSecondaryText AC_SWIFT_PRIVATE = @"SecondaryText";

/// The "SuccessGreen" asset catalog color resource.
static NSString * const ACColorNameSuccessGreen AC_SWIFT_PRIVATE = @"SuccessGreen";

/// The "VibrantOrange" asset catalog color resource.
static NSString * const ACColorNameVibrantOrange AC_SWIFT_PRIVATE = @"VibrantOrange";

#undef AC_SWIFT_PRIVATE
