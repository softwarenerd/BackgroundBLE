//
//  TSNPerf.h
//  softwarenerd.org
//
//  Created by Brian Lambert on 2/2/12.
//  Copyright (c) 2012-2015 Brian Lambert. All rights reserved.
//

#import <Foundation/Foundation.h>

// TSNPerf interface.
@interface TSNPerf : NSObject

// Starts or restarts perf.
- (void)start;

// Captures perf.
- (void)capture;

// Returns the elapsed time in nanoseconds of the last capture.
- (UInt64)nsElapsed;

// Returns the elapsed time in milliseconds of the last capture.
- (UInt32)msElapsed;

// Returns a string representation of the last capture.
- (NSString *)stringWithElapsedTime;

@end
