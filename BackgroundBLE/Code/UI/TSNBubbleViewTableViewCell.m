//
//  TSNBubbleViewTableViewCell.m
//  BackgroundBLE
//
//  Created by Brian Lambert on 3/25/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import "TSNBubbleViewTableViewCell.h"

// TSNBubbleViewTableViewCell (Internal) interface.
@interface TSNBubbleViewTableViewCell (Internal)
@end

// TSNBubbleViewTableViewCell implementation.
@implementation TSNBubbleViewTableViewCell
{
@private
    UIView * _view;
    
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
    
    // Initialize.
    [self setAutoresizesSubviews:YES];
    
    _view = [[UIView alloc] initWithFrame:CGRectMake(10.0, 4.0, 200.0, 36.0)];
    [_view setBackgroundColor:[UIColor purpleColor]];
    [self addSubview:_view];
        
    // Done.
    return self;
}

// Gets the height.
- (CGFloat)height
{
    return 40.0;
}

@end

// TSNBubbleViewTableViewCell (Internal) implementation.
@implementation TSNBubbleViewTableViewCell (Internal)
@end
