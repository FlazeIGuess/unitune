package de.unitune.unitune

import android.content.Context
import android.view.LayoutInflater
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactory(private val context: Context) : 
    GoogleMobileAdsPlugin.NativeAdFactory {
    
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView
        
        // Bind ad views
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val adBadge = adView.findViewById<TextView>(R.id.ad_badge)
        
        headlineView.text = nativeAd.headline
        bodyView.text = nativeAd.body
        
        adView.headlineView = headlineView
        adView.bodyView = bodyView
        
        adView.setNativeAd(nativeAd)
        
        return adView
    }
}
