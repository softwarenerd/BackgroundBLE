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
//  BackgroundBLE
//  TSNAppView.m
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import <TSNLogger.h>
#import <TSNAtomicFlag.h>
#import <TSNThreading.h>
#import "TSNAppView.h"

// TSNAppView (Internal) interface.
@interface TSNAppView (Internal)
@end

// TSNAppView implementation.
@implementation TSNAppView
{
@private
    // The logger view.
    UIView * _loggerView;
}

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
{
    // Initialize superclass.
    self = [super initWithFrame:frame];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    // Get the height of the status bar. The workspace begins below it.
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;

    // Allocate, initialize, and add the logger view.
    _loggerView = [[TSNLogger singleton] createLoggerViewWithFrame:CGRectMake(0.0, statusBarHeight, [self width], [self height] - statusBarHeight)
                                                   backgroundColor:[UIColor colorWithRGB:0xecf0f1]
                                                   foregroundColor:[UIColor blackColor]];
    [self addSubview:_loggerView];
    
    // Done.
	return self;
}

@end

// TSNAppView (Internal) implementation.
@implementation TSNAppView (Internal)
@end