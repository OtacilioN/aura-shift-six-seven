package com.otaciliomaia.aurashiftsixseven

import com.google.android.gms.ads.AgeRestrictedTreatment
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.play.agesignals.AgeSignalsManagerFactory
import com.google.android.play.agesignals.AgeSignalsRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val AD_PRIVACY_CHANNEL =
            "com.otaciliomaia.aurashiftsixseven/ad_privacy"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AD_PRIVACY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "configureTeenAds" -> {
                    val configuration = MobileAds
                        .getRequestConfiguration()
                        .toBuilder()
                        .setMaxAdContentRating(
                            RequestConfiguration.MAX_AD_CONTENT_RATING_T,
                        )
                        .setAgeRestrictedTreatment(AgeRestrictedTreatment.TEEN)
                        .setPublisherPrivacyPersonalizationState(
                            RequestConfiguration
                                .PublisherPrivacyPersonalizationState
                                .DISABLED,
                        )
                        .build()
                    MobileAds.setRequestConfiguration(configuration)
                    result.success(null)
                }

                "refreshAgeSignals" -> refreshAgeSignals(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun refreshAgeSignals(result: MethodChannel.Result) {
        // This response is intentionally discarded. In particular, it is not
        // exposed to Dart, persisted, logged, sent to analytics, or connected
        // to the advertising configuration.
        AgeSignalsManagerFactory
            .create(applicationContext)
            .checkAgeSignals(AgeSignalsRequest.builder().build())
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { result.success(null) }
    }
}
