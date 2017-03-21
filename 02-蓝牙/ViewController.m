//
//  ViewController.m
//  02-蓝牙
//
//  Created by 钟国龙 on 2017/2/25.
//  Copyright © 2017年 guolong. All rights reserved.
//

#import "ViewController.h"
#import "GLBlueToothManager.h"

static NSString *const identifier = @"identifier";
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (IBAction)beginScanClick:(id)sender
{
    [GLBlueToothManagerShare beginScanPeripheral:^(CBPeripheral *peripheral) {
        [self.tableView reloadData];
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return GLBlueToothManagerShare.scanArrM.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    //展示外设的数据
    //1. 获取对应cell的外设
    CBPeripheral *peripheral = GLBlueToothManagerShare.scanArrM[indexPath.row];
    //2. 展示数据
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = [peripheral.identifier UUIDString];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //1. 指定需要发送数据的特征值UUID,实际开发中根据蓝牙协议来发送
    GLBlueToothManagerShare.cb_CharacteristicUUID = @"2A06";
    
    //2. 获取点击的外设
    CBPeripheral *peripheral = GLBlueToothManagerShare.scanArrM[indexPath.row];
    //3. 连接外设
    [GLBlueToothManagerShare connectPeripheral:peripheral Completion:^(CBPeripheral *peripheral, NSError *error) {
        if (error == nil) {
            NSLog(@"连接成功");
        }
        //4.开始发送数据
        //应该使用异步操作,因为我们的外设连接成功之后需要搜索服务和特征,需要时间,实际开发中我们使用block的形式或者通知的形式来告知外部发现外设成功
        GLBlueToothManagerShare.didDiscoverCharacteristicUUID = ^{
            Byte *byte[1];
            byte[0] = 2 & 0xff;
            NSData *data = [NSData dataWithBytes:byte length:1];
            [GLBlueToothManagerShare sendDataWithPeripheral:GLBlueToothManagerShare.cb_Peripheral Characteristics:GLBlueToothManagerShare.cb_Characteristic Data:data];
        };
    }];
}


@end
