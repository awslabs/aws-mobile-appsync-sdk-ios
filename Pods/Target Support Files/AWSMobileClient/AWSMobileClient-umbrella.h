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

#import "AWSMobileClient.h"
#import "_AWSMobileClient.h"
#import "AWSCognitoAuth.h"
#import "AWSCognitoAuth+Extensions.h"
#import "AWSCognitoCredentialsProvider+Extension.h"
#import "AWSCognitoIdentityUserPool+Extension.h"

FOUNDATION_EXPORT double AWSMobileClientVersionNumber;
FOUNDATION_EXPORT const unsigned char AWSMobileClientVersionString[];

