package com.example.medical_copilot

import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.getSystemService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "medical_copilot/audio_native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setGain" -> {
                    // Gain is currently handled in Dart. Native hook is provided
                    // for future extension.
                    result.success(null)
                }
                "startForegroundService" -> {
                    val intent = Intent(this, RecordingForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopForegroundService" -> {
                    val intent = Intent(this, RecordingForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Basic audio focus listener to react to interruptions like phone calls.
        val audioManager: AudioManager? = getSystemService()
        audioManager?.requestAudioFocus(
            { focusChange ->
                if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT ||
                    focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK
                ) {
                    channel.invokeMethod("onAudioInterruption", "pause")
                } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                    channel.invokeMethod("onAudioInterruption", "resume")
                }
            },
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
        )
    }
}
