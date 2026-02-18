package de.unitune.unitune

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "de.unitune.unitune/intent"
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Native Ad Factory for Liquid Glass style ads
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "liquidGlassNative",
            NativeAdFactory(this)
        )
        
        // Create MethodChannel for intent action communication
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        val action = intent.action
        val data = intent.data
        val type = intent.type
        
        Log.d("UniTune", "=== Native Intent Handler ===")
        Log.d("UniTune", "Action: $action")
        Log.d("UniTune", "Data: $data")
        Log.d("UniTune", "Type: $type")
        
        // Send intent info to Flutter
        val intentInfo = mapOf(
            "action" to (action ?: ""),
            "data" to (data?.toString() ?: ""),
            "type" to (type ?: "")
        )
        
        methodChannel?.invokeMethod("onIntent", intentInfo)
    }
    
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "liquidGlassNative")
        methodChannel = null
    }
}
