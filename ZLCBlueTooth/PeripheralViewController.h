//
//  PeripheralViewController.h
//  ZLCBlueTooth
//
//  Created by shining3d on 16/8/17.
//  Copyright © 2016年 shining3d. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEManager.h"
#import "SVProgressHUD.h"
#import "ZYKeyboardUtil.h"

@interface PeripheralViewController : UIViewController<BLEManagerDelegate,UITableViewDelegate,UITableViewDataSource>




@property CBPeripheral *periperal;




@property ZYKeyboardUtil *keyboardUtil;
@property UITextField *serviceTF;
@property UITextField *characteristicTF;
@property UITextField *contentTF;

@property UILabel  *notifyLabel;


@end
