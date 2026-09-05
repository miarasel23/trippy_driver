package com.trippy.rider

import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.trippy.rider/maps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setApiKey") {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey != null) {
                    try {
                        val applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                        if (applicationInfo.metaData == null) {
                            applicationInfo.metaData = Bundle()
                        }
                        applicationInfo.metaData.putString("com.google.android.geo.API_KEY", apiKey)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not set API key.", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "API key is null.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
