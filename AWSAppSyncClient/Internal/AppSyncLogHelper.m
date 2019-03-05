//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

#import "AppSyncLogHelper.h"

@implementation AppSyncLogHelper

+(BOOL)shouldLogFlag:(AWSDDLogFlag)flag {
    return flag & [AWSDDLog sharedInstance].logLevel;
}

+(void)log:(NSString *)message flag:(AWSDDLogFlag)flag file:(NSString *)file function:(NSString *)function line:(NSUInteger)line {
    [AWSDDLog log: YES
            level: [AWSDDLog sharedInstance].logLevel
             flag: flag
          context: 0
             file: [file cStringUsingEncoding:NSUTF8StringEncoding]
         function: [function cStringUsingEncoding:NSUTF8StringEncoding]
             line: line
              tag: nil
           format: message
             args: nil];
}

@end
