//
//  GLBlueToothManager.h
//  02-蓝牙
//
//  Created by 钟国龙 on 2017/2/25.
//  Copyright © 2017年 guolong. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

//接收到外设发送数据的通知
#define kReceiveDataNotification @"kReceiveDataNotification"

#define GLBlueToothManagerShare [GLBlueToothManager shareInstance]

@interface GLBlueToothManager : NSObject


//外设
@property (strong, nonatomic)CBPeripheral *cb_Peripheral;
//蓝牙的特征
@property (strong, nonatomic)CBCharacteristic *cb_Characteristic;
//读写特征的UUID
@property (strong, nonatomic)NSString *cb_CharacteristicUUID;
//扫描到的外设数组
@property (strong, nonatomic)NSMutableArray<CBPeripheral *> *scanArrM;
//连接的外设数组
@property (strong, nonatomic)NSMutableArray<CBPeripheral *> *connectArrM;

//找到指定特征值的回调
@property (copy, nonatomic)void(^didDiscoverCharacteristicUUID)(void);

//单例类实现
+ (instancetype)shareInstance;
//1. 开始扫描
- (void)beginScanPeripheral:(void(^)(CBPeripheral *peripheral))scanBlock;

//2. 连接外设
- (void)connectPeripheral:(CBPeripheral *)peripheral Completion:(void(^)(CBPeripheral *peripheral,NSError *error))connectBlock;
//3. 发现特征
- (void)sendDataWithPeripheral:(CBPeripheral *)peripheral Characteristics:(CBCharacteristic *)characteristics Data:(NSData *)data;


@end
