//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>

@interface AppSyncLogHelper : NSObject

+(void)logVerbose:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line;
+(void)logDebug:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line;
+(void)logInfo:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line;
+(void)logWarn:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line;
+(void)logError:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line;

@end
