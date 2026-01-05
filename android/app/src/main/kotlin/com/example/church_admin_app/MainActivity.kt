package com.example.church_admin_app
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity(){
    private val CHANNEL = "church_flavor"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getFlavor") {
                val flavor = getString(
                    resources.getIdentifier(
                        "church_flavor",
                        "string",
                        packageName
                    )
                )
                result.success(flavor)
            } else {
                result.notImplemented()
            }
        }
    }
}
