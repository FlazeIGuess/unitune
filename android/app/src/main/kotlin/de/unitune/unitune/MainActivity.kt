package de.unitune.unitune

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Native Ad Factory for Liquid Glass style ads
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "liquidGlassNative",
            NativeAdFactory(this)
        )
    }
    
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "liquidGlassNative")
    }
}
