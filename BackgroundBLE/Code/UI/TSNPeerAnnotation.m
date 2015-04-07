//
//  TSNPeerAnnotation.m
//  BackgroundBLE
//
//  Created by Brian Lambert on 3/30/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import "TSNPeer.h"
#import "TSNPeerAnnotation.h"

// TSNPeerAnnotation (Internal) interface.
@interface TSNPeerAnnotation (Internal)
@end

// TSNPeerAnnotation implementation.
@implementation TSNPeerAnnotation
{
@private
}

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    _peer = peer;
    title = [_peer peerName];
    coordinate = [[_peer location] coordinate];
    
    // Done.
    return self;
}

// Called as a result of dragging an annotation view.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    coordinate = newCoordinate;
}

@end

// TSNPeerAnnotation (Internal) implementation.
@implementation TSNPeerAnnotation (Internal)
@end
