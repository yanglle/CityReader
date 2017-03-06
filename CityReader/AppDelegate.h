//
//  AppDelegate.h
//  CityReader
//
//  Created by yanglle on 17/2/17.
//  Copyright © 2017年 yanglle. All rights reserved.
//
/*
 联网：AFNetworking 连接wifi 并获取路由地址 配置上传图片接口
 拍照：调用原生相机 并将图片上传至服务器
 
 服务器端功能   1 检测所有连入局域网的设备
              2 为设备分配顺序编号  （如果这部分做不到需手动输入设备顺序）
              3 发送控制命令
              4 接受传来的图片 并按照命名顺序合成短视频
               
 
 
 
 
 */
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

