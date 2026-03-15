package com.forroemmilao.radiofemwatchbridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class WatchBridgeService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var bridgeServer: LocalHttpBridgeServer? = null
    private var currentVolume = 1.0f

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build(),
            )
            setOnPreparedListener {
                it.start()
                updateStatus(
                    snapshot().copy(
                        bridgeRunning = true,
                        isPlaying = true,
                        volume = currentVolume,
                        lastMessage = "Radio ao vivo tocando",
                    ),
                )
            }
            setOnErrorListener { _, _, _ ->
                updateStatus(
                    snapshot().copy(
                        bridgeRunning = true,
                        isPlaying = false,
                        volume = currentVolume,
                        lastMessage = "Erro ao reproduzir a radio",
                    ),
                )
                true
            }
        }

        bridgeServer = LocalHttpBridgeServer(
            statusProvider = ::snapshot,
            commandHandler = ::handleBridgeCommand,
        ).also { it.start() }

        updateStatus(
            BridgeStatus(
                bridgeRunning = true,
                isPlaying = false,
                volume = currentVolume,
                lastMessage = "Ponte ativa no celular",
            ),
        )
        startForeground(notificationId, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            actionPlay -> playLive()
            actionPause -> pausePlayback()
            actionVolumeUp -> changeVolume(+0.1f)
            actionVolumeDown -> changeVolume(-0.1f)
            actionStopService -> stopSelf()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        bridgeServer?.stop()
        bridgeServer = null
        mediaPlayer?.release()
        mediaPlayer = null
        updateStatus(BridgeStatus())
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun handleBridgeCommand(command: String): BridgeResponse =
        runOnMainThread {
            when (command) {
                "play-live" -> playLive()
                "pause" -> pausePlayback()
                "volume-up" -> changeVolume(+0.1f)
                "volume-down" -> changeVolume(-0.1f)
                else -> BridgeResponse(
                    ok = false,
                    message = "Comando desconhecido: $command",
                    volume = currentVolume,
                    isPlaying = snapshot().isPlaying,
                )
            }
        }

    private fun playLive(): BridgeResponse {
        val player = mediaPlayer ?: return BridgeResponse(
            ok = false,
            message = "Player indisponivel",
            volume = currentVolume,
            isPlaying = false,
        )

        return try {
            if (player.isPlaying) {
                updateStatus(snapshot().copy(lastMessage = "Radio ja esta tocando"))
                BridgeResponse(true, "Radio ja esta tocando", currentVolume, true)
            } else if (snapshot().isPlaying.not() && playerCurrentSourcePrepared(player)) {
                player.start()
                updateStatus(snapshot().copy(isPlaying = true, lastMessage = "Radio retomada"))
                BridgeResponse(true, "Radio retomada", currentVolume, true)
            } else {
                player.reset()
                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build(),
                )
                player.setVolume(currentVolume, currentVolume)
                player.setDataSource(BridgeConfig.streamUrl)
                player.prepareAsync()
                updateStatus(
                    snapshot().copy(
                        bridgeRunning = true,
                        isPlaying = false,
                        volume = currentVolume,
                        lastMessage = "Conectando ao stream ao vivo",
                    ),
                )
                BridgeResponse(true, "Conectando ao stream ao vivo", currentVolume, false)
            }
        } catch (error: Exception) {
            val message = error.message ?: "Falha ao tocar a radio"
            updateStatus(snapshot().copy(isPlaying = false, lastMessage = message))
            BridgeResponse(false, message, currentVolume, false)
        }
    }

    private fun pausePlayback(): BridgeResponse {
        val player = mediaPlayer ?: return BridgeResponse(
            ok = false,
            message = "Player indisponivel",
            volume = currentVolume,
            isPlaying = false,
        )

        return if (player.isPlaying) {
            player.pause()
            updateStatus(snapshot().copy(isPlaying = false, lastMessage = "Radio pausada"))
            BridgeResponse(true, "Radio pausada", currentVolume, false)
        } else {
            updateStatus(snapshot().copy(lastMessage = "Radio ja esta pausada"))
            BridgeResponse(true, "Radio ja esta pausada", currentVolume, false)
        }
    }

    private fun changeVolume(delta: Float): BridgeResponse {
        currentVolume = (currentVolume + delta).coerceIn(0.0f, 1.0f)
        mediaPlayer?.setVolume(currentVolume, currentVolume)
        val message = "Volume ${(currentVolume * 100).toInt()}%"
        updateStatus(snapshot().copy(volume = currentVolume, lastMessage = message))
        return BridgeResponse(true, message, currentVolume, snapshot().isPlaying)
    }

    private fun buildNotification(): Notification {
        val openAppIntent = PendingIntent.getActivity(
            this,
            1,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val status = snapshot()
        return NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("Radio FEM Watch Bridge")
            .setContentText(status.lastMessage)
            .setOngoing(true)
            .setContentIntent(openAppIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                notificationChannelId,
                "Radio FEM Watch Bridge",
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }

    private fun updateStatus(status: BridgeStatus) {
        latestStatus = status
        val manager = ContextCompat.getSystemService(this, NotificationManager::class.java)
        manager?.notify(notificationId, buildNotification())
    }

    private fun snapshot(): BridgeStatus = latestStatus

    private fun playerCurrentSourcePrepared(player: MediaPlayer): Boolean =
        try {
            player.currentPosition >= 0
        } catch (_: IllegalStateException) {
            false
        }

    private fun <T> runOnMainThread(action: () -> T): T {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            return action()
        }

        val latch = CountDownLatch(1)
        var result: Result<T>? = null
        val handler = ContextCompat.getMainExecutor(this)
        handler.execute {
            result = runCatching(action)
            latch.countDown()
        }
        latch.await(5, TimeUnit.SECONDS)
        return result!!.getOrThrow()
    }

    companion object {
        const val actionPlay = "com.forroemmilao.radiofemwatchbridge.action.PLAY"
        const val actionPause = "com.forroemmilao.radiofemwatchbridge.action.PAUSE"
        const val actionVolumeUp = "com.forroemmilao.radiofemwatchbridge.action.VOLUME_UP"
        const val actionVolumeDown = "com.forroemmilao.radiofemwatchbridge.action.VOLUME_DOWN"
        const val actionStopService = "com.forroemmilao.radiofemwatchbridge.action.STOP_SERVICE"

        private const val notificationChannelId = "radiofem_watch_bridge"
        private const val notificationId = 43871

        @Volatile
        private var latestStatus = BridgeStatus()

        fun startService(context: android.content.Context, action: String? = null) {
            val intent = Intent(context, WatchBridgeService::class.java).apply {
                this.action = action
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stopService(context: android.content.Context) {
            context.startService(
                Intent(context, WatchBridgeService::class.java).apply {
                    action = actionStopService
                },
            )
        }

        fun currentStatus(): BridgeStatus = latestStatus
    }
}
