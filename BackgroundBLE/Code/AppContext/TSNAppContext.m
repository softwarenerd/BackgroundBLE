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
//  TSNAppContext.m
//

#import "TSNAppContext.h"
#import "TSNPeerBluetoothContext.h"

// TSNAppContext (TSNPeerBluetoothContextDelegate) interface.
@interface TSNAppContext (TSNPeerBluetoothContextDelegate) <TSNPeerBluetoothContextDelegate>
@end

// TSNAppContext (Internal) interface.
@interface TSNAppContext (Internal)

// Class initializer.
- (instancetype)init;

@end

// TSNAppContext implementation.
@implementation TSNAppContext
{
@private
    // The peer Bluetooth context.
    TSNPeerBluetoothContext * _peerBluetoothContext;
}

// Singleton.
+ (instancetype)singleton
{
    // Singleton instance.
    static TSNAppContext * appContext = nil;
    
    // If unallocated, allocate.
    if (!appContext)
    {
        // Allocator.
        void (^allocator)() = ^
        {
            appContext = [[TSNAppContext alloc] init];
        };
        
        // Dispatch allocator once.
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, allocator);
    }
    
    // Done.
    return appContext;
}

// Starts communications.
- (void)startCommunications
{
    [_peerBluetoothContext start];
}

// Stops communications.
- (void)stopCommunications
{
    [_peerBluetoothContext stop];
}

@end

// TSNAppContext (TSNPeerBluetoothContextDelegate) implementation.
@implementation TSNAppContext (TSNPeerBluetoothContextDelegate)

// Notifies the delegate that a peer was connected.
- (void)peerBluetoothContext:(TSNPeerBluetoothContext *)peerBluetoothContext
    didConnectPeerIdentifier:(NSString *)peerIdentifier
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        UILocalNotification * localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[[NSDate alloc] init]];
        [localNotification setAlertTitle:@"Connected"];
        [localNotification setAlertBody:[NSString stringWithFormat:@"Connected to %@", peerIdentifier]];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

// Notifies the delegate that a peer was disconnected.
- (void)peerBluetoothContext:(TSNPeerBluetoothContext *)peerBluetoothContext
 didDisconnectPeerIdentifier:(NSString *)peerIdentifier
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        UILocalNotification * localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[[NSDate alloc] init]];
        [localNotification setAlertTitle:@"Disconnected"];
        [localNotification setAlertBody:[NSString stringWithFormat:@"Disconnected from %@.", peerIdentifier]];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

@end

// TSNAppContext (Internal) implementation.
@implementation TSNAppContext (Internal)

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
    
    // Get the peer name.
    NSString * peerName = [[UIDevice currentDevice] name];
    
    // Allocate and initialize the peer Bluetooth context.
    _peerBluetoothContext = [[TSNPeerBluetoothContext alloc] initWithPeerName:peerName];
    [_peerBluetoothContext setDelegate:(id<TSNPeerBluetoothContextDelegate>)self];

    // Done.
    return self;
}

@end
