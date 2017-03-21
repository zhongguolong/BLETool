//
//  GLBlueToothManager.m
//  02-蓝牙
//
//  Created by 钟国龙 on 2017/2/25.
//  Copyright © 2017年 guolong. All rights reserved.
//

#import "GLBlueToothManager.h"

@interface GLBlueToothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>
//蓝牙中心
@property (strong, nonatomic)CBCentralManager *cb_CentralManager;
//扫描到外设的回调
@property (copy, nonatomic)void(^scanBlock)(CBPeripheral *peripheral) ;
//连接成功的回调
@property (nonatomic,copy)void(^connectBlock)(CBPeripheral *peripheral, NSError *error);

@end

@implementation GLBlueToothManager

+ (instancetype)shareInstance
{
    static GLBlueToothManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[GLBlueToothManager alloc] init];
    });
    return manager;
}

//只会在初始化的时候走一次,一般可以在这里初始化单例类的某些属性
- (instancetype)init
{
    self = [super init];
    if (self) {
        _scanArrM = [NSMutableArray array];
        _connectArrM = [NSMutableArray array];
    }
    return self;
}

- (BOOL)bluetoothIsAvailable
{
    //获取蓝牙硬件状态
    CBManagerState state = [self.cb_CentralManager state];
    /**
     CBManagerStateUnknown = 0,  //未知,第一次使用蓝牙会出现
     CBManagerStateResetting,    //与系统连接丢失,系统无法使用
     CBManagerStateUnsupported,  //系统无法使用,硬件损坏可能,设备部支持(iPhone4s之后)
     CBManagerStateUnauthorized, //未认证,未授权
     CBManagerStatePoweredOff,   //蓝牙关闭
     CBManagerStatePoweredOn,    //蓝牙开启
     */
    BOOL result = NO;
    switch (state)
    {
        case CBManagerStateUnknown:
            NSLog(@"第一次设备连接");
            break;
        case CBManagerStateResetting:
            NSLog(@"无法连接蓝牙");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"不支持");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"未授权");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"蓝牙关闭");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@"蓝牙开启");
            result = YES;
            break;
        default:
            break;
    }
    //第一次启动蓝牙是不可用状态
    if (state == CBManagerStateUnknown)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self beginScanPeripheral:self.scanBlock];
        });
        return YES;
    }
    
    return result;
}

#pragma mark - 1.开始扫描外设
- (void)beginScanPeripheral:(void (^)(CBPeripheral *))scanBlock
{
    //1. 创建蓝牙中心
    if (self.cb_CentralManager == nil)
    {
        self.cb_CentralManager = [[CBCentralManager alloc] init];
        self.cb_CentralManager.delegate = self;
    }
    
    //2. 判断当前设备蓝牙是否可用  第一个参数,判断条件,第二个参数:当条件不成立时,描述信息
    
    NSAssert([self bluetoothIsAvailable], @"当前蓝牙不可用");
    
    //3. 保存block
    _scanBlock = scanBlock;
    //4. 开始扫描
    /**
     参数一: 扫描指定设备服务,如果未nil则扫描所有设备
     参数二: 扫描属性 一般为nil 使用系统默认设置
     */
    [self.cb_CentralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - 3.连接外设
- (void)connectPeripheral:(CBPeripheral *)peripheral Completion:(void (^)(CBPeripheral *, NSError *))connectBlock
{
    //判断外设是否已连接
    if (self.cb_Peripheral.state == CBPeripheralStateConnected)
    {
        return;
    }
    //保存
    _connectBlock = connectBlock;
    //开始连接
    [self.cb_CentralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - 蓝牙中心代理
//蓝牙中心状态发生变化,该方法实际不参与蓝牙连接流程(必须实现的代理方法)
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
}

#pragma mark - 2. 扫描到外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"外设%@",peripheral);
    NSLog(@"外设的名字%@",peripheral.name);
    NSLog(@"外设宣传广告数据%@",advertisementData);
    NSLog(@"外设信号强度%@",RSSI);
    
    //1. 将扫描到的外设添加到扫描数组,用于外部UI展示
    if (![_scanArrM containsObject:peripheral])
    {
        [_scanArrM addObject:peripheral];
    }
    //2. 执行block回调
    if (_scanBlock)
    {
        _scanBlock(peripheral);
    }
}

#pragma mark - 4.连接外设成功
//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //1. 添加到连接数组中
    [self.connectArrM addObject:peripheral];
    //2. 赋值为当前连接的外设
    self.cb_Peripheral = peripheral;
    //3. 设置代理
    self.cb_Peripheral.delegate = self;
    //4. 开始发现外设服务 参数是指发现什么服务,如果为nil,就是指所有外设服务
    //MARK: 4.1开始发行外设的服务
    [self.cb_Peripheral discoverServices:nil];
    //5. 执行连接成功的回调
    if (_connectBlock) {
        _connectBlock(peripheral,nil);
    }
}
//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    
}
//与外设断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    
}

#pragma mark - 7. 给外设的特征发送数据
- (void)sendDataWithPeripheral:(CBPeripheral *)peripheral Characteristics:(CBCharacteristic *)characteristics Data:(NSData *)data
{
    //参数一: 发送的数据 参数二: 发送给谁(特征) 第三个参数:是否需要特征反馈
    /**
     CBCharacteristicWriteWithResponse = 0  需要反馈
     CBCharacteristicWriteWithoutResponse , 不需要反馈
     */
    //有的特征值读写时需要响应,有的特征值不需要响应,根据实际情况而定,如果写错,可能会报错,可以写数据的特征报错不能写
    [peripheral writeValue:data forCharacteristic:characteristics type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - CBPeripheralDelegate 外设代理
//MARK: 4.2发现外设服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSLog(@"%@",peripheral.services);
    
    for (CBService *service in peripheral.services)
    {
        NSLog(@"服务的UUID:%@",service.UUID);
        //寻找服务的特征
        //参数一: 指定特征(nil 寻找服务的所有特征) 参数二: 指定服务 (当前已经发现特征)
#pragma mark - 5.寻找服务的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

#pragma mark - 6.发现特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    NSLog(@"发现特征的服务UUID:%@",service.UUID);
    for (CBCharacteristic *character in service.characteristics)
    {
        NSLog(@"特征的UUID:%@",character.UUID);
        //判断该特征是否是当前想要读写的特征
        if ([[character.UUID UUIDString] isEqualToString:self.cb_CharacteristicUUID])
        {
            _cb_Characteristic = character;
            //开始读写特征的服务
            //一次性读写特征数据
            //[self.cb_Peripheral readValueForCharacteristic:character];
            //使用通知的形式读写特征的数据(建立长连接
            [self.cb_Peripheral setNotifyValue:YES forCharacteristic:character];
            
            //送出找到指定特征值的回调
            if (_didDiscoverCharacteristicUUID) {
                _didDiscoverCharacteristicUUID();
            }
        }
    }
}

//给外设发送数据
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"发送成功");
}

//读取到特征的数据(无论是read方式还是notify方式都会走这个方法)
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    //NSLog(@"特征的数据:%@",characteristic.UUID.data);
    NSLog(@"特征发送过来的值:%@",characteristic.value);
    
    //实际开发中,我们以消息机制将设备发送给我们的数据交给外部使用
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveDataNotification object:nil userInfo:@{@"value":characteristic.value}];
}

@end
