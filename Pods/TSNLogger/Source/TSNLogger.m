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
//  TSNLogger.m
//

#import <pthread.h>
#import "TSNLogger.h"

// The TSNLogger new log entry notification name.
NSString * const TSNLoggerNewLogEntryNotificationName = @"org.softwarenerd.newloggerentry";

// TSNLoggerView interface.
@interface TSNLoggerView : UIView

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
            initialLogEntries:(NSArray *)initialLogEntries
              backgroundColor:(UIColor *)backgroundColor
              foregroundColor:(UIColor *)foregroundColor;

@end

// TSNLoggerView (UIWebViewDelegate) interface.
@interface TSNLoggerView (UIWebViewDelegate) <UIWebViewDelegate>
@end

// TSNLoggerView (Internal) interface.
@interface TSNLoggerView (Internal)

// TSNLoggerNewLogEntryNotificationName callback.
- (void)loggerNewLogEntryNotificationCallback:(NSNotification *)notification;

@end

// TSNLoggerView implementation.
@implementation TSNLoggerView
{
@private
    // The web view that displays the log entries.
    UIWebView * _webView;
}

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
            initialLogEntries:(NSArray *)initialLogEntries
              backgroundColor:(UIColor *)backgroundColor
              foregroundColor:(UIColor *)foregroundColor
{
    // Initialize superclass.
    self = [super initWithFrame:frame];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    [self setOpaque:NO];
    [self setBackgroundColor:backgroundColor];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    // Get the foreground RGBA.
    CGFloat foregroundR, foregroundG, foregroundB, foregroundA;
    [foregroundColor getRed:&foregroundR
                      green:&foregroundG
                       blue:&foregroundB
                      alpha:&foregroundA];
    UInt8 foregroundValR = (UInt8)roundf(255.0 * foregroundR);
    UInt8 foregroundValG = (UInt8)roundf(255.0 * foregroundG);
    UInt8 foregroundValB = (UInt8)roundf(255.0 * foregroundB);
    UInt8 foregroundValA = (UInt8)roundf(255.0 * foregroundA);
    
    // Allocate, initialize, and add the web view.
    _webView = [[UIWebView alloc] initWithFrame:[self bounds]];
    [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_webView setScalesPageToFit:YES];
    [_webView setOpaque:NO];
    [_webView setBackgroundColor:[UIColor clearColor]];
    [_webView setDelegate:(id<UIWebViewDelegate>)self];
    [_webView setDataDetectorTypes:UIDataDetectorTypeNone];
    [self addSubview:_webView];
    
    // Allocate the initial log HTML document string.
    NSMutableString * logHTML = [[NSMutableString alloc] initWithCapacity:2048];
    
    // Note: The addLogEntry function does two interesting things. First, it trims the set of log entries to 500
    // so that the document doesn't grow unbounded. Second, it scrolls the document to the bottom if it was scrolled
    // to the bottom before adding the new log entry.
    [logHTML appendString:[NSString stringWithFormat:@"\
                           <html>\
                           <head>\
                           <meta name=\"viewport\" content=\"width=device-width; minimum-scale=0.5; maximum-scale=0.8; user-scalable=no\">\
                           <script>\
                           function addLogEntry(logEntry, maxEntries) {\
                               var wasScrolledBottom = (window.innerHeight + window.scrollY) >= document.body.offsetHeight;\
                               var logEntries = document.getElementsByClassName('logEntry');\
                               if (logEntries.length >= maxEntries) {\
                                   for (i = 0; i < logEntries.length - maxEntries; i++) {\
                                       document.body.removeChild(logEntries[i]);\
                                   }\
                               }\
                               var logEntryDiv = document.createElement('div');\
                               logEntryDiv.className = 'logEntry';\
                               logEntryDiv.innerHTML = logEntry;\
                               document.body.appendChild(logEntryDiv);\
                               if (wasScrolledBottom) {\
                                   window.scrollTo(0, document.body.scrollHeight);\
                               }\
                           }\
                           </script>\
                           </head>\
                           <body style=\"color: rgba(%u, %u, %u, %u); font-family: Menlo-Regular; font-size: 8pt; word-wrap: break-word; -webkit-text-size-adjust: none;\">\
                           </body>\
                           </html>",
                           foregroundValR,
                           foregroundValG,
                           foregroundValB,
                           foregroundValA]];
    
    // Append the initial log entries.
    if ([initialLogEntries count])
    {
        for (NSString * logEntry in initialLogEntries)
        {
            [logHTML appendFormat:@"<div class=\"logEntry\">%@</div>", logEntry];
        }
    }
    
    // End the HTML document.
    [logHTML appendString:@"</body></html>"];
    
    // Load the initial log HTML document. This gives the appearance that the console view was
    // running all along in the background.
    [_webView loadHTMLString:logHTML
                     baseURL:nil];

    // Add TSNLoggerNewLogEntryNotificationName observer.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggerNewLogEntryNotificationCallback:)
                                                 name:TSNLoggerNewLogEntryNotificationName
                                               object:nil];

    // Done.
    return self;
}

// Dealloc
- (void)dealloc
{
    // Remove TSNLoggerNewLogEntryNotificationName observer.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// TSNLoggerView (UIWebViewDelegate) implementation.
@implementation TSNLoggerView (UIWebViewDelegate)

// Notifies the delegate that the web view finished loading.
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // After the initial log HTML document has loaded, scroll the window to the bottom.
    [_webView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0, document.body.scrollHeight);"];
}

@end

// TSNLoggerView (Internal) implementation.
@implementation TSNLoggerView (Internal)

// TSNLogEntryNotification callback.
- (void)loggerNewLogEntryNotificationCallback:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableString * logEntry = [NSMutableString stringWithString:[notification object]];
        [logEntry replaceOccurrencesOfString:@"\n" withString:@"<br/>" options:0 range:NSMakeRange(0, [logEntry length])];
        [logEntry replaceOccurrencesOfString:@" " withString:@"&nbsp;" options:0 range:NSMakeRange(0, [logEntry length])];
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"addLogEntry('%@', %lu);", logEntry, (unsigned long)[[TSNLogger singleton] maxLogEntries]]];
    });
}

@end

// TSNLogger (Internal) interface.
@interface TSNLogger (Internal)

// Class initializer.
- (instancetype)init;

@end

// TSNLogger implementation.
@implementation TSNLogger
{
@private
    // The mutex.
    pthread_mutex_t _mutex;
    
    // Date formatter we use to format timestamps.
    NSDateFormatter * _dateFormatter;
    
    // An array of the log entries.
    NSMutableArray * _arrayLogEntries;
}

// Class singleton.
+ (instancetype)singleton
{
    // Singleton instance.
    static TSNLogger * logger = nil;
    
    // If unallocated, allocate.
    if (!logger)
    {
        // Allocator.
        void (^allocator)() = ^
        {
            // Initialize singleton.
            logger = [[TSNLogger alloc] init];
        };
        
        // Dispatch allocator once.
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, allocator);
    }
    
    // Done.
    return logger;
}

// Creates a logger view with the specified frame and colors. The logger view will display log entries from TSNLogger,
// including log entries which were appended to TSNLogger to before the logger view was created. The logger view will
// display, at most, the number of log entries specified in the maxLogEntries property.
- (UIView *)createLoggerViewWithFrame:(CGRect)frame
                      backgroundColor:(UIColor *)backgroundColor
                      foregroundColor:(UIColor *)foregroundColor
{
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Allocate and initialize the logger view.
    TSNLoggerView * loggerView = [[TSNLoggerView alloc] initWithFrame:frame
                                                    initialLogEntries:_arrayLogEntries
                                                      backgroundColor:backgroundColor
                                                      foregroundColor:foregroundColor];
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);

    // Done. Return the logger view.
    return loggerView;
}

// Appends a log entry.
- (void)appendLogEntry:(NSString *)logEntry
{
    // Timestamp the log entry.
    NSString * timestampedLogEntry = [NSString stringWithFormat:@"%@ %@", [_dateFormatter stringFromDate:[[NSDate alloc] init]], logEntry];

    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Append the entry to the log.
    [_arrayLogEntries addObject:timestampedLogEntry];
    
    // When there are more than TSNAppLogMaxSize of objects, remove the first.
    if ([_arrayLogEntries count] > 1000)
    {
        [_arrayLogEntries removeObjectAtIndex:0];
    }
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);
    
    // Post the notification.
    [[NSNotificationCenter defaultCenter] postNotificationName:TSNLoggerNewLogEntryNotificationName
                                                        object:timestampedLogEntry];
    
    // Write to the Apple system log, if we should.
    if ([self writeToAppleSystemLog])
    {
        NSLog(@"%@", logEntry);
    }
}

@end

// TSNLogger (Internal) implementation.
@implementation TSNLogger (Internal)

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
    
    // Initialize.
    _maxLogEntries = 1000;
    pthread_mutex_init(&_mutex, NULL);
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"HH:mm:ss.SSSS"];
    _arrayLogEntries = [[NSMutableArray alloc] initWithCapacity:1000];

    // Done.
    return self;
}

@end