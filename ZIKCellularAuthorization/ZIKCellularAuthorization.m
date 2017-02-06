//
//  ZIKCellularAuthorization.m
//  iOS10CellularAuthorizeFix
//
//  Created by zuik on 2017/2/4.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKCellularAuthorization.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <CoreTelephony/CTCellularData.h>

#pragma mark 字符串混淆

//"/System/Library/PrivateFrameworks/AppleAccount.framework/AppleAccount"
#define AppleAccountFrameworkPath_ASCII (char[]){0x2f,0x53,0x79,0x73,0x74,0x65,0x6d,0x2f,0x4c,0x69,0x62,0x72,0x61,0x72,0x79,0x2f,0x50,0x72,0x69,0x76,0x61,0x74,0x65,0x46,0x72,0x61,0x6d,0x65,0x77,0x6f,0x72,0x6b,0x73,0x2f,0x41,0x70,0x70,0x6c,0x65,0x41,0x63,0x63,0x6f,0x75,0x6e,0x74,0x2e,0x66,0x72,0x61,0x6d,0x65,0x77,0x6f,0x72,0x6b,0x2f,0x41,0x70,0x70,0x6c,0x65,0x41,0x63,0x63,0x6f,0x75,0x6e,0x74,'\0'}
//"AADeviceInfo"
#define AADeviceInfo_ASCII (char[]){0x41,0x41,0x44,0x65,0x76,0x69,0x63,0x65,0x49,0x6e,0x66,0x6f,'\0'}
//"regionCode"
#define regionCode_ASCII (char[]){0x72,0x65,0x67,0x69,0x6f,0x6e,0x43,0x6f,0x64,0x65,'\0'}
//"hasCellularCapability"
#define hasCellularCapability_ASCII (char[]){0x68,0x61,0x73,0x43,0x65,0x6c,0x6c,0x75,0x6c,0x61,0x72,0x43,0x61,0x70,0x61,0x62,0x69,0x6c,0x69,0x74,0x79,'\0'}
//"/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony"
#define CoreTelephonyFrameworkPath_ASCII (char[]){0x2f,0x53,0x79,0x73,0x74,0x65,0x6d,0x2f,0x4c,0x69,0x62,0x72,0x61,0x72,0x79,0x2f,0x46,0x72,0x61,0x6d,0x65,0x77,0x6f,0x72,0x6b,0x73,0x2f,0x43,0x6f,0x72,0x65,0x54,0x65,0x6c,0x65,0x70,0x68,0x6f,0x6e,0x79,0x2e,0x66,0x72,0x61,0x6d,0x65,0x77,0x6f,0x72,0x6b,0x2f,0x43,0x6f,0x72,0x65,0x54,0x65,0x6c,0x65,0x70,0x68,0x6f,0x6e,0x79,'\0'}
//"_CTServerConnectionCreateOnTargetQueue"
#define CTServerConnectionCreateOnTargetQueue_ASCII (char[]){0x5f,0x43,0x54,0x53,0x65,0x72,0x76,0x65,0x72,0x43,0x6f,0x6e,0x6e,0x65,0x63,0x74,0x69,0x6f,0x6e,0x43,0x72,0x65,0x61,0x74,0x65,0x4f,0x6e,0x54,0x61,0x72,0x67,0x65,0x74,0x51,0x75,0x65,0x75,0x65,'\0'}
//"_CTServerConnectionSetCellularUsagePolicy"
#define CTServerConnectionSetCellularUsagePolicy_ASCII (char[]){0x5f,0x43,0x54,0x53,0x65,0x72,0x76,0x65,0x72,0x43,0x6f,0x6e,0x6e,0x65,0x63,0x74,0x69,0x6f,0x6e,0x53,0x65,0x74,0x43,0x65,0x6c,0x6c,0x75,0x6c,0x61,0x72,0x55,0x73,0x61,0x67,0x65,0x50,0x6f,0x6c,0x69,0x63,0x79,'\0'}
//"com.apple.Preferences"
#define PreferencesAppBundleId_ASCII (char[]){0x63,0x6f,0x6d,0x2e,0x61,0x70,0x70,0x6c,0x65,0x2e,0x50,0x72,0x65,0x66,0x65,0x72,0x65,0x6e,0x63,0x65,0x73,'\0'}
//"kCTCellularUsagePolicyDataAllowed"
#define kCTCellularUsagePolicyDataAllowed_ASCII (char[]){0x6b,0x43,0x54,0x43,0x65,0x6c,0x6c,0x75,0x6c,0x61,0x72,0x55,0x73,0x61,0x67,0x65,0x50,0x6f,0x6c,0x69,0x63,0x79,0x44,0x61,0x74,0x61,0x41,0x6c,0x6c,0x6f,0x77,0x65,0x64,'\0'}
//"/System/Library/PrivateFrameworks/FTServices.framework/FTServices"
#define FTServicesFrameworkPath_ASCII (char[]){0x2f,0x53,0x79,0x73,0x74,0x65,0x6d,0x2f,0x4c,0x69,0x62,0x72,0x61,0x72,0x79,0x2f,0x50,0x72,0x69,0x76,0x61,0x74,0x65,0x46,0x72,0x61,0x6d,0x65,0x77,0x6f,0x72,0x6b,0x73,0x2f,0x46,0x54,0x53,0x65,0x72,0x76,0x69,0x63,0x65,0x73,0x2e,0x66,0x72,0x61,0x6d,0x65,0x77,0x6f,0x72,0x6b,0x2f,0x46,0x54,0x53,0x65,0x72,0x76,0x69,0x63,0x65,0x73,'\0'}
//"FTNetworkSupport"
#define FTNetworkSupport_ASCII (char[]){0x46,0x54,0x4e,0x65,0x74,0x77,0x6f,0x72,0x6b,0x53,0x75,0x70,0x70,0x6f,0x72,0x74,'\0'}
//"dataActiveAndReachable"
#define dataActiveAndReachable_ASCII (char[]){0x64,0x61,0x74,0x61,0x41,0x63,0x74,0x69,0x76,0x65,0x41,0x6e,0x64,0x52,0x65,0x61,0x63,0x68,0x61,0x62,0x6c,0x65,'\0'}

static NSString* stringFromASCII(char* encodingString) {
    NSString *decrypted = [NSString stringWithCString:encodingString encoding:NSASCIIStringEncoding];
    NSLog(@"decrypted字符串：%@",decrypted);
    return decrypted;
}

NSString* printASCIIEncodingForString(NSString *string) {
    NSMutableString *hexs = [NSMutableString string];
    for (int i = 0; i < string.length; i++) {
        [hexs appendString:[NSString stringWithFormat:@"0x%x,",[string characterAtIndex:i]]];
    }
    [hexs appendString:@"'\0'"];
    NSLog(@"源字符串:%@,转换成ASCII码后:(char[]){%@\\0'}",string,hexs);
    return hexs;
}

#pragma mark

static NSString *const ZIKCellularAuthorizationFixedKey = @"ZIKCellularAuthorizationFixed";
static void *CoreTelephonyHandle;
static void *ServicesHandle;
static CTCellularData *cellularDataHandle;

@implementation ZIKCellularAuthorization

+ (void)requestCellularAuthorization {
    NSAssert([AppBundleIdentifier isEqualToString:[NSBundle mainBundle].bundleIdentifier], @"AppBundleIdentifier和bundle id不一致，请手动配置");
    NSAssert(!CoreTelephonyHandle && !ServicesHandle && !cellularDataHandle, @"不要重复调用");
    
    if ([self appFixed]) {
        NSLog(@"ZIKCellularAuthorization：此app已经执行过修复");
        return;
    }
    if (![self deviceNeedFix]) {
        NSLog(@"ZIKCellularAuthorization：此设备系统低于iOS 10 or 不是国行 or 没有蜂窝网络功能，不需要修复");
        return;
    }
    
    CoreTelephonyHandle = dlopen(CoreTelephonyFrameworkPath_ASCII, RTLD_LAZY);
    if (CoreTelephonyHandle) {
        //since iOS 7
        CFTypeRef (*connectionCreateOnTargetQueue)(CFAllocatorRef, NSString *, dispatch_queue_t, void*) = dlsym(CoreTelephonyHandle, CTServerConnectionCreateOnTargetQueue_ASCII);
        //since iOS 7
        int (*changeCellularPolicy)(CFTypeRef, NSString *, NSDictionary *) = dlsym(CoreTelephonyHandle, CTServerConnectionSetCellularUsagePolicy_ASCII);
        if (!connectionCreateOnTargetQueue || !changeCellularPolicy) {
            NSLog(@"ZIKCellularAuthorization：调用changeCellularPolicy失败");
            return;
        }
        
        CFTypeRef connection = connectionCreateOnTargetQueue(kCFAllocatorDefault,stringFromASCII(PreferencesAppBundleId_ASCII),dispatch_get_main_queue(),NULL);
        
        /*此方法无法直接修改app的蜂窝权限，目的是让系统更新一次蜂窝权限数据
         传入AppBundleIdentifier参数时，对象必须用字面量语法创建，直接传入[NSBundle mainBundle].bundleIdentifier时，不会触发系统更新相关数据，原因未知*/
        changeCellularPolicy(connection, AppBundleIdentifier, @{stringFromASCII(kCTCellularUsagePolicyDataAllowed_ASCII):@YES});
    }
    
    ServicesHandle = dlopen(FTServicesFrameworkPath_ASCII, RTLD_LAZY);
    //since iOS 5
    Class NetworkSupport = NSClassFromString(stringFromASCII(FTNetworkSupport_ASCII));
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL sharedInstanceSelector = NSSelectorFromString(@"sharedInstance");
    if (![(id)NetworkSupport respondsToSelector:sharedInstanceSelector]) {
        [self requestFinish];
        NSLog(@"ZIKCellularAuthorization：请求授权失败");
        return;
    }
    id networkSupport = [NetworkSupport performSelector:sharedInstanceSelector];
    
    //since iOS 6
    SEL requestAuthSelector = NSSelectorFromString(stringFromASCII(dataActiveAndReachable_ASCII));
    if (![networkSupport respondsToSelector:requestAuthSelector]) {
        [self requestFinish];
        NSLog(@"ZIKCellularAuthorization：请求授权失败");
        return;
    }
    /*如果是第一次请求蜂窝权限，此方法会让系统弹出"允许xxx使用数据？"的授权框，如果之前已经请求过则不会弹出
     使用此方法仍然存在不会弹框的bug，因此需要配合上面的CTServerConnectionSetCellularUsagePolicy，先让系统更新一次蜂窝权限数据*/
    [networkSupport performSelector:requestAuthSelector];
#pragma clang diagnostic pop
    
    cellularDataHandle = [[CTCellularData alloc] init];
    cellularDataHandle.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state) {
        if (state == kCTCellularDataNotRestricted) {
            [self requestFinish];
        }
    };
    
    [self setAppFixed:YES];
}

+ (void)requestFinish {
    if (CoreTelephonyHandle) {
        dlclose(CoreTelephonyHandle);
        CoreTelephonyHandle = NULL;
    }
    if (ServicesHandle) {
        dlclose(ServicesHandle);
        ServicesHandle = NULL;
    }
    cellularDataHandle.cellularDataRestrictionDidUpdateNotifier = nil;
    cellularDataHandle = nil;
}

+ (BOOL)deviceNeedFix {
    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
        NSLog(@"ZIKCellularAuthorization：系统版本低于iOS 10，无须修复");
        return NO;
    }
    void *AADeviceInfo = dlopen(AppleAccountFrameworkPath_ASCII, RTLD_LAZY);
    //since iOS 5
    Class deviceInfo = NSClassFromString(stringFromASCII(AADeviceInfo_ASCII));
    if (!deviceInfo) {
        return NO;
    }
    id device = [[deviceInfo alloc] init];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    //since iOS 6
    SEL regionSelector = NSSelectorFromString(stringFromASCII(regionCode_ASCII));
    if (![device respondsToSelector:regionSelector]) {
        return NO;
    }
    NSString *code = [device performSelector:regionSelector];
    //since iOS 8
    SEL hasCellularSelector = NSSelectorFromString(stringFromASCII(hasCellularCapability_ASCII));
    BOOL hasCellular = NO;
    if ([device respondsToSelector:hasCellularSelector]) {
        hasCellular = (BOOL)[device performSelector:hasCellularSelector];
    }
#pragma clang diagnostic pop
    
    dlclose(AADeviceInfo);
    if ([code isEqualToString:@"CH"] && hasCellular) {
        return YES;
    }
    return NO;
}

+ (BOOL)appFixed {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *fixed = [userDefault objectForKey:ZIKCellularAuthorizationFixedKey];
    return fixed.boolValue;
}

+ (void)setAppFixed:(BOOL)fixed {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@(fixed) forKey:ZIKCellularAuthorizationFixedKey];
    [userDefault synchronize];
}

@end
