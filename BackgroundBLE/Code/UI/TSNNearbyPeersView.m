//
//  TSNNearbyPeersView.m
//  BackgroundBLE
//
//  Created by Brian Lambert on 3/28/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import <TSNThreading.h>
#import <MapKit/MapKit.h>
#import "TSNAppContext.h"
#import "TSNNearbyPeersView.h"
#import "TSNMeAnnotation.h"
#import "TSNPeerAnnotation.h"

// TSNNearbyPeersView (MKMapViewDelegate) interface.
@interface TSNNearbyPeersView (MKMapViewDelegate) <MKMapViewDelegate>
@end

// TSNNearbyPeersView (Internal) interface.
@interface TSNNearbyPeersView (Internal)

// TSNLocationUpdatedNotification callback.
- (void)locationUpdatedNotificationCallback:(NSNotification *)notification;

// TSNPeersUpdatedNotification callback.
- (void)peersUpdatedNotificationCallback:(NSNotification *)notification;

@end

// TSNNearbyPeersView implementation.
@implementation TSNNearbyPeersView
{
@private
    // The map view.
    MKMapView * _mapView;
    
    // The me annotation.
    TSNMeAnnotation * _annotationMe;
    
    // The peer annotations dictionary.
    NSMutableDictionary * _peerAnnotations;
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
    
    // Allocate and initialize the peer annotations dictionary.
    _peerAnnotations = [[NSMutableDictionary alloc] init];
    
    
    // Allocate, initialize, and add the map view, if it has not been added already.
    _mapView = [[MKMapView alloc] initWithFrame:[self bounds]];
    [_mapView setZoomEnabled:NO];
    [_mapView setScrollEnabled:NO];
    [_mapView setRotateEnabled:NO];
    [_mapView setPitchEnabled:NO];
    [_mapView setShowsBuildings:YES];
    [_mapView setShowsUserLocation:NO];
    [_mapView setShowsPointsOfInterest:YES];
    [_mapView setDelegate:(id<MKMapViewDelegate>)self];
    [self addSubview:_mapView];
    
    _annotationMe = [[TSNMeAnnotation alloc] init];
    [_mapView addAnnotation:_annotationMe];

    // Get the default notification center.
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    
    // Add our observers.
    [notificationCenter addObserver:self
                           selector:@selector(locationUpdatedNotificationCallback:)
                               name:TSNLocationUpdatedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(peersUpdatedNotificationCallback:)
                               name:TSNPeersUpdatedNotification
                             object:nil];
    
    // Done.
    return self;
}

// Dealloc.
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// TSNNearbyPeersView (MKMapViewDelegate) implementation.
@implementation TSNNearbyPeersView (MKMapViewDelegate)

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay
{
//    if (overlay == _pathLineStroke)
//    {
//        MKPolylineRenderer * pathLineStrokeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:_pathLineStroke];
//        [pathLineStrokeRenderer setStrokeColor:[UIColor colorWithWhite:1 alpha:0.95]];
//        [pathLineStrokeRenderer setLineWidth:4.0];
//        [pathLineStrokeRenderer setLineJoin:kCGLineJoinRound];
//        
//        return pathLineStrokeRenderer;
//    }
//    else if (overlay == _pathLineFill)
//    {
//        MKPolylineRenderer * pathLineFillRenderer = [[MKPolylineRenderer alloc] initWithPolyline:_pathLineFill];
//        [pathLineFillRenderer setStrokeColor:[UIColor whoopIntensityBlueColor]];
//        [pathLineFillRenderer setLineWidth:2.0];
//        [pathLineFillRenderer setLineJoin:kCGLineJoinRound];
//        return pathLineFillRenderer;
//    }
//    
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[TSNMeAnnotation class]])
    {
        static NSString * const identifierAnnotationMe = @"AnnotationMe";
        
        MKAnnotationView * annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifierAnnotationMe];
        if (annotationView)
        {
            [annotationView setAnnotation:annotation];
        }
        else
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifierAnnotationMe];
        }
        
        [annotationView setCanShowCallout:YES];
        [annotationView setImage:[UIImage imageNamed:@"NearbyPeers"]];
        return annotationView;
    }
    else if ([annotation isKindOfClass:[TSNPeerAnnotation class]])
    {
        static NSString * const identifierAnnotationPeer = @"AnnotationPeer";
        
        MKAnnotationView * annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifierAnnotationPeer];
        if (annotationView)
        {
            [annotationView setAnnotation:annotation];
        }
        else
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifierAnnotationPeer];
        }
        
        [annotationView setCanShowCallout:YES];
        [annotationView setImage:[UIImage imageNamed:@"Peer"]];
        return annotationView;
    }
    else
    {
        return nil;
    }
}

@end

// TSNNearbyPeersView (Internal) implementation.
@implementation TSNNearbyPeersView (Internal)

// TSNLocationUpdatedNotification callback.
- (void)locationUpdatedNotificationCallback:(NSNotification *)notification
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        return;
    }

    // Get the location.
    CLLocation * location = [notification object];
    
    // Update the me annotation.
    if (_annotationMe)
    {
        [_annotationMe setCoordinate:[location coordinate]];
    }

    // Update the region.
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance([location coordinate], 50, 50);
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion
               animated:YES];
}

// TSNPeersUpdatedNotification callback.
- (void)peersUpdatedNotificationCallback:(NSNotification *)notification
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        return;
    }

    OnMainThread(^{
        // Get the peers from the app context.
        NSArray * peers = [[TSNAppContext singleton] peers];
        
        // If there are no peers, remove all peer annotations.
        if (![peers count])
        {
            // If there are any peer annotations, remove them all.
            if ([_peerAnnotations count])
            {
                [_mapView removeAnnotations:[_peerAnnotations allValues]];
                [_peerAnnotations removeAllObjects];
            }
            
            // Done.
            return;
        }
        
        // Enumerate the peers and add / update peer annotations, as needed.
        NSMutableDictionary * peerAnnotationsAdded = [[NSMutableDictionary alloc] initWithCapacity:[peers count]];
        NSMutableDictionary * peerAnnotationsProcessed = [[NSMutableDictionary alloc] initWithCapacity:[peers count]];
        for (TSNPeer * peer in peers)
        {
            // See if we have a peer annotation for this peer. If we do, update it and note that we processed it.
            // If we don't, create it and note that we added it.
            TSNPeerAnnotation * peerAnnotation = [_peerAnnotations objectForKey:[peer peerName]];
            if (peerAnnotation)
            {
                [peerAnnotation setCoordinate:[[peer location] coordinate]];
                peerAnnotationsProcessed[[peer peerName]] = peerAnnotation;
            }
            else
            {
                peerAnnotation = [[TSNPeerAnnotation alloc] initWithPeer:peer];
                peerAnnotationsAdded[[peer peerName]] = peerAnnotation;
            }
        }
        
        // Find peer annotations that are no longer needed.
        NSMutableDictionary * peerAnnotationsToRemove = [[NSMutableDictionary alloc] init];
        for (TSNPeerAnnotation * peerAnnotation in [_peerAnnotations allValues])
        {
            NSString * peerName = [[peerAnnotation peer] peerName];
            if (!peerAnnotationsProcessed[peerName] && !peerAnnotationsAdded[peerName])
            {
                peerAnnotationsToRemove[peerName] = peerAnnotation;
            }
        }
        
        // Remove any peer annotations that need to be removed.
        if ([peerAnnotationsToRemove count])
        {
            [_peerAnnotations removeObjectsForKeys:[peerAnnotationsToRemove allKeys]];
            [_mapView removeAnnotations:[peerAnnotationsToRemove allValues]];
        }
        
        // Add any peer annotations that need to be added.
        if ([peerAnnotationsAdded count])
        {
            [_peerAnnotations addEntriesFromDictionary:peerAnnotationsAdded];
            [_mapView addAnnotations:[peerAnnotationsAdded allValues]];
        }
    });
}

@end
