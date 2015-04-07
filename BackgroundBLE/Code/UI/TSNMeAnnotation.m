//
//  TSNMeAnnotation.m
//  BackgroundBLE
//
//  Created by Brian Lambert on 3/28/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import "TSNMeAnnotation.h"

// TSNMeAnnotation (Internal) interface.
@interface TSNMeAnnotation (Internal)
@end

// TSNMeAnnotation implementation.
@implementation TSNMeAnnotation
{
@private
}

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;

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

    // Intialize.
    title = @"ME";
    
    // Done.
    return self;
}

// Called as a result of dragging an annotation view.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    coordinate = newCoordinate;
}

@end

// TSNMeAnnotation (Internal) implementation.
@implementation TSNMeAnnotation (Internal)
@end
