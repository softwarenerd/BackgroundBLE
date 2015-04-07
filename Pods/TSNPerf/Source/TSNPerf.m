//
//  TSNPerf.m
//  softwarenerd.org
//
//  Created by Brian Lambert on 2/2/12.
//  Copyright (c) 2012-2015 Brian Lambert. All rights reserved.
//

#include <mach/mach.h>
#include <mach/mach_time.h>
#import "TSNPerf.h"

// TSNPerf (Internal) interface.
@interface TSNPerf (Internal)
@end

// TSNPerf implementation.
@implementation TSNPerf
{
@private
    // The absolute to nanosecond conversion factor.
    volatile long double _factor;
    
    // The started absolute time.
    volatile UInt64 _started;
    
    // The capture absolute time.
    volatile UInt64 _capture;
}

// Class initializer.
- (instancetype)init
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Precalculate the absolute time to nanosecond conversion factor as it
    // only needs to be done once.
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    _factor = ((long double)info.numer) / ((long double)info.denom);
    
    // Done.
	return self;
}

// Starts or restarts the perf timer.
- (void)start;
{
    _capture = 0ULL;
    _started = mach_absolute_time();
}

// Captures the perf timer.
- (void)capture
{
    // Get the capture time.
    UInt64 capture = mach_absolute_time();
    
    // If the timer was started, set capture time; otherwise, ignore the call.
    if (_started)
    {
        _capture = capture;
    }
}

// Returns the elapsed time in nanoseconds.
- (UInt64)nsElapsed
{
    if (!_started || !_capture)
    {
        return 0LL;
    }
    
    return (UInt64)roundl((long double)(_capture - _started) * _factor);
}

// Returns the elapsed time in milliseconds.
- (UInt32)msElapsed
{
    if (!_started || !_capture)
    {
        return 0LL;
    }
    
    return (UInt32)roundl((long double)(_capture - _started) * _factor / 1000000.0L);
}

// Returns a string containing a representation of the elapsed time.
- (NSString *)stringWithElapsedTime
{
    // Allocate a number formatter and initialize it with the decimal style.
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    // Obtain the elapsed ns.
    UInt64 nsElapsed = [self nsElapsed];
    
    // Format the elapsed ns. This will always be returned.
    NSString * nsElapsedString = [formatter stringFromNumber:[NSNumber numberWithLongLong:nsElapsed]];
    
    // If the elapsed NS is < 1 ms, just return the elapsed ns.
    if (nsElapsed < 1000000ULL)
    {
        return [NSString stringWithFormat:@"(<1 ms) [%@ ns]", nsElapsedString];
    }
    
    // Format the elapsed ns.
    NSString * msElapsedString = [formatter stringFromNumber:[NSNumber numberWithLong:[self msElapsed]]];
    
    // Done.
    return [NSString stringWithFormat:@"[%@ ms] [%@ ns]", msElapsedString, nsElapsedString];
}

@end

// TSNPerf (Internal) implementation.
@implementation TSNPerf (Internal)
@end

