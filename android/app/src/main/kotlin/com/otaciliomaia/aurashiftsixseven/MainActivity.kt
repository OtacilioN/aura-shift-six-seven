package com.otaciliomaia.aurashiftsixseven

import android.content.Intent
import android.os.Bundle
import com.google.android.gms.ads.AgeRestrictedTreatment
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.gms.games.PlayGamesSdk
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

    private var playGamesBridge: PlayGamesBridge? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (
            getString(R.string.game_services_project_id).isNotBlank() &&
            getString(R.string.game_services_project_id) != "0"
        ) {
            PlayGamesSdk.initialize(this)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playGamesBridge =
            PlayGamesBridge(
                this,
                flutterEngine.dartExecutor.binaryMessenger,
            )
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

    @Deprecated("FlutterActivity still dispatches legacy activity results.")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        if (playGamesBridge?.onActivityResult(requestCode, resultCode) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        playGamesBridge?.dispose()
        playGamesBridge = null
        super.onDestroy()
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
