package com.hardsync.mobile

import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private val permissionRequestCode = 7304

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hardsync/media_permissions")
            .setMethodCallHandler { call, result ->
                if (call.method != "request") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val wantsMic = call.argument<Boolean>("microphone") == true
                val wantsCamera = call.argument<Boolean>("camera") == true
                val requested = mutableListOf<String>()
                if (wantsMic && checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                    requested.add(Manifest.permission.RECORD_AUDIO)
                }
                if (wantsCamera && checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                    requested.add(Manifest.permission.CAMERA)
                }
                if (requested.isEmpty()) {
                    result.success(true)
                } else if (permissionResult != null) {
                    result.error("permission_in_progress", "A media permission request is already active.", null)
                } else {
                    permissionResult = result
                    requestPermissions(requested.toTypedArray(), permissionRequestCode)
                }
            }
    }

    @Deprecated("Deprecated in Android")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            val allowed = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionResult?.success(allowed)
            permissionResult = null
        }
    }
}
