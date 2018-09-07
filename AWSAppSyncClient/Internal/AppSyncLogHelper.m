//
// Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
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
