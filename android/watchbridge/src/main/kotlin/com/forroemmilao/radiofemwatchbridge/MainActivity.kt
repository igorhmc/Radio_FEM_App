package com.forroemmilao.radiofemwatchbridge

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity() {
    private val uiHandler = Handler(Looper.getMainLooper())
    private lateinit var statusView: TextView
    private lateinit var endpointView: TextView

    private val statusUpdater = object : Runnable {
        override fun run() {
            renderStatus(WatchBridgeService.currentStatus())
            uiHandler.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        statusView = findViewById(R.id.bridge_status)
        endpointView = findViewById(R.id.bridge_endpoint)

        findViewById<Button>(R.id.start_bridge_button).setOnClickListener {
            WatchBridgeService.startService(this)
        }
        findViewById<Button>(R.id.stop_bridge_button).setOnClickListener {
            WatchBridgeService.stopService(this)
        }
        findViewById<Button>(R.id.play_button).setOnClickListener {
            WatchBridgeService.startService(this, WatchBridgeService.actionPlay)
        }
        findViewById<Button>(R.id.pause_button).setOnClickListener {
            WatchBridgeService.startService(this, WatchBridgeService.actionPause)
        }
        findViewById<Button>(R.id.volume_down_button).setOnClickListener {
            WatchBridgeService.startService(this, WatchBridgeService.actionVolumeDown)
        }
        findViewById<Button>(R.id.volume_up_button).setOnClickListener {
            WatchBridgeService.startService(this, WatchBridgeService.actionVolumeUp)
        }

        endpointView.text =
            "Endpoint: http://${BridgeConfig.bridgeHost}:${BridgeConfig.bridgePort}"

        maybeRequestNotificationPermission()
        WatchBridgeService.startService(this)
    }

    override fun onStart() {
        super.onStart()
        uiHandler.post(statusUpdater)
    }

    override fun onStop() {
        uiHandler.removeCallbacks(statusUpdater)
        super.onStop()
    }

    private fun renderStatus(status: BridgeStatus) {
        val running = if (status.bridgeRunning) "Ativa" else "Desligada"
        val playing = if (status.isPlaying) "Tocando" else "Pausada"
        val volume = (status.volume * 100).toInt()

        statusView.text = buildString {
            append("Ponte: $running\n")
            append("Audio: $playing\n")
            append("Volume: $volume%\n")
            append("Status: ${status.lastMessage}")
        }
    }

    private fun maybeRequestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }
        if (
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            1001,
        )
    }
}
