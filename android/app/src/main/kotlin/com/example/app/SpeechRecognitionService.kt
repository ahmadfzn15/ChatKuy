package com.example.app

import android.app.Service
import android.content.Intent
import android.os.Bundle
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SpeechRecognitionService : Service(), RecognitionListener {
    private lateinit var speechRecognizer: SpeechRecognizer
    private lateinit var methodChannel: MethodChannel

    override fun onCreate() {
        super.onCreate()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(this)

        val flutterEngine = FlutterEngineCache.getInstance().get("my_engine_id")
        if (flutterEngine != null) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.app/alarm")
        } else {
            Log.e("SpeechRecognitionService", "Flutter engine is null")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startListening()
        return START_STICKY
    }

    private fun startListening() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        intent.putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, this.packageName)
        speechRecognizer.startListening(intent)
    }

    override fun onDestroy() {
        speechRecognizer.destroy()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {}
    override fun onError(error: Int) {
        startListening()
    }

    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        matches?.forEach { result ->
            Log.d("SpeechRecognition", "Result: $result")
            if (::methodChannel.isInitialized) {
                methodChannel.invokeMethod("onSpeechResult", result)
            }
            if (result.contains("stop", true)) {
                stopSelf()
            }
        }
        startListening()
    }

    override fun onPartialResults(partialResults: Bundle?) {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
}