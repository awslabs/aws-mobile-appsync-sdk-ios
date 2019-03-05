//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>

@interface AppSyncLogHelper : NSObject

+(BOOL)shouldLogFlag:(AWSDDLogFlag)flag NS_SWIFT_NAME(shouldLog(flag:));

+(void)log:(NSString *)message
      flag:(AWSDDLogFlag)flag
      file:(NSString *)file
  function:(NSString *)function
      line:(NSUInteger)line;

@end
