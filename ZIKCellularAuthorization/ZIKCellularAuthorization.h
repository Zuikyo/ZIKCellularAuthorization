//
//  ZIKCellularAuthorization.h
//  iOS10CellularAuthorizeFix
//
//  Created by zuik on 2017/2/4.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

///app的bundle id，需要在这里手动配置，只能用字面量语法赋值（不使用字面量语法，而使用[NSBundle mainBundle].bundleIdentifier时，不会触发系统更新相关数据）
static NSString *const AppBundleIdentifier = @"com.zuik.iOS10CellularAuthorizeFix-1";

///用于修复iOS 10首次安装app时，不会弹出"允许xxx使用数据？"授权框的bug；使用了私有API，已经经过混淆
@interface ZIKCellularAuthorization : NSObject

/**
 请求蜂窝网络权限，在app启动时调用
 @discussion
 1.如果之前已经请求过权限，或者权限已经确定，此方法没有效果
 
 2.如果非国行 or 没有蜂窝网络功能，此方法没有效果
 
 3.iOS 10以下调用没有效果
 */
+ (void)requestCellularAuthorization;

///设备是否需要修复（iOS10以上，国行机型，并且有蜂窝网络功能）
+ (BOOL)deviceNeedFix;

///app是否执行过修复
+ (BOOL)appFixed;
@end
