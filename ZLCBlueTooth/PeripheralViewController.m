//
//  PeripheralViewController.m
//  ZLCBlueTooth
//
//  Created by shining3d on 16/8/17.
//  Copyright © 2016年 shining3d. All rights reserved.
//

#import "PeripheralViewController.h"

@interface PeripheralViewController ()

@end

@implementation PeripheralViewController
{
	NSMutableArray *thisServices;
	UITableView    *thisServiceTableView;
	
	
	
	
}


@synthesize serviceTF;
@synthesize characteristicTF;
@synthesize contentTF;
@synthesize notifyLabel;


@synthesize periperal;//当前的设备

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	
	[self setTableView];//设置tableview
	[self setUUIDInputAndSengButton];//设置输入框及发送按钮
	
	[BLEManager sharedManagerWithDelegate:self];//初始化
	[BLEManager sharedManager].delegate  =self;
	
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[[BLEManager sharedManager] connectingPeripheral:periperal];//连接设备
}

# pragma mark - BLEManager Methods
- (void)BLEManagerDisabledDelegate {
	
}

#pragma mark --蓝牙连接完成
- (void)BLEManagerDidConnectPeripheral:(CBPeripheral *)peripheral
{
	CBPeripheral *connctedPeripheral = peripheral;//当前连接成功的设备
	[SVProgressHUD showSuccessWithStatus:@"连接成功"];
	
	
	//扫描当前连接的蓝牙设备的所有服务
	[[BLEManager sharedManager] scanningForServicesWithPeripheral:connctedPeripheral];

}

#pragma mark --接受获取到得服务
- (void)BLEManagerReceiveAllService:(CBService *)service
{
	[thisServices addObject:service];
	[thisServiceTableView reloadData];
}


#pragma mark --蓝牙连接失败
- (void)BLEManagerDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
	NSLog(@"蓝牙连接失败，请重新连接");
}

#pragma mark --接受数据返回的信息及广播
- (void)BLEManagerReceiveData:(NSData *)value fromPeripheral:(CBPeripheral *)peripheral andServiceUUID:(NSString *)serviceUUID andCharacteristicUUID:(NSString *)charUUID
{
	NSString *backString = [[NSString alloc]initWithData:value encoding:NSUTF8StringEncoding];
	
	
	notifyLabel.text = backString;
	
}












#pragma mark --设置uuid及发送按钮
- (void)setUUIDInputAndSengButton
{
	 serviceTF = [[UITextField alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(thisServiceTableView.frame)-54, 200, 30)];
	serviceTF.layer.borderWidth = 1;
	serviceTF.layer.borderColor = [UIColor grayColor].CGColor;
	serviceTF.placeholder = @"输入服务的uuid";
	[self.view addSubview:serviceTF];
	
	characteristicTF = [[UITextField alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(serviceTF.frame)+10, 200, 30)];
	characteristicTF.layer.borderWidth = 1;
	characteristicTF.layer.borderColor = [UIColor grayColor].CGColor;
	characteristicTF.placeholder = @"输入特征的uuid";
	[self.view addSubview:characteristicTF];
	
	contentTF = [[UITextField alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(characteristicTF.frame)+10, 200, 30)];
	contentTF.layer.borderWidth = 1;
	contentTF.layer.borderColor = [UIColor grayColor].CGColor;
	contentTF.placeholder = @"输入发送内容";
	[self.view addSubview:contentTF];
	
	
     UILabel	*notifyAlert = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(contentTF.frame)+20, self.view.frame.size.width-20, 30)];
	notifyAlert.textAlignment = NSTextAlignmentCenter;
	notifyAlert.textColor = [UIColor blueColor];
	notifyAlert.text = @"返回及订阅的消息：";
	[self.view addSubview:notifyAlert];
	
	
	
	notifyLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(notifyAlert.frame)+3, self.view.frame.size.width-20, 30)];
	notifyLabel.textAlignment = NSTextAlignmentCenter;
	notifyLabel.textColor = [UIColor blueColor];
	[self.view addSubview:notifyLabel];
	
	
	
	//初始化键盘修复类
	_keyboardUtil = [[ZYKeyboardUtil alloc] init];
	__weak PeripheralViewController *weakSelf = self;
	//全自动键盘弹出处理 (需调用keyboardUtil 的 adaptiveViewHandleWithController:adaptiveView:)
#pragma explain - use animateWhenKeyboardAppearBlock, animateWhenKeyboardAppearAutomaticAnimBlock will be invalid.
	[_keyboardUtil setAnimateWhenKeyboardAppearAutomaticAnimBlock:^(ZYKeyboardUtil *keyboardUtil) {
		[keyboardUtil adaptiveViewHandleWithController:weakSelf adaptiveView:weakSelf.serviceTF,weakSelf.characteristicTF,weakSelf.contentTF, nil];
	}];
	
	
	
	
	UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(serviceTF.frame)+10, CGRectGetMaxY(serviceTF.frame)-15, 80, 80)];
	[btn setTitle:@"发送" forState:UIControlStateNormal];
	[btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	btn.backgroundColor = [UIColor greenColor];
	[btn addTarget:self action:@selector(btn_Click:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btn];
}
#pragma mark -- 按钮点击事件
- (void)btn_Click:(UIButton *)sender
{
	[self.view endEditing:YES];
	NSData *sendData  =  [contentTF.text dataUsingEncoding:NSUTF8StringEncoding];//数据
	[[BLEManager sharedManager] setValue:sendData forServiceUUID:serviceTF.text andCharacteristicUUID:characteristicTF.text withPeripheral:periperal];//发送消息到设备
}




#pragma mark --根据蓝牙设备数据设置tableview
- (void)setTableView
{
	self.automaticallyAdjustsScrollViewInsets = YES;
	self.edgesForExtendedLayout               = UIRectEdgeNone;
	
	//初始化数据数组
	thisServices = [[NSMutableArray alloc]init];
	
	thisServiceTableView                         = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*0.6) style:UITableViewStylePlain];
	thisServiceTableView.delegate                = self;
	thisServiceTableView.dataSource              = self;
	thisServiceTableView.tableFooterView         = [[UIView alloc]init];
	[self.view addSubview:thisServiceTableView];
	
	thisServiceTableView.layer.borderColor = [UIColor blackColor].CGColor;
	thisServiceTableView.layer.borderWidth = 1;
	
	//让底部不被遮挡
	thisServiceTableView.autoresizingMask  = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return thisServices.count;
}
-  (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	CBService *service = thisServices[section];
	return service.characteristics.count;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	
	
	CBService *service = thisServices[section];//获取到服务
	UIButton *headerbutton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
	[headerbutton setTitle:[NSString stringWithFormat:@"服务UUID：%@",service.UUID.UUIDString] forState:UIControlStateNormal];
	headerbutton.titleLabel.textColor = [UIColor whiteColor];
	headerbutton.backgroundColor = [UIColor blackColor];
	
	[headerbutton sizeToFit];
	headerbutton.tag = section;
	
	[headerbutton addTarget:self action:@selector(clickOnSectionHeader:) forControlEvents:UIControlEventTouchUpInside];
	
	
	return headerbutton;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 40;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	}
	
	CBService *service = thisServices[indexPath.section];//获取到服务
	CBCharacteristic *characteristic = service.characteristics[indexPath.row];
	cell.textLabel.text = characteristic.UUID.UUIDString;//将设备名显示到cell
	[cell.textLabel sizeToFit];
	
	return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	CBService *service = thisServices[indexPath.section];//获取到服务
	CBCharacteristic *characteristic = service.characteristics[indexPath.row];
	characteristicTF.text = characteristic.UUID.UUIDString;
}
#pragma mark --点击section事件
- (void)clickOnSectionHeader:(UIButton *)sender
{
	CBService *service = thisServices[sender.tag];//获取到服务
	serviceTF.text = service.UUID.UUIDString;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.view endEditing:YES];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self.view endEditing:YES];
}
@end
