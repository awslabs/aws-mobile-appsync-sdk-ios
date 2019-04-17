#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AWSAuthCore.h"
#import "AWSIdentityManager.h"
#import "AWSSignInButtonView.h"
#import "AWSSignInManager.h"
#import "AWSSignInProvider.h"
#import "AWSSignInProviderApplicationIntercept.h"
#import "AWSUIConfiguration.h"

FOUNDATION_EXPORT double AWSAuthCoreVersionNumber;
FOUNDATION_EXPORT const unsigned char AWSAuthCoreVersionString[];

