package com.example.flutter_native_screenshots;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.util.HashMap;
import java.util.Map;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterNativeScreenshotsPlugin
 */
public class FlutterNativeScreenshotsPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private ScreenShotListenManager mScreenManager;

    private final int mPermissionCode = 111;
    private String[] mPermissionArr = {Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE};

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_native_screenshots");
        channel.setMethodCallHandler(this);
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_native_screenshots");
        FlutterNativeScreenshotsPlugin plugin = new FlutterNativeScreenshotsPlugin();
        channel.setMethodCallHandler(plugin);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
          if (call.method.equals("initiateNativeScreenshots")) {
            iosStartScreenshots();
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    void iosStartScreenshots() {
        Toast.makeText(context, "点击截屏", Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onAttachedToActivity(@NonNull final ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        checkPerssion();
        initScreenShotManager();
        binding.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
                switch (requestCode) {
                    case mPermissionCode:
                        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_DENIED) {
                            Toast.makeText(binding.getActivity(),"已拒绝访问设备上照片及文件权限!",Toast.LENGTH_SHORT).show();
                        } else {
                            initScreenShotManager();
                        }
                        break;
                }
                return false;
            }
        });
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }


    void checkPerssion() {
        mScreenManager = ScreenShotListenManager.newInstance(context);
        mScreenManager.startListen();
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(activity, mPermissionArr, mPermissionCode);
        } else {
            initScreenShotManager();
        }
    }

    private void initScreenShotManager() {
        mScreenManager.setListener(new ScreenShotListenManager.OnScreenShotListener() {
            @Override
            public void onShot(String imagePath) {
                Map<String, byte[]> map = new HashMap<>();
                map.put("image", getBytesByFile(imagePath));
                channel.invokeMethod("listeningNativeScreenshots", map, new MethodChannel.Result() {

                    @Override
                    public void success(@Nullable Object result) {

                    }

                    @Override
                    public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {

                    }

                    @Override
                    public void notImplemented() {

                    }
                });
            }
        });
    }


    byte[] getBytesByFile(String filePath) {
        try {
            File file = new File(filePath);
            //获取输入流
            FileInputStream fis = new FileInputStream(file);
            //新的 byte 数组输出流，缓冲区容量1024byte
            ByteArrayOutputStream bos = new ByteArrayOutputStream(1024);
            //缓存
            byte[] b = new byte[1024];
            int n;
            while ((n = fis.read(b)) != -1) {
                bos.write(b, 0, n);
            }
            fis.close();
            //改变为byte[]
            byte[] data = bos.toByteArray();
            //
            bos.close();
            return data;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
