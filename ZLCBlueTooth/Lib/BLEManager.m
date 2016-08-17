//
//  BLEManager.m
//  BTLE
//
//  Created by Nick Yang on 10/10/15.
//  Copyright (c) 2015 Nick Yang. All rights reserved.
//

#import "BLEManager.h"

#define CALLBACK_NONE 0
#define CALLBACK_RSSI 1
#define CALLBACK_SEND 2
#define CALLBACK_READ 3
#define CALLBACK_WRRS 4

@implementation BLEManager

@synthesize discoveredPeripherals;
@synthesize discoveredAdvertisements;

@synthesize delegate;

static BLEManager *manager = nil;

BOOL isConnecting;
int settedRSSI = defaultRSSI;

int lockCallBack = CALLBACK_NONE;

int currentRSSI;
NSData *currentData = nil;

NSError *writeResCode = nil;

NSString *currentService = nil;
NSString *currentCharacteristic = nil;

+ (BLEManager *)sharedManager
{
    return [self sharedManagerWithDelegate:nil];
}

+ (BLEManager *)sharedManagerWithDelegate:(id<BLEManagerDelegate>)delegate
{
	
    if(manager == nil)
    {
        manager = [[BLEManager alloc] initWithDelegate:delegate];
    }
    return manager;
}

- (void)disableBLEManager
{
    NSLog(@"disableBLEManager");
    if(manager != nil && self.delegate != nil)
    {
        [self.delegate BLEManagerDisabledDelegate];
    }
    self.delegate = nil;
    centralManager = nil;
    manager = nil;
}

- (id) initWithDelegate:(id<BLEManagerDelegate>)delegate
{
    self = [super init];
    if(self)
    {
        isConnecting = NO;
        self.delegate = delegate;
        discoveredPeripherals = [[NSMutableArray alloc] init];
		discoveredAdvertisements = [[NSMutableArray alloc] init];
    }
    return  self;
}

# pragma mark - CBCentralManager Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [centralManager scanForPeripheralsWithServices:nil options:nil];
        [NSTimer scheduledTimerWithTimeInterval:timeInverval target:self selector:@selector(scanBleTimeout:) userInfo:nil repeats:NO];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"peripheral:%@",peripheral);
//    NSLog(@"advertisementData:%@",advertisementData);
//    NSLog(@"RSSI:%@",RSSI);
    
    if(peripheral.identifier == nil || RSSI.intValue < settedRSSI)
    {
        return;
    }
        
    for(int i = 0; i < discoveredPeripherals.count; i++){
        CBPeripheral *p = [self.discoveredPeripherals objectAtIndex:i];
            
        if([peripheral.identifier.UUIDString isEqualToString:p.identifier.UUIDString]){
            [self.discoveredPeripherals replaceObjectAtIndex:i withObject:peripheral];
//            NSLog(@"Duplicate UUID found updating...");
            return;
        }
    }
	
	
	
	    //查看数组中是否已经包含advertisementData
		if ([discoveredAdvertisements containsObject:advertisementData]) {
			return;
		}
		
	
	
	
	
    [self.discoveredPeripherals addObject:peripheral];
	[self.discoveredAdvertisements addObject:advertisementData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"didConnectPeripheral");

	[self.delegate BLEManagerDidConnectPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didDisconnectPeripheral");
    lockCallBack = CALLBACK_NONE;
    writeResCode = [NSError errorWithDomain:@"" code:0 userInfo:@""];
    [self.delegate BLEManagerDisconnectPeripheral:peripheral error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    for(CBService *service in peripheral.services){
//        NSLog(@"service.UUID:%@",service.UUID.UUIDString);
//        if([currentService isEqualToString:service.UUID.UUIDString]){
//            NSArray *arr = [[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:currentCharacteristic], nil];
//            [peripheral discoverCharacteristics:arr forService:service];
//        }
        
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    NSLog(@"service.UUID:%@",service.UUID.UUIDString);
    for(CBCharacteristic *characteristic in service.characteristics){
        NSLog(@"characteristic.UUID:%@, current:%@",characteristic.UUID.UUIDString,currentCharacteristic);
    }
	
	[self.delegate BLEManagerReceiveAllService:service];
	
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didUpdateValueForCharacteristic");
//    NSLog(@"error(%d):%@", (int)error.code, [error localizedDescription]);
//    NSLog(@"data:%@", characteristic.value);
    
    switch (lockCallBack) {
        case CALLBACK_NONE:
            currentData = nil;
            currentService = nil;
            currentCharacteristic = nil;
            
            [self.delegate BLEManagerReceiveData:characteristic.value fromPeripheral:peripheral andServiceUUID:characteristic.service.UUID.UUIDString andCharacteristicUUID:characteristic.UUID.UUIDString];
            break;
        case CALLBACK_SEND:
        case CALLBACK_READ:
            currentData = characteristic.value;
            break;
        default:
            break;
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didWriteValueForCharacteristic");
//    NSLog(@"charUUID:%@, error:%@", characteristic.UUID.UUIDString, [error localizedDescription]);
    writeResCode = error == nil ? [NSError errorWithDomain:@"" code:0 userInfo:@""] : error;
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
                          error:(NSError *)error {
    
    NSLog(@"peripheral RSSI:%d",peripheral.RSSI.intValue);
    if(lockCallBack == CALLBACK_RSSI){
        currentRSSI = (int)peripheral.RSSI.integerValue;
    }
}

- (BOOL)isConnecting
{
    return isConnecting;
}

- (void)scanningForPeripherals
{
    settedRSSI = defaultRSSI;
    [discoveredPeripherals removeAllObjects];
	[discoveredAdvertisements removeAllObjects];
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)scanningForPeripheralsWithDistance:(int)RSSI
{
    settedRSSI = RSSI;
    [discoveredPeripherals removeAllObjects];
	[discoveredAdvertisements removeAllObjects];
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)scanBleTimeout:(NSTimer*)timer
{
    if (centralManager != NULL){
        [centralManager stopScan];
        
//        for(CBPeripheral *p in self.peripherals){
//            NSLog(@"peripheral.name:%@",p.name);
//        }
        [self.delegate BLEManagerReceiveAllPeripherals:self.discoveredPeripherals andAdvertisements:self.discoveredAdvertisements];
        
    }else{
        NSLog(@"CM is Null!");
    }
    NSLog(@"scanTimeout");
}

- (void)stopScanningForPeripherals
{
    [centralManager stopScan];
}

- (void)connectingPeripheral:(CBPeripheral *)peripheral
{
    if(isConnecting)
    {
        return;
    }
    
    isConnecting = YES;
    
    if(centralManager != nil)
    {
        peripheral.delegate = self;
        [centralManager connectPeripheral:peripheral options:nil];
        [centralManager stopScan];
    }
    else
    {
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral
{
    
    [centralManager stopScan];
    if (peripheral == nil){
        NSLog(@"connectPeripheral is NULL");
        return;
    }else if (peripheral.state == CBPeripheralStateConnected){
        [centralManager cancelPeripheralConnection:peripheral];
    }
}

- (int)readRSSI:(CBPeripheral *)peripheral
{
    if(peripheral.state != CBPeripheralStateConnected)
    {
        [self.delegate BLEManagerDisconnectPeripheral:peripheral error:nil];
        return 0;
    }else
    {
        [self waitingCallBack];
        lockCallBack = CALLBACK_RSSI;
        
        [peripheral readRSSI];
        
        int returnRSSI = 0;
        while(currentRSSI == 0 && lockCallBack == CALLBACK_RSSI){
             [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        lockCallBack = CALLBACK_NONE; // reset lockCallBack
        
        returnRSSI = currentRSSI;
        currentRSSI = 0;
        return returnRSSI;
    }
}

- (void)scanningForServicesWithPeripheral:(CBPeripheral *)peripheral{
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (NSError *) setValue:(NSData *) data forServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral
{
    if(isConnecting){
        peripheral.delegate = self;
        CBCharacteristic *characteristic = [self findCharacteristicWithServiceUUID:serviceUUID andCharacteristicUUID:charUUID andPeripheral:peripheral];
        if(characteristic == nil) return [NSError errorWithDomain:@"" code:0 userInfo:@""];
        NSLog(@"data:%@",data);
        NSLog(@"char.UUID:%@",characteristic.UUID.UUIDString);
        
        [self waitingCallBack];
        
        CBCharacteristicProperties properties = characteristic.properties;
        CBCharacteristicWriteType writeType = CBCharacteristicWriteWithoutResponse;
        if((properties & CBCharacteristicPropertyBroadcast) == CBCharacteristicPropertyBroadcast){
            NSLog(@"CBCharacteristicPropertyBroadcast");
        }
        if((properties & CBCharacteristicPropertyRead) == CBCharacteristicPropertyRead){
            NSLog(@"CBCharacteristicPropertyRead");
        }
        if((properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse){
            NSLog(@"CBCharacteristicPropertyWriteWithoutResponse");
            writeResCode = [NSError errorWithDomain:@"" code:0 userInfo:@""];
        }
        if((properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite){
            NSLog(@"CBCharacteristicPropertyWrite");
            writeType = CBCharacteristicWriteWithResponse;
            lockCallBack = CALLBACK_WRRS;
        }
        if((properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify){
            NSLog(@"CBCharacteristicPropertyNotify");
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        if((properties & CBCharacteristicPropertyIndicate) == CBCharacteristicPropertyIndicate){
            NSLog(@"CBCharacteristicPropertyIndicate");
        }
        if((properties & CBCharacteristicPropertyAuthenticatedSignedWrites) == CBCharacteristicPropertyAuthenticatedSignedWrites){
            NSLog(@"CBCharacteristicPropertyAuthenticatedSignedWrites");
        }
        if((properties & CBCharacteristicPropertyExtendedProperties) == CBCharacteristicPropertyExtendedProperties){
            NSLog(@"CBCharacteristicPropertyExtendedProperties");
        }
        
        [peripheral writeValue:data forCharacteristic:characteristic type:writeType];
        
        while(writeResCode == nil){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        lockCallBack = lockCallBack == CALLBACK_WRRS ? CALLBACK_NONE : lockCallBack; // reset lockCallBack
 
        NSError *rtn;
        rtn = writeResCode;
        writeResCode = nil;
        return rtn;
    }
    return [NSError errorWithDomain:@"" code:0 userInfo:@""];
}

- (NSData *)readValueForServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral
{
    if(isConnecting){
        CBCharacteristic *characteristic = [self findCharacteristicWithServiceUUID:serviceUUID andCharacteristicUUID:charUUID andPeripheral:peripheral];
        if(characteristic == nil) return nil;
        
        [self waitingCallBack];
        lockCallBack = CALLBACK_READ;
        [peripheral readValueForCharacteristic:characteristic];
        
        NSData *returnedData = nil;
        while(currentData == nil && lockCallBack == CALLBACK_READ){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        lockCallBack = CALLBACK_NONE; // reset lockCallBack
        
        returnedData = currentData;
        currentData = nil;
        return returnedData;
    }
    return  nil;
}

- (CBCharacteristic *)findCharacteristicWithServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID andPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    NSLog(@"peripheral.name:%@", peripheral.name);
    for(CBService *servie in peripheral.services){
        if([serviceUUID isEqualToString:servie.UUID.UUIDString]){
            NSLog(@"service.UUID:%@", servie.UUID.UUIDString);
            for(CBCharacteristic *characteristic in servie.characteristics){
                if([charUUID isEqualToString:characteristic.UUID.UUIDString]){
                    NSLog(@"char.UUID:%@",characteristic.UUID.UUIDString);
                    return characteristic;
                }
            }
        }
    }
    return nil;
    
}

- (void)waitingCallBack
{
    while(lockCallBack != CALLBACK_NONE){
        sleep(1);
    }
}

@end
