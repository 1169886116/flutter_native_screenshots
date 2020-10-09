#import "FlutterNativeScreenshotsPlugin.h"

///属性
@interface FlutterNativeScreenshotsPlugin ()
@property(nonatomic,strong)FlutterMethodChannel *channel;
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry> *registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@end


@implementation FlutterNativeScreenshotsPlugin
//实例变量
{
    //队列
    dispatch_queue_t _dispatchQueue;
}

#pragma mark - 系统提供-注册
///系统提供-注册
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    //信道
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_native_screenshots" binaryMessenger:[registrar messenger]];
    //初始化
    FlutterNativeScreenshotsPlugin *instance = [[FlutterNativeScreenshotsPlugin alloc] initWithRegistry:[registrar textures] messenger:[registrar messenger] channel:channel];
    //代理
    [registrar addMethodCallDelegate:instance channel:channel];
}
///初始化
- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry messenger:(NSObject<FlutterBinaryMessenger> *)messenger channel:(FlutterMethodChannel *)channel
{
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = registry;
    _messenger = messenger;
    _channel = channel;
    //注册通知
    [self setNSNotificationCenter];
    //返回self
    return self;
}

#pragma mark - 系统提供-监听并回调
///系统提供-监听并回调
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    [self handleMethodCallAsync:call result:result];
}
///异步
- (void)handleMethodCallAsync:(FlutterMethodCall *)call result:(FlutterResult)result
{
    //flutter发起原生截屏
    if ([@"initiateNativeScreenshots" isEqualToString:call.method]) {
        //图片数据
        NSData *imageData = [self screenshotsDataFromUIImageJPEGRepresentation];
        //将data转flutter用的
        id unit8List = [FlutterStandardTypedData typedDataWithBytes:imageData];
        //返回
        result(unit8List);
    }
    else {
        //回调
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - 通知
/// 通知
- (void)setNSNotificationCenter
{
    //监测截屏通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}
/// 截屏响应
- (void)userDidTakeScreenshot:(NSNotification *)notification
{
    NSLog(@"检测到截屏");
    //人为截屏, 模拟用户截屏行为, 获取所截图片
    NSData *imageData = [self screenshotsDataFromUIImageJPEGRepresentation];
    //将data转flutter用的
    id unit8List = [FlutterStandardTypedData typedDataWithBytes:imageData];
    //发送数据到flutter
    [_channel invokeMethod:@"listeningNativeScreenshots" arguments:@{@"image": unit8List}];
}


#pragma mark - 系统级截屏
/// 返回系统级截屏PNG数据
- (NSData *)screenshotsDataFromUIImagePNGRepresentation
{
    UIImage *image = [self imageFromScreenshots];
    return UIImagePNGRepresentation(image);
}

/// 返回系统级截屏JPG数据
- (NSData *)screenshotsDataFromUIImageJPEGRepresentation
{
    UIImage *image = [self imageFromScreenshots];
    return UIImageJPEGRepresentation(image, 1.0f);
}

/// 返回系统级截屏图片
- (UIImage *)imageFromScreenshots
{
    CGSize imageSize = CGSizeZero;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        imageSize = [UIScreen mainScreen].bounds.size;
    }
    else {
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft)
        {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        }
        else if (orientation == UIInterfaceOrientationLandscapeRight)
        {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        }
        else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        }
        else {
            [window.layer renderInContext:context];
        }
        CGContextRestoreGState(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
