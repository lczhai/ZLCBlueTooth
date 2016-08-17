//
//  BLEManager.h
//  BTLE
//
//  Created by Nick Yang on 10/10/15.
//  Copyright (c) 2015 Nick Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define timeInverval 2.0f // timeount for scanning peripherals
#define defaultRSSI -100 // signal of blue device for detecting

@class BLEManager;
@protocol BLEManagerDelegate <NSObject>

@required
- (void)BLEManagerDisabledDelegate;

@optional
- (void)BLEManagerReceiveAllPeripherals:(NSMutableArray *) peripherals;
- (void)BLEManagerReceiveAllService:(CBService *) service;
- (void)BLEManagerDidConnectPeripheral:(CBPeripheral *)peripheral;
- (void)BLEManagerDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)BLEManagerReceiveData:(NSData *) value fromPeripheral:(CBPeripheral *)peripheral andServiceUUID:(NSString *)serviceUUID andCharacteristicUUID:(NSString *)charUUID;

@end

@interface BLEManager : NSObject <CBCentralManagerDelegate,CBPeripheralManagerDelegate,CBPeripheralDelegate>
{
    CBCentralManager *centralManager;
}

@property (strong,nonatomic) NSMutableArray *discoveredPeripherals;

@property (assign,nonatomic) id<BLEManagerDelegate> delegate;

//初始化对象
+ (BLEManager *)sharedManagerWithDelegate:(id<BLEManagerDelegate>)delegate; // inital
//重用对象（单例）
+ (BLEManager *)sharedManager; // singleton

//让对象失效
- (void)disableBLEManager; // disable delegate
//检查设备蓝牙连接状态
- (BOOL)isConnecting;
//扫描装置
- (void)scanningForPeripherals;
//扫描所有设备的限制距离
- (void)scanningForPeripheralsWithDistance:(int)RSSI;
//停止扫描装置
- (void)stopScanningForPeripherals;
//连接指定设备
- (void)connectingPeripheral:(CBPeripheral *)peripheral;
//断开指定设备
- (void)disconnectPeripheral:(CBPeripheral *)peripheral;
//获取接收设备的信号强度
- (int)readRSSI:(CBPeripheral *)peripheral;
//扫描设置中的所有服务
- (void)scanningForServicesWithPeripheral:(CBPeripheral *)peripheral;

// after discovering services and characteristics
//写入数据到设备
- (NSError *)setValue:(NSData *) data forServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral;
//从设备读取数据
- (NSData *)readValueForServiceUUID:(NSString *) serviceUUID andCharacteristicUUID:(NSString *) charUUID withPeripheral:(CBPeripheral *)peripheral;

@end
