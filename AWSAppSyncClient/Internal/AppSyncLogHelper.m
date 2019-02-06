//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

#import "AppSyncLogHelper.h"

@implementation AppSyncLogHelper

+(void)logVerbose:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line {
    [AWSDDLog log: YES
            level: [AWSDDLog sharedInstance].logLevel
             flag: AWSDDLogFlagVerbose
          context: 0
             file: [file cStringUsingEncoding:NSUTF8StringEncoding]
         function: [function cStringUsingEncoding:NSUTF8StringEncoding]
             line: line
              tag: nil
           format:message
             args:nil];
}

+(void)logDebug:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line {
    [AWSDDLog log: YES
            level: [AWSDDLog sharedInstance].logLevel
             flag: AWSDDLogFlagDebug
          context: 0
             file: [file cStringUsingEncoding:NSUTF8StringEncoding]
         function: [function cStringUsingEncoding:NSUTF8StringEncoding]
             line: line
              tag: nil
           format:message
             args:nil];
}

+(void)logInfo:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line {
    [AWSDDLog log: YES
            level: [AWSDDLog sharedInstance].logLevel
             flag: AWSDDLogFlagInfo
          context: 0
             file: [file cStringUsingEncoding:NSUTF8StringEncoding]
         function: [function cStringUsingEncoding:NSUTF8StringEncoding]
             line: line
              tag: nil
           format:message
             args:nil];
}

+(void)logWarn:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line {
    [AWSDDLog log: YES
            level: [AWSDDLog sharedInstance].logLevel
             flag: AWSDDLogFlagWarning
          context: 0
             file: [file cStringUsingEncoding:NSUTF8StringEncoding]
         function: [function cStringUsingEncoding:NSUTF8StringEncoding]
             line: line
              tag: nil
           format:message
             args:nil];
}

+(void)logError:(NSString *)message file:(NSString *)file funcion:(NSString *)function line:(NSUInteger)line {
    [AWSDDLog log: YES
            level: [AWSDDLog sharedInstance].logLevel
             flag: AWSDDLogFlagError
          context: 0
             file: [file cStringUsingEncoding:NSUTF8StringEncoding]
         function: [function cStringUsingEncoding:NSUTF8StringEncoding]
             line: line
              tag: nil
           format:message
             args:nil];
}

@end
