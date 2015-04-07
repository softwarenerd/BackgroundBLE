//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Brian Lambert.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  TSNLogger.h
//

#import <UIKit/UIKit.h>

// TSNLogger interface.
@interface TSNLogger : NSObject

// Properties.
@property (nonatomic) NSUInteger maxLogEntries;
@property (nonatomic) BOOL writeToAppleSystemLog;

// Class singleton.
+ (instancetype)singleton;

// Appends a log entry.
- (void)appendLogEntry:(NSString *)logEntry;

// Creates a logger view with the specified frame and colors. The logger view will display log entries from TSNLogger,
// including log entries which were appended to TSNLogger to before the logger view was created. The logger view will
// display, at most, the number of log entries specified in the maxLogEntries property.
- (UIView *)createLoggerViewWithFrame:(CGRect)frame
                      backgroundColor:(UIColor *)backgroundColor
                      foregroundColor:(UIColor *)foregroundColor;

@end

// Convenience C function to append a log entry to the TSNLogger.
static inline void TSNLog(NSString * format, ...)
{
    // Format the log entry.
    va_list args;
    va_start(args, format);
    NSString * formattedString = [[NSString alloc] initWithFormat:format
                                                        arguments:args];
    va_end(args);
    [[TSNLogger singleton] appendLogEntry:formattedString];
}
