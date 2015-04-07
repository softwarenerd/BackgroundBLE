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

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheralManager+Extensions.h"
#import "CBPeripheral+Extensions.h"
#import "CBCentralManager+Extensions.h"
#import "TSNThreading.h"
#import "TSNAtomicFlag.h"
#import "TSNLogger.h"
#import "TSNPeerBluetoothContext.h"

// Logging.
static inline void Log(NSString * format, ...)
{
    // Format the log entry.
    va_list args;
    va_start(args, format);
    NSString * formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    // Append the log entry.
    TSNLog([NSString stringWithFormat:@" TSNPeerBluetoothContext: %@", formattedString]);
}

// TSNPeerDescriptor interface.
@interface TSNPeerDescriptor : NSObject

// Properties.
@property (nonatomic) NSString * peerName;

// Class initializer.
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;

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

// Updates the last location characteristic.
- (void)updateLastLocationCharacteristic;

@end

// TSNPeerBluetoothContext implementation.
@implementation TSNPeerBluetoothContext
{
@private
    // The operation queue.
    dispatch_queue_t _operationQueue;

    // The peer name.
    NSString * _peerName;
    
    // The canonical peer name.
    NSData * _canonicalPeerName;
    
    // The enabled atomic flag.
    TSNAtomicFlag * _atomicFlagEnabled;
    
    // The scanning atomic flag.
    TSNAtomicFlag * _atomicFlagScanning;

    // The service UUID.
    CBUUID * _cbuuidService;
    
    // The peer name characteristic UUID.
    CBUUID * _cbuuidCharacteristicPeerName;

    // The location characteristic UUID.
    CBUUID * _cbuuidCharacteristicLocation;
    
    // The service.
    CBMutableService * _service;
    
    // The location characteristic.
    CBMutableCharacteristic * _characteristicPeerName;

    // The location characteristic.
    CBMutableCharacteristic * _characteristicLocation;
    
    // The advertising data.
    NSDictionary * _advertisingData;
    
    // The peripheral manager.
    CBPeripheralManager * _peripheralManager;
    
    // The central manager.
    CBCentralManager * _centralManager;
    
    // The connecting peers dictionary.
    NSMutableDictionary * _connectingPeers;

    // The connected peers dictionary.
    NSMutableDictionary * _connectedPeers;
    
    // The last location coordinate.
    CLLocationCoordinate2D _lastLocationCoordinate;
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
    
    // Initialize.
    _operationQueue = dispatch_queue_create("com.yackalskdhjaksd", DISPATCH_QUEUE_SERIAL);

    // Initialize.
    _peerName = peerName;
    _canonicalPeerName = [_peerName dataUsingEncoding:NSUTF8StringEncoding];
    
    // Allocate and initialize the enabled atomic flag.
    _atomicFlagEnabled = [[TSNAtomicFlag alloc] init];
    
    // Allocate and initialize the scanning atomic flag.
    _atomicFlagScanning = [[TSNAtomicFlag alloc] init];

    // Allocate and initialize the service UUID.
    _cbuuidService = [CBUUID UUIDWithString:@"B206EE5D-17EE-40C1-92BA-462A038A33D2"];
    
    // Allocate and initialize the peer name characteristic UUID.
    _cbuuidCharacteristicPeerName = [CBUUID UUIDWithString:@"2EFDAD55-5B85-4C78-9DE8-07884DC051FA"];

    // Allocate and initialize the location characteristic UUID.
    _cbuuidCharacteristicLocation = [CBUUID UUIDWithString:@"B080D422-5B7D-430B-9F75-1D1D7D264197"];
    
    // Allocate and initialize the service.
    _service = [[CBMutableService alloc] initWithType:_cbuuidService
                                              primary:YES];
    
    // Allocate and initialize the peer name characteristic.
    _characteristicPeerName = [[CBMutableCharacteristic alloc] initWithType:_cbuuidCharacteristicPeerName
                                                                 properties:CBCharacteristicPropertyRead
                                                                      value:_canonicalPeerName
                                                                permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the location characteristic.
    _characteristicLocation = [[CBMutableCharacteristic alloc] initWithType:_cbuuidCharacteristicLocation
                                                         properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead
                                                              value:nil
                                                        permissions:CBAttributePermissionsReadable];

    // Set the service characteristics.
    [_service setCharacteristics:@[_characteristicPeerName,
                                   _characteristicLocation]];
    
    // Allocate and initialize the advertising data.
    _advertisingData = @{CBAdvertisementDataServiceUUIDsKey:    @[_cbuuidService],
                         CBAdvertisementDataLocalNameKey:       [[UIDevice currentDevice] name]};
    
    // Allocate and initialize the peripheral manager.
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    // Allocate and initialize the central manager.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:(id<CBCentralManagerDelegate>)self
                                                           queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    // Allocate and initialize the connected peers dictionary. It contains a TSNPeerDescriptor for
    // every peer we are connected to.
    _connectedPeers = [[NSMutableDictionary alloc] init];

    // Allocate and initialize the connecting peers dictionary. It contains a TSNPeerDescriptor for
    // every peer we are connecting to.
    _connectingPeers = [[NSMutableDictionary alloc] init];

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

// Updates the location.
- (void)updateLocation:(CLLocation *)location
{
    _lastLocationCoordinate = [location coordinate];
    [self updateLastLocationCharacteristic];
}

@end

// TSNPeerBluetoothContext (CBPeripheralManagerDelegate) implementation.
@implementation TSNPeerBluetoothContext (CBPeripheralManagerDelegate)

/*!
 *  @method peripheralManagerDidUpdateState:
 *
 *  @param peripheral   The peripheral manager whose state has changed.
 *
 *  @discussion         Invoked whenever the peripheral manager's state has been updated. Commands should only be issued when the state is
 *                      <code>CBPeripheralManagerStatePoweredOn</code>. A state below <code>CBPeripheralManagerStatePoweredOn</code>
 *                      implies that advertisement has paused and any connected centrals have been disconnected. If the state moves below
 *                      <code>CBPeripheralManagerStatePoweredOff</code>, advertisement is stopped and must be explicitly restarted, and the
 *                      local database is cleared and all services must be re-added.
 *
 *  @see                state
 *
 */
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

/*!
 *  @method peripheralManager:willRestoreState:
 *
 *  @param peripheral	The peripheral manager providing this information.
 *  @param dict			A dictionary containing information about <i>peripheral</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBPeripheralManagerRestoredStateServicesKey;
 *  @seealso            CBPeripheralManagerRestoredStateAdvertisementDataKey;
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
         willRestoreState:(NSDictionary *)dict
{
}

/*!
 *  @method peripheralManagerDidStartAdvertising:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
 *                      not be started, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager
                                       error:(NSError *)error
{
    if (error)
    {
        Log(@"Advertising peer failed (%@)", [error localizedDescription]);
    }
}

/*!
 *  @method peripheralManager:didAddService:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param service      The service that was added to the local database.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
 *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    if (error)
    {
        Log(@"Adding service failed (%@)", [error localizedDescription]);
    }
}

/*!
 *  @method peripheralManager:central:didSubscribeToCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were enabled.
 *
 *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
 *                          It should be used as a cue to start sending updates as the characteristic value changes.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // Request low latency.
    [_peripheralManager setDesiredConnectionLatency:CBPeripheralManagerConnectionLatencyLow
                                         forCentral:central];
}

/*!
 *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were disabled.
 *
 *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
}

/*!
 *  @method peripheralManager:didReceiveReadRequest:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param request      A <code>CBATTRequest</code> object.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
}

/*!
 *  @method peripheralManager:didReceiveWriteRequests:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
 *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
 *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray *)requests
{
}

/*!
 *  @method peripheralManagerIsReadyToUpdateSubscribers:
 *
 *  @param peripheral   The peripheral manager providing this update.
 *
 *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
 *                      ready to send characteristic value updates.
 *
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    Log(@"Ready to update subscribers.");
}

@end

// TSNPeerBluetoothContext (CBCentralManagerDelegate) implementation.
@implementation TSNPeerBluetoothContext (CBCentralManagerDelegate)

/*!
 *  @method centralManagerDidUpdateState:
 *
 *  @param central  The central manager whose state has changed.
 *
 *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
 *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
 *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
 *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
 *                  manager become invalid and must be retrieved or discovered again.
 *
 *  @see            state
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([_centralManager state] == CBCentralManagerStatePoweredOn)
    {
        [self startScanning];
    }
    else
    {
        [self stopScanning];
    }
}

/*!
 *  @method centralManager:willRestoreState:
 *
 *  @param central      The central manager providing this information.
 *  @param dict			A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
 *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
 *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
 *
 */
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)dict
{
}

/*!
 *  @method centralManager:didRetrievePeripherals:
 *
 *  @param central      The central manager providing this information.
 *  @param peripherals  A list of <code>CBPeripheral</code> objects.
 *
 *  @discussion         This method returns the result of a {@link retrievePeripherals} call, with the peripheral(s) that the central manager was
 *                      able to match to the provided UUID(s).
 *
 */
- (void)centralManager:(CBCentralManager *)centralManager
didRetrievePeripherals:(NSArray *)peripherals
{
}

/*!
 *  @method centralManager:didRetrieveConnectedPeripherals:
 *
 *  @param central      The central manager providing this information.
 *  @param peripherals  A list of <code>CBPeripheral</code> objects representing all peripherals currently connected to the system.
 *
 *  @discussion         This method returns the result of a {@link retrieveConnectedPeripherals} call.
 *
 */
- (void)centralManager:(CBCentralManager *)centralManager
didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
}

/*!
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param central              The central manager providing this update.
 *  @param peripheral           A <code>CBPeripheral</code> object.
 *  @param advertisementData    A dictionary containing any advertisement and scan response data.
 *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
 *								was not available.
 *
 *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
 *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
 *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
 *
 *  @seealso                    CBAdvertisementData.h
 *
 */
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    // If we are not connected or connecting to this peer, connect to it.
    NSString * peripheralIdentifierString = [peripheral identifierString];
    
    if (_connectedPeers[peripheralIdentifierString])
    {
        Log(@"Discovered peer %@ that we're already connected to", peripheralIdentifierString);
    }
    else if (_connectingPeers[peripheralIdentifierString])
    {
        Log(@"Discovered peer %@ that we're already connecting to", peripheralIdentifierString);
    }
    
    if (!_connectedPeers[peripheralIdentifierString] && !_connectingPeers[peripheralIdentifierString])
    {
        // Log.
        Log(@"Discovered peer %@ named %@", peripheralIdentifierString, [peripheral name]);
#if false
        // Log.
        Log(@"Discovered peer %@ and connecting", peripheralIdentifierString);
        

        // Add a TSNPeerDescriptor to the connecting peers dictionary.
        [_connectingPeers setObject:[[TSNPeerDescriptor alloc] initWithPeripheral:peripheral]
                             forKey:peripheralIdentifierString];
        
        // Connect to the peripheral.
        [_centralManager connectPeripheral:peripheral
                                   options:nil];
#endif
    }
}

/*!
 *  @method centralManager:didConnectPeripheral:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has connected.
 *
 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
 *
 */
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [peripheral identifierString];

    // Log.
    Log(@"Connected to peer %@", peripheralIdentifierString);
    
    // Move the peer from connecting to connected.
    TSNPeerDescriptor * peerDescriptor = [_connectingPeers objectForKey:peripheralIdentifierString];
    if (peerDescriptor)
    {
        [_connectingPeers removeObjectForKey:peripheralIdentifierString];
        [_connectedPeers setObject:[[TSNPeerDescriptor alloc] initWithPeripheral:peripheral]
                            forKey:peripheralIdentifierString];
    }
    else
    {
        Log(@"!!!!!!!!!!!!!!BAD! We didn't have the peer in connecting peers when it connected!!!!!!!!!!!!!!");
        [_connectedPeers setObject:[[TSNPeerDescriptor alloc] initWithPeripheral:peripheral]
                            forKey:peripheralIdentifierString];
    }
    
    // Set our delegate on the peripheral and discover services.
    [peripheral setDelegate:(id<CBPeripheralDelegate>)self];
    [peripheral discoverServices:@[_cbuuidService]];
}

/*!
 *  @method centralManager:didFailToConnectPeripheral:error:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
 *  @param error        The cause of the failure.
 *
 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
 *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSString * peripheralIdentifierString = [peripheral identifierString];

    // Log.
    Log(@"Unable to connect to peer %@ (%@)", peripheralIdentifierString, [error localizedDescription]);
    
    // Immediately issue another connect.
    if ([_connectingPeers objectForKey:peripheralIdentifierString])
    {
        [_connectingPeers removeObjectForKey:peripheralIdentifierString];
    }
    else
    {
        Log(@"!!!!!!!!!!!!!!BAD! We didn't have the peer in connecting peers when we couldn't connect!!!!!!!!!!!!!!");
    }
}

/*!
 *  @method centralManager:didDisconnectPeripheral:error:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
 *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
 *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSString * peripheralIdentifierString = [peripheral identifierString];

    // Log.
    if (error)
    {
        Log(@"Lost connection to peer %@ (%@)", peripheralIdentifierString, [error localizedDescription]);
    }
    else
    {
        Log(@"Lost connection to peer %@", peripheralIdentifierString);
    }
    
    TSNPeerDescriptor * peerDescriptor = [_connectedPeers objectForKey:peripheralIdentifierString];
    if (peerDescriptor)
    {
        
        // Move the peer from connected to connecting and immediately issue another connect.
        [_connectedPeers removeObjectForKey:peripheralIdentifierString];
        
//        [_connectingPeers setObject:[[TSNPeerDescriptor alloc] initWithPeripheral:peripheral]
//                             forKey:peripheralIdentifierString];
//        [_centralManager connectPeripheral:peripheral
//                                   options:nil];
        
        // Notify the delegate.
        if ([peerDescriptor peerName])
        {
            if ([[self delegate] respondsToSelector:@selector(peerBluetoothContext:didDisconnectFromPeerName:)])
            {
                [[self delegate] peerBluetoothContext:self didDisconnectFromPeerName:[peerDescriptor peerName]];
            }
        }
    }
    else
    {
        Log(@"!!!!!!!!!!!!!!BAD! We didn't have the peer in connected peers when it disconnected!!!!!!!!!!!!!!");
    }
}

@end

// TSNPeerBluetoothContext (CBPeripheralDelegate) implementation.
@implementation TSNPeerBluetoothContext (CBPeripheralDelegate)

/*!
 *  @method peripheralDidUpdateName:
 *
 *  @param peripheral	The peripheral providing this update.
 *
 *  @discussion			This method is invoked when the @link name @/link of <i>peripheral</i> changes.
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
}

/*!
 *  @method peripheral:didModifyServices:
 *
 *  @param peripheral			The peripheral providing this update.
 *  @param invalidatedServices	The services that have been invalidated
 *
 *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
 *						At this point, the designated <code>CBService</code> objects have been invalidated.
 *						Services can be re-discovered via @link discoverServices: @/link.
 */
- (void)peripheral:(CBPeripheral *)peripheral
 didModifyServices:(NSArray *)invalidatedServices
{
}

/*!
 *  @method peripheralDidUpdateRSSI:error:
 *
 *  @param peripheral	The peripheral providing this update.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link readRSSI: @/link call.
 */
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
                          error:(NSError *)error
{
}

/*!
 *  @method peripheral:didDiscoverServices:
 *
 *  @param peripheral	The peripheral providing this information.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
 *						<i>peripheral</i>'s @link services @/link property.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    // Process the services.
    for (CBService * service in [peripheral services])
    {
        // If this is our service, discover its characteristics.
        if ([[service UUID] isEqual:_cbuuidService])
        {
            [peripheral discoverCharacteristics:@[_cbuuidCharacteristicPeerName,
                                                  _cbuuidCharacteristicLocation]
                                     forService:service];
        }
    }
}

/*!
 *  @method peripheral:didDiscoverIncludedServicesForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the included services.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverIncludedServicesForService:(CBService *)service
             error:(NSError *)error
{
}

/*!
 *  @method peripheral:didDiscoverCharacteristicsForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the characteristic(s).
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    // If this is our service, process its discovered characteristics.
    if ([[service UUID] isEqual:_cbuuidService])
    {
        for (CBCharacteristic * characteristic in [service characteristics])
        {
            if ([[characteristic UUID] isEqual:_cbuuidCharacteristicPeerName])
            {
                Log(@"Reading peer name characteristic");
                [peripheral readValueForCharacteristic:characteristic];
            }
            else if ([[characteristic UUID] isEqual:_cbuuidCharacteristicLocation])
            {
                Log(@"Subscribing to location characteristic");
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
        }
    }
}

/*!
 *  @method peripheral:didUpdateValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    // Process the characteristic.
    if ([[characteristic UUID] isEqual:_cbuuidCharacteristicPeerName])
    {
        // If we received the value, process it.
        if ([characteristic value])
        {
            // Get the peer name.
            NSString * peerName = [[NSString alloc] initWithData:[characteristic value]
                                                        encoding:NSUTF8StringEncoding];
            
            Log(@"Read peer name characteristic %@", peerName);

            // Update the peer descriptor.
            TSNPeerDescriptor * peerDescriptor = _connectedPeers[[peripheral identifierString]];
            if (peerDescriptor)
            {
                // Update the peer descriptor name.
                [peerDescriptor setPeerName:peerName];
                
                // Notify the delegate.
                if ([[self delegate] respondsToSelector:@selector(peerBluetoothContext:didConnectToPeerName:)])
                {
                    [[self delegate] peerBluetoothContext:self didConnectToPeerName:peerName];
                }
            }
        }
    }
    else if ([[characteristic UUID] isEqual:_cbuuidCharacteristicLocation])
    {
        Log(@"Update received for location characteristic");
        UInt8 * data = (UInt8 *)[[characteristic value] bytes];

        CLLocationCoordinate2D * location = (CLLocationCoordinate2D *)data;
        data += sizeof(CLLocationCoordinate2D);
        
        UInt8 * length = data++;

        NSString * peerName = [[NSString alloc] initWithBytes:data length:*length encoding:NSUTF8StringEncoding];
        
        Log(@"%@ is at %0.4f, %0.4f", peerName, location->latitude, location->longitude);
        
        if ([[self delegate] respondsToSelector:@selector(peerBluetoothContext:didReceiveLocation:forPeerName:)])
        {
            [[self delegate] peerBluetoothContext:self
                               didReceiveLocation:[[CLLocation alloc] initWithLatitude:location->latitude longitude:location->longitude]
                                      forPeerName:peerName];
        }
    }
}

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
}

/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
}

/*!
 *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
 *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
}

/*!
 *  @method peripheral:didUpdateValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForDescriptor:(CBDescriptor *)descriptor
             error:(NSError *)error
{
}

/*!
 *  @method peripheral:didWriteValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForDescriptor:(CBDescriptor *)descriptor
             error:(NSError *)error
{
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
        Log(@"Started advertising peer");
    }
}

// Stops advertising.
- (void)stopAdvertising
{
    if ([_peripheralManager isAdvertising])
    {
        [_peripheralManager removeAllServices];
        [_peripheralManager stopAdvertising];
        Log(@"Stopped advertising peer");
    }
}

// Starts scanning.
- (void)startScanning
{
    if ([_centralManager state] == CBCentralManagerStatePoweredOn && [_atomicFlagEnabled isSet] && [_atomicFlagScanning trySet])
    {
        [_centralManager scanForPeripheralsWithServices:@[_cbuuidService]
                                                options:@{CBCentralManagerOptionShowPowerAlertKey: @(YES),
                                                          CBCentralManagerScanOptionAllowDuplicatesKey: @(NO)}];
        Log(@"Started scanning for peers");
    }
}

// Stops scanning.
- (void)stopScanning
{
    if ([_atomicFlagScanning tryClear])
    {
        [_centralManager stopScan];
        Log(@"Stopped scanning for peers");
    }
}

// Updates the last location characteristic.
- (void)updateLastLocationCharacteristic
{
    if ([_connectedPeers count] && [_atomicFlagEnabled isSet])
    {
        NSMutableData * data = [[NSMutableData alloc] initWithCapacity:(sizeof(CLLocationDegrees) * 2) + sizeof(UInt8) + [_peerName length]];
        [data appendBytes:&_lastLocationCoordinate.latitude
                   length:sizeof(_lastLocationCoordinate.latitude)];
        [data appendBytes:&_lastLocationCoordinate.longitude
                   length:sizeof(_lastLocationCoordinate.longitude)];
        UInt8 length = [_canonicalPeerName length];
        [data appendBytes:&length length:1];
        [data appendData:_canonicalPeerName];

        [_peripheralManager updateValue:data
                      forCharacteristic:_characteristicLocation
                   onSubscribedCentrals:nil];
    }
}

@end
