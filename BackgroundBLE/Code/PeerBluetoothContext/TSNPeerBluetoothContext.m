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
//  TSNPeerBluetoothContext.m
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheralManager+Extensions.h"
#import "CBPeripheral+Extensions.h"
#import "CBCentralManager+Extensions.h"
#import "TSNThreading.h"
#import "TSNAtomicFlag.h"
#import "TSNLogger.h"
#import "TSNPeerBluetoothContext.h"

// TSNMessageDescriptor interface.
@interface TSNMessageDescriptor : NSObject

// Properties.
@property (nonatomic) NSUUID * identifier;
@property (nonatomic) NSString * message;
@property (nonatomic) NSDate * messageDate;
@property (nonatomic) NSData * data;

// Class initializer.
- (instancetype)initWithIdentifier:(NSUUID *)identifier
                       messageDate:(NSDate *)messageDate
                           message:(NSString *)message;

@end

// TSNMessageDescriptor implementation.
@implementation TSNMessageDescriptor
{
@private
}

// Class initializer.
- (instancetype)initWithIdentifier:(NSUUID *)identifier
                       messageDate:(NSDate *)messageDate
                           message:(NSString *)message
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _identifier = identifier;
    _message = message;
    _messageDate = messageDate;
    
    // Done.
    return self;
}

@end

// TSNPeerDescriptor interface.
@interface TSNPeerDescriptor : NSObject

// Properties.
@property (nonatomic) NSUUID * peerID;
@property (nonatomic) NSString * peerName;
@property (nonatomic) BOOL connecting;

// Class initializer.
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                        connecting:(BOOL)connecting;

@end

// TSNPeerDescriptor implementation.
@implementation TSNPeerDescriptor
{
@private
    // The peripheral.
    CBPeripheral * _peripheral;
}

// Class initializer.
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                        connecting:(BOOL)connecting
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _peripheral = peripheral;
    _connecting = connecting;

    // Done.
    return self;
}

@end

// TSNPeerBluetoothContext (CBPeripheralManagerDelegate) interface.
@interface TSNPeerBluetoothContext (CBPeripheralManagerDelegate) <CBPeripheralManagerDelegate>
@end

// TSNPeerBluetoothContext (CBCentralManagerDelegate) interface.
@interface TSNPeerBluetoothContext (CBCentralManagerDelegate) <CBCentralManagerDelegate>
@end

// TSNPeerBluetoothContext (CBPeripheralDelegate) interface.
@interface TSNPeerBluetoothContext (CBPeripheralDelegate) <CBPeripheralDelegate>
@end

// TSNPeerBluetoothContext (Internal) interface.
@interface TSNPeerBluetoothContext (Internal)

// Starts advertising.
- (void)startAdvertising;

// Stops advertising.
- (void)stopAdvertising;

// Starts scanning.
- (void)startScanning;

// Stops scanning.
- (void)stopScanning;

@end

// TSNPeerBluetoothContext implementation.
@implementation TSNPeerBluetoothContext
{
@private
    NSData * _peerID;
    
    // The peer name.
    NSString * _peerName;
    
    // The canonical peer name.
    NSData * _canonicalPeerName;
    
    // The enabled atomic flag.
    TSNAtomicFlag * _atomicFlagEnabled;
    
    // The scanning atomic flag.
    TSNAtomicFlag * _atomicFlagScanning;

    // The service type.
    CBUUID * _serviceType;
    
    // The peer ID type.
    CBUUID * _peerIDType;

    // The peer name type.
    CBUUID * _peerNameType;
    
    // The newest message date type.
    CBUUID * _newestMessageDateType;
    
//    // The data type.
//    CBUUID * _dataType;
//
//    // The read position type.
//    CBUUID * _readPositionType;

    // The service.
    CBMutableService * _service;
    
    // The peer ID characteristic.
    CBMutableCharacteristic * _characteristicPeerID;

    // The peer name characteristic.
    CBMutableCharacteristic * _characteristicPeerName;
    
    // The newest message date characteristic.
    CBMutableCharacteristic * _characteristicNewestMessageDate;

//    // The data characteristic.
//    CBMutableCharacteristic * _characteristicData;
//
//    // The read position characteristic.
//    CBMutableCharacteristic * _characteristicReadPosition;
    
    // The advertising data.
    NSDictionary * _advertisingData;
    
    // The peripheral manager.
    CBPeripheralManager * _peripheralManager;
    
    // The central manager.
    CBCentralManager * _centralManager;
    
    // Mutex used to synchronize accesss to peers and messages.
    pthread_mutex_t _mutex;
    
    // The peers dictionary.
    NSMutableDictionary * _peers;
    
    // The messages array.
    NSMutableArray * _messages;
    
    NSMutableDictionary * _readDescriptors;
}

// Class initializer.
- (instancetype)initWithPeerName:(NSString *)peerName
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Static declarations.
    static NSString * const PEER_ID_KEY = @"PeerIDKey";

    // Obtain user defaults and see if we have a serialized peer ID. If we do, deserialize it. If not, make one
    // and serialize it for later use. If we don't serialize and reuse the peer ID, we'll see duplicates
    // of this peer in sessions.
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    _peerID = [userDefaults dataForKey:PEER_ID_KEY];
    if (!_peerID)
    {
        // Allocate and initialize a new peer ID.
        UInt8 uuid[16];
        [[NSUUID UUID] getUUIDBytes:uuid];
        _peerID = [NSData dataWithBytes:uuid length:sizeof(uuid)];
        
        // Serialize and save the peer ID in user defaults.
        [userDefaults setValue:_peerID
                        forKey:PEER_ID_KEY];
        [userDefaults synchronize];
    }

    // Initialize.
    _peerName = peerName;
    _canonicalPeerName = [_peerName dataUsingEncoding:NSUTF8StringEncoding];
    
    // Allocate and initialize the enabled atomic flag.
    _atomicFlagEnabled = [[TSNAtomicFlag alloc] init];
    
    // Allocate and initialize the scanning atomic flag.
    _atomicFlagScanning = [[TSNAtomicFlag alloc] init];

    // Allocate and initialize the service type.
    _serviceType = [CBUUID UUIDWithString:@"B206EE5D-17EE-40C1-92BA-462A038A33D2"];
    
    // Allocate and initialize the peer ID type.
    _peerIDType = [CBUUID UUIDWithString:@"E669893C-F4C2-4604-800A-5252CED237F9"];
    
    // Allocate and initialize the peer name type.
    _peerNameType = [CBUUID UUIDWithString:@"2EFDAD55-5B85-4C78-9DE8-07884DC051FA"];
    
    // Allocate and initialize the newest message date type.
    _newestMessageDateType = [CBUUID UUIDWithString:@"3211022A-EEF4-4522-A5CE-47E60342FFB5"];
    
//    // Allocate and initialize the data type.
//    _dataType = [CBUUID UUIDWithString:@"465FFFCE-914E-41DD-AC52-DF11002390F1"];
//
//    // Allocate and initialize the read type.
//    _dataType = [CBUUID UUIDWithString:@"E490C1B2-03A3-4D9C-A799-A57D671B8AB1"];

    // Allocate and initialize the service.
    _service = [[CBMutableService alloc] initWithType:_serviceType
                                              primary:YES];
    
    // Allocate and initialize the peer ID characteristic.
    _characteristicPeerID = [[CBMutableCharacteristic alloc] initWithType:_peerIDType
                                                               properties:CBCharacteristicPropertyRead
                                                                    value:_peerID
                                                              permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the peer name characteristic.
    _characteristicPeerName = [[CBMutableCharacteristic alloc] initWithType:_peerNameType
                                                                 properties:CBCharacteristicPropertyRead
                                                                      value:_canonicalPeerName
                                                                permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the newest message date characteristic.
    _characteristicNewestMessageDate = [[CBMutableCharacteristic alloc] initWithType:_newestMessageDateType
                                                                          properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
                                                                               value:nil
                                                                         permissions:CBAttributePermissionsReadable];


    // Set the service characteristics.
    [_service setCharacteristics:@[_characteristicPeerID,
                                   _characteristicPeerName,
                                   _characteristicNewestMessageDate]];
    
    // Allocate and initialize the advertising data.
    _advertisingData = @{CBAdvertisementDataServiceUUIDsKey:    @[_serviceType],
                         CBAdvertisementDataLocalNameKey:       [[UIDevice currentDevice] name]};
    
    // The background queue.
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    // Allocate and initialize the peripheral manager.
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:(id<CBPeripheralManagerDelegate>)self
                                                                 queue:backgroundQueue];
    
    // Allocate and initialize the central manager.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:(id<CBCentralManagerDelegate>)self
                                                           queue:backgroundQueue];
    

    pthread_mutex_init(&_mutex, NULL);
   
    // Allocate and initialize the peers dictionary. It contains a TSNPeerDescriptor for
    // every peer we are either connecting or connected to.
    _peers = [[NSMutableDictionary alloc] init];
    
    // Allocate and initialize the messages array.
    _messages = [[NSMutableArray alloc] init];

    // Done.
    return self;
}

// Starts the peer Bluetooth context.
- (void)start
{
    if ([_atomicFlagEnabled trySet])
    {
        [self startAdvertising];
        [self startScanning];
    }
}

// Stops the peer Bluetooth context.
- (void)stop
{
    if ([_atomicFlagEnabled tryClear])
    {
        [self stopAdvertising];
        [self stopScanning];
    }
}

// Appends a message.
- (void)appendMessage:(NSString *)message
          messageDate:(NSDate *)messageDate
{
    TSNMessageDescriptor * messageDescriptor = [[TSNMessageDescriptor alloc] initWithIdentifier:[NSUUID UUID]
                                                                                    messageDate:messageDate
                                                                                        message:message];

    pthread_mutex_lock(&_mutex);
    
    [_messages addObject:messageDescriptor];
    
    pthread_mutex_unlock(&_mutex);
}

@end

// TSNPeerBluetoothContext (CBPeripheralManagerDelegate) implementation.
@implementation TSNPeerBluetoothContext (CBPeripheralManagerDelegate)

// Invoked whenever the peripheral manager's state has been updated.
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if ([_peripheralManager state] == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
    else
    {
        [self stopAdvertising];
    }
}

// Invoked with the result of a startAdvertising call.
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager
                                       error:(NSError *)error
{
    if (error)
    {
        TSNLog(@"Advertising peer failed (%@)", [error localizedDescription]);
    }
}

// Invoked with the result of a addService call.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    if (error)
    {
        TSNLog(@"Adding service failed (%@)", [error localizedDescription]);
    }
}

// Invoked when peripheral manager receives a read request.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
    didReceiveReadRequest:(CBATTRequest *)request
{
    // Process the characteristic being read.
    if ([[[request characteristic] UUID] isEqual:_peerNameType])
    {
        // Process the request.
        [request setValue:_canonicalPeerName];
        [peripheralManager respondToRequest:request
                                 withResult:CBATTErrorSuccess];
    }
}

// Invoked when peripheral manager receives a write request.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
  didReceiveWriteRequests:(NSArray *)requests
{
    for (CBATTRequest * request in requests)
    {
    }
    
    //
    [peripheralManager respondToRequest:[requests firstObject]
                             withResult:CBATTErrorSuccess];
}

// Invoked after characteristic is subscribed to.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // Request low latency for the central.
    [_peripheralManager setDesiredConnectionLatency:CBPeripheralManagerConnectionLatencyLow
                                         forCentral:central];
}

// Invoked after a failed call to update a characteristic.
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheralManager
{
    TSNLog(@"Ready to update subscribers.");
}

@end

// TSNPeerBluetoothContext (CBCentralManagerDelegate) implementation.
@implementation TSNPeerBluetoothContext (CBCentralManagerDelegate)

// Invoked whenever the central manager's state has been updated.
- (void)centralManagerDidUpdateState:(CBCentralManager *)centralManager
{
    // If the central manager is powered on, make sure we're scanning. If it's in any other state,
    // make sure we're not scanning.
    if ([_centralManager state] == CBCentralManagerStatePoweredOn)
    {
        [self startScanning];
    }
    else
    {
        [self stopScanning];
    }
}

// Invoked when a peripheral is discovered.
- (void)centralManager:(CBCentralManager *)centralManager
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    // Obtain the peripheral identifier string.
    NSString * peripheralIdentifierString = [peripheral identifierString];
    
    // If we're not connected or connecting to this peripheral, connect to it.
    if (!_peers[peripheralIdentifierString])
    {
        // Log.
        TSNLog(@"Connecing peer %@", peripheralIdentifierString);
        
        // Add a TSNPeerDescriptor to the peers dictionary.
        _peers[peripheralIdentifierString] = [[TSNPeerDescriptor alloc] initWithPeripheral:peripheral
                                                                                connecting:YES];

        // Connect to the peripheral.
        [_centralManager connectPeripheral:peripheral
                                   options:nil];
    }
}

// Invoked when a peripheral is connected.
- (void)centralManager:(CBCentralManager *)centralManager
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [peripheral identifierString];
    
    // Find the peer descriptor in the peers dictionary. It should be there.
    TSNPeerDescriptor * peerDescriptor = _peers[peripheralIdentifierString];
    if (peerDescriptor)
    {
        // Log.
        TSNLog(@"Peer %@ connected", peripheralIdentifierString);

        // Move the peer descriptor to the connected state.
        [peerDescriptor setConnecting:NO];
    }
    else
    {
        // Log.
        TSNLog(@"***** Problem: Peer %@ was connected without having first been discovered", peripheralIdentifierString);
        
        // Allocate a new peer descriptor and add it to the peers dictionary.
        peerDescriptor = [[TSNPeerDescriptor alloc] initWithPeripheral:peripheral
                                                            connecting:NO];
        _peers[peripheralIdentifierString] = peerDescriptor;
    }
    
    // Update the peer name in the peer descriptor to the peripheral name for now. This is often a stand-in
    // value, it seems. "iPhone" seems to be quite common. We'll update this later.
    [peerDescriptor setPeerName:[peripheral name]];
    
    // Set our delegate on the peripheral and discover its services.
    [peripheral setDelegate:(id<CBPeripheralDelegate>)self];
    [peripheral discoverServices:@[_serviceType]];
}

// Invoked when a peripheral connection fails.
- (void)centralManager:(CBCentralManager *)centralManager
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [peripheral identifierString];

    // Log.
    TSNLog(@"Reconnecting to peer %@", peripheralIdentifierString);
    
    // Immediately reconnect. This is long-lived meaning that we will connect to this peer whenever it is
    // encountered again.
    [_centralManager connectPeripheral:peripheral
                               options:nil];
}

// Invoked when a peripheral is disconnected.
- (void)centralManager:(CBCentralManager *)centralManager
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [peripheral identifierString];

    TSNPeerDescriptor * peerDescriptor = [_peers objectForKey:peripheralIdentifierString];
    if (peerDescriptor)
    {
        // Log.
        TSNLog(@"Reconnecting to peer %@", peripheralIdentifierString);

        // Notify the delegate.
        if ([peerDescriptor peerName])
        {
            if ([[self delegate] respondsToSelector:@selector(peerBluetoothContext:didDisconnectPeerIdentifier:)])
            {
                [[self delegate] peerBluetoothContext:self
                          didDisconnectPeerIdentifier:peripheralIdentifierString];
            }
        }
        
        // Immediately reconnect. This is long-lived meaning that we will connect to this peer whenever it is
        // encountered again.
        [peerDescriptor setConnecting:YES];
        [_centralManager connectPeripheral:peripheral
                                   options:nil];
    }
}

@end

// TSNPeerBluetoothContext (CBPeripheralDelegate) implementation.
@implementation TSNPeerBluetoothContext (CBPeripheralDelegate)

// Invoked when services are discovered.
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    // Process the services.
    for (CBService * service in [peripheral services])
    {
        // If this is our service, discover its characteristics.
        if ([[service UUID] isEqual:_serviceType])
        {
            [peripheral discoverCharacteristics:@[_peerIDType,
                                                  _peerNameType,
                                                  _newestMessageDateType]
                                     forService:service];
        }
    }
}

// Invoked when service characteristics are discovered.
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    // If this is our service, process its discovered characteristics.
    if ([[service UUID] isEqual:_serviceType])
    {
        for (CBCharacteristic * characteristic in [service characteristics])
        {
            if ([[characteristic UUID] isEqual:_peerIDType])
            {
                TSNLog(@"Reading peer ID");
                [peripheral readValueForCharacteristic:characteristic];
            }
            else if ([[characteristic UUID] isEqual:_peerNameType])
            {
                TSNLog(@"Reading peer name");
                [peripheral readValueForCharacteristic:characteristic];
            }
            else if ([[characteristic UUID] isEqual:_newestMessageDateType])
            {
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
        }
    }
}

// Invoked when the value of a characteristic is updated.
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [peripheral identifierString];

    // Obtain the peer descriptor.
    TSNPeerDescriptor * peerDescriptor = _peers[peripheralIdentifierString];
    if (!peerDescriptor)
    {
        // Log.
        TSNLog(@"***** Problem: Unknown peer %@ updated characteristic", peripheralIdentifierString);
        return;
    }

    if ([[characteristic UUID] isEqual:_peerIDType])
    {
        TSNLog(@"Read peer ID");
        [peerDescriptor setPeerID:[[NSUUID alloc] initWithUUIDBytes:[[characteristic value] bytes]]];
    }
    else if ([[characteristic UUID] isEqual:_peerNameType])
    {
        TSNLog(@"Read peer name");
        [peerDescriptor setPeerName:[[NSString alloc] initWithData:[characteristic value]
                                                          encoding:NSUTF8StringEncoding]];
    }
    else
    {
        
    }
}

@end

// TSNPeerBluetoothContext (Internal) implementation.
@implementation TSNPeerBluetoothContext (Internal)

// Starts advertising.
- (void)startAdvertising
{
    if ([_peripheralManager state] == CBPeripheralManagerStatePoweredOn && [_atomicFlagEnabled isSet] && ![_peripheralManager isAdvertising])
    {
        [_peripheralManager addService:_service];
        [_peripheralManager startAdvertising:_advertisingData];
        TSNLog(@"Started advertising peer");
    }
}

// Stops advertising.
- (void)stopAdvertising
{
    if ([_peripheralManager isAdvertising])
    {
        [_peripheralManager removeAllServices];
        [_peripheralManager stopAdvertising];
        TSNLog(@"Stopped advertising peer");
    }
}

// Starts scanning.
- (void)startScanning
{
    if ([_centralManager state] == CBCentralManagerStatePoweredOn && [_atomicFlagEnabled isSet] && [_atomicFlagScanning trySet])
    {
        [_centralManager scanForPeripheralsWithServices:@[_serviceType]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(NO)}];
        TSNLog(@"Started scanning for peers");
    }
}

// Stops scanning.
- (void)stopScanning
{
    if ([_atomicFlagScanning tryClear])
    {
        [_centralManager stopScan];
        TSNLog(@"Stopped scanning for peers");
    }
}

@end
