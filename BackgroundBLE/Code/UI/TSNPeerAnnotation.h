//
//  TSNPeerAnnotation.h
//  BackgroundBLE
//
//  Created by Brian Lambert on 3/30/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

// TSNPeerAnnotation interface.
@interface TSNPeerAnnotation : NSObject <MKAnnotation>

// Properties.
@property (nonatomic, readonly) TSNPeer * peer;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString * title;
@property (nonatomic, readonly, copy) NSString * subtitle;

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer;

@end
