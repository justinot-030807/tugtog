package com.tugtog.tugtog

import android.content.Intent
import android.media.audiofx.AudioEffect
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val EQUALIZER_CHANNEL = "com.tugtog.tugtog/equalizer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EQUALIZER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSystemEqualizer" -> {
                    try {
                        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
                        intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                        intent.putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivityForResult(intent, 0)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("EQ_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

