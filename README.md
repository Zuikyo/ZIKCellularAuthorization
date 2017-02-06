# ZIKCellularAuthorization
用于修复iOS 10首次安装app时，不会弹出"允许xxx使用数据？"授权框的bug；使用了私有API，已经经过混淆

# 目录

* [问题描述](#problem)
* [修复方法](#fix)
	* [弹出授权框](#present-alert)
		* [调用方式](#how-to-use-1)
	* [让系统更新蜂窝网络权限数据](#update-cellular-data)
		* [调用方式](#how-to-use-2)
		* [出现了玄学](#strange-thing)
	* [用控制台跟踪进程间通信](#debug-trace)
* [检查网络权限情况](#check-celluar-auth)
* [检测国行机型和是否有蜂窝功能](#check-device)
* [测试修复是否成功的方法](#how-to-test)
* [工具代码和Demo](#code)
* [参考](#reference)

# <a name="problem"></a>问题描述
iOS 10有一个系统bug：app在第一次安装时，第一次联网操作会弹出一个授权框，提示"是否允许xxx访问数据？"。而有时候系统并不会弹出授权框，导致app无法联网。

详细情况见：

[iOS 10 的坑：新机首次安装 app，请求网络权限“是否允许使用数据”](http://www.jianshu.com/p/6cbde1b8b922)

[iOS 10 不提示「是否允许应用访问数据」，导致应用无法使用的解决方案](https://zhuanlan.zhihu.com/p/22738261)

关键点总结：

* 只有iOS 10以上、国行机型、有蜂窝网络功能的设备存在这个授权问题，WiFi版的iPad没有这个问题；
* 由于授权框是在有网络操作时才弹出的，这就导致app第一次网络访问必定失败；
* 当出现不弹出授权框的bug时，去设置里更改任意app的蜂窝网络权限，或者打开无线局域网助理，让系统更新一下蜂窝网络相关的数据，可以解决这个bug。

这个系统bug出现时，对用户来说是很麻烦的，app也需要提供详细的提示语来应对这种情况，十分不优雅。

# <a name="fix"></a>修复方法

春节有点空，找到了几个相关的私有API来修复这个bug。

## <a name="present-alert"></a>弹出授权框

首先找到的是一个能直接弹出授权框的API。

```
//Image: /System/Library/PrivateFrameworks/FTServices.framework/FTServices

@interface FTNetworkSupport : NSObject
+ (id)sharedInstance;
- (bool)dataActiveAndReachable;
@end
```
头文件参考：[FTNetworkSupport.h](https://github.com/JaviSoto/iOS10-Runtime-Headers/blob/master/PrivateFrameworks/FTServices.framework/FTNetworkSupport.h)

当app之前没有请求过网络权限时，调用`dataActiveAndReachable`会弹出"是否允许xxx访问数据？"的授权框，如果网络权限已经确定，则不会弹出。

### <a name="how-to-use-1"></a>调用方式

由于`FTNetworkSupport`是在`PrivateFrameworks`目录下，app并没有加载这个库，所以要使用里面的类前，需要用`dlopen`加载`FTServices.framework`,简单示意如下：

```
#import <dlfcn.h>

//加载FTServices.framework
void * FTServicesHandle = dlopen("/System/Library/PrivateFrameworks/FTServices.framework/FTServices", RTLD_LAZY);
Class NetworkSupport = NSClassFromString(@"FTNetworkSupport");
id networkSupport = [NetworkSupport performSelector:NSSelectorFromString(@"sharedInstance")];
[networkSupport performSelector:NSSelectorFromString(@"dataActiveAndReachable")];
//卸载FTServices.framework
dlclose(FTServicesHandle);
```

这个API能解决网络权限导致第一个联网操作失败的问题，但是它还是存在有时候不会弹出授权框的bug。

## <a name="update-cellular-data"></a>让系统更新蜂窝网络权限数据

既然更改任意app的蜂窝网络权限后，能让app弹出授权框，那么只要找到一个方法，能让系统更新一下网络权限相关的数据就可以了。

用`hopper`反编译一下系统的设置app，找到了里面修改app网络权限的API。用到的是`CoreTelephony.framework`里的两个私有C函数：

`CTServerConnection* _CTServerConnectionCreateOnTargetQueue(CFAllocatorRef, NSString *, dispatch_queue_t, void*/*一个block类型的参数*/)`

`void _CTServerConnectionSetCellularUsagePolicy(CTServerConnection *, NSString *, NSDictionary *)`

大部分时间都花在测试这两个函数上了。几个月前我也研究过这两个函数尝试修复这个bug，但是那时候发现没什么作用，就不了了之了。

### <a name="how-to-use-2"></a>调用方式

要调用私有C函数，需要用`dlsym`，简单示意如下：

```
void *CoreTelephonyHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);

//用函数指针来调用私有C函数，用符号名从库里寻找函数地址
CFTypeRef (*connectionCreateOnTargetQueue)(CFAllocatorRef, NSString *, dispatch_queue_t, void*) = dlsym(CoreTelephonyHandle, "_CTServerConnectionCreateOnTargetQueue");
int (*changeCellularPolicy)(CFTypeRef, NSString *, NSDictionary *) = dlsym(CoreTelephonyHandle, "_CTServerConnectionSetCellularUsagePolicy");

//使用设置app的bundle id进行伪装
CFTypeRef connection = connectionCreateOnTargetQueue(kCFAllocatorDefault,@"com.apple.Preferences",dispatch_get_main_queue(),NULL);
//请求修改本app的网络权限为allowed，不会真的修改，只能触发系统更新一下相关的数据
changeCellularPolicy(connection, @"需要授权的app的bundle id", @{@"kCTCellularUsagePolicyDataAllowed":@YES});

dlclose(CoreTelephonyHandle);
```
注意，在声明connectionCreateOnTargetQueue和changeCellularPolicy函数指针时，参数类型要严格对应，如果类型错误，可能会导致系统对参数执行错误的内存管理，出现crash。`CTServerConnection`是私有的，是`CFTypeRef`的子类，所以这里可以用`CFTypeRef`来代替。

### <a name="strange-thing"></a>出现了玄学

`_CTServerConnectionSetCellularUsagePolicy`函数的第二个参数是需要修改的app的bundle id。在测试时，发现传入这个参数时，对象必须是用字面量语法创建的`NSString`，例如`@"com.who.testDemo"`，当传入`[NSBundle mainBundle].bundleIdentifier`这种动态生成的`NSString`时，仍然会出现不弹出授权框的bug，也就是并没有修复成功。连续测试5-10次就能重现。

不过，用

```
NSMutableString *bundleIdentifier = [NSMutableString stringWithString:@"com.who"];
[bundleIdentifier appendString:@".testDemo"];
```
这样的字符串也没问题。相同点是最终都是来自字面量语法创建的`NSString`。

这个玄学问题目前还没有找到原因。

研究了一下字面量创建出的`NSString`，的确是有些特殊的。参考：[Constant Strings in Objective-C](http://bou.io/ConstantStringsInObjC.html)。它是一个`__NSCFConstantString`类型的字符串，在app的整个生命周期内，这个对象的内存都不会被释放。难道iOS的XPC对使用到的字符串还有要求？

时间有限，这个问题以后再研究吧。

## <a name="debug-trace"></a>用控制台跟踪进程间通信

这几个私有API都用了进程间通信，要进行调试跟踪有点麻烦。

可以使用Mac上的控制台查看设备的实时log，寻找通信行为。打开控制台app，在左侧选择连接到Mac的iOS设备，就可以看到设备log了。

下面是调用了`_CTServerConnectionSetCellularUsagePolicy`之后的log，传入bundle id时用的是字面量创建的字符串：
![使用字面量字符串传入bundle id](http://upload-images.jianshu.io/upload_images/1865432-e5eec32d03c2fa7c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
高亮的那行是测试demo打的log，可以认为就是在这里调用了`_CTServerConnectionSetCellularUsagePolicy`，
可以看到，调用之后系统更新了本app的权限状态。`CommCenter`就是这几个私有API通信的对应进程，用于管理设备的网络。参考[CommCenter - The iPhone Wiki](https://www.theiphonewiki.com/wiki//System/Library/Frameworks/CoreTelephony.Framework/Support/CommCenter)。

下面是用`[NSBundle mainBundle].bundleIdentifier`传入`_CTServerConnectionSetCellularUsagePolicy`的第二个参数时的log：
![使用动态创建的字符串传入bundle id](http://upload-images.jianshu.io/upload_images/1865432-87dfca01425cbad0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
没有看到系统更新app权限的相关log，进程间通信可能失败了。因此可以确定，使用`_CTServerConnectionSetCellularUsagePolicy`时必须传入字面量语法创建的字符串。

# <a name="check-celluar-auth"></a>检查网络权限情况

由于`dataActiveAndReachable`里面有异步操作，所以不能立即用`dlclose`卸载`FTServices.framework`。解决方法是监听到蜂窝权限开启时再卸载。

`CoreTelephony`里的`CTCellularData`可以用来监测app的蜂窝网络权限，并且这不是个私有API。你也可以用它来帮助用户检测蜂窝权限是否被关闭，并给出提示，防止出现用户关了网络权限导致app无法联网的情况。

`CTCellularData`的头文件如下：

```
typedef NS_ENUM(NSUInteger, CTCellularDataRestrictedState) {
	kCTCellularDataRestrictedStateUnknown,//权限未知
	kCTCellularDataRestricted,//蜂窝权限被关闭，有 网络权限完全关闭 or 只有WiFi权限 两种情况
	kCTCellularDataNotRestricted//蜂窝权限开启
};

@interface CTCellularData : NSObject
///权限更改时的回调
@property (copy, nullable) CellularDataRestrictionDidUpdateNotifier cellularDataRestrictionDidUpdateNotifier;
///当前的蜂窝权限
@property (nonatomic, readonly) CTCellularDataRestrictedState restrictedState;
@end
```

使用方法：

```
#import <CoreTelephony/CTCellularData.h>

CTCellularData *cellularDataHandle = [[CTCellularData alloc] init];
cellularDataHandle.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state) {
        //蜂窝权限更改时的回调
    };
```

使用时需要注意的关键点：

* `CTCellularData`只能检测蜂窝权限，不能检测WiFi权限。
* 一个`CTCellularData`实例新建时，`restrictedState`是`kCTCellularDataRestrictedStateUnknown`，之后在`cellularDataRestrictionDidUpdateNotifier`里会有一次回调，此时才能获取到正确的权限状态。
* 当用户在设置里更改了app的权限时，`cellularDataRestrictionDidUpdateNotifier`会收到回调，如果要停止监听，必须将`cellularDataRestrictionDidUpdateNotifier`设置为`nil`。
* 赋值给`cellularDataRestrictionDidUpdateNotifier`的block并不会自动释放，即便你给一个局部变量的`CTCellularData`实例设置监听，当权限更改时，还是会收到回调，所以记得将block置`nil`。

# <a name="check-device"></a>检测国行机型和是否有蜂窝功能

非国行机型，以及没有蜂窝功能的设备是不需要进行修复的。因此也要寻找相关的私有API进行检测。

用到的私有API如下：

```
//Image: /System/Library/PrivateFrameworks/AppleAccount.framework/AppleAccount

@interface AADeviceInfo : NSObject
///是否有蜂窝功能
- (bool)hasCellularCapability;
///设备的区域代码，例如国行机就是CH
- (id)regionCode;
@end
```

头文件参考：[AADeviceInfo.h](https://github.com/JaviSoto/iOS10-Runtime-Headers/blob/master/PrivateFrameworks/AppleAccount.framework/AADeviceInfo.h)

使用方式和`FTServices.framework`类似，不再重复。

# <a name="how-to-test"></a>测试修复是否成功的方法

我的测试方式是每次运行都修改项目的`bundle identifier`和`display name`，让系统每次都把它当做一个新app，使用`Release`模式，测试是否每次都能够弹出授权框。由于需要不断修改`bundle identifier`，写了个脚本在每次build时自动运行，会自动累加几个地方的`bundle identifier`后面的数字。demo里已经附带了这个脚本。

你也可以测试一下不执行修复时，进行联网操作是否会弹出授权框。我的测试结果是大约运行5-10次时，就会出现不弹出授权框的bug。需要把项目改为`Release`模式才能出现，`Debug`模式下不会出bug。

注意，由于build后自动累加的关系，`ZIKCellularAuthorization.h`里的`AppBundleIdentifier`是下一次app运行时的值。如果你觉得这个脚本把你搞晕了，可以在`Build Phases/Run Script`里关掉，在`sh ${PROJECT_DIR}/IncreaseBundleId.sh`前面加个`#`注释掉就行了。

没有测试覆盖安装同一个`bundle identifier`的app，或者更新了版本号的app是否也会出现这个bug，现在是认为只有第一次安装时才会出现bug。

# <a name="code"></a>工具代码和Demo

地址在[ZIKCellularAuthorization](https://github.com/Zuikyo/ZIKCellularAuthorization)，用到的私有API已经经过混淆。测试前记得先把`Build Configuration`改为`Release`模式。有帮助请点个Star~

# <a name="reference"></a>参考

[iOS 10 的坑：新机首次安装 app，请求网络权限“是否允许使用数据”](http://www.jianshu.com/p/6cbde1b8b922)

[iOS 10 不提示「是否允许应用访问数据」，导致应用无法使用的解决方案](https://zhuanlan.zhihu.com/p/22738261)