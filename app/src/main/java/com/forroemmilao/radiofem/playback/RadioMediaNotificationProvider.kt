package com.forroemmilao.radiofem.playback

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.forroemmilao.radiofem.MainActivity
import com.forroemmilao.radiofem.R
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import com.google.common.collect.ImmutableList

class RadioMediaNotificationProvider(
    private val appContext: Context
) : MediaNotification.Provider {
    companion object {
        private const val CHANNEL_ID = "radiofem_playback"
        private const val NOTIFICATION_ID = 1001
    }

    override fun createNotification(
        mediaSession: MediaSession,
        mediaButtons: ImmutableList<CommandButton>,
        actionFactory: MediaNotification.ActionFactory,
        callback: MediaNotification.Provider.Callback
    ): MediaNotification {
        ensureNotificationChannel()

        val player = mediaSession.player
        val metadata = player.mediaMetadata
        val title = metadata.title?.toString().orEmpty().ifBlank {
            appContext.getString(R.string.playback_notification_title_fallback)
        }
        val subtitle = metadata.artist?.toString().orEmpty().ifBlank {
            appContext.getString(R.string.playback_notification_subtitle_fallback)
        }
        val station = metadata.albumTitle?.toString().orEmpty().ifBlank {
            appContext.getString(R.string.app_name)
        }
        val isPlaying = player.isPlaying

        val compactView = buildCompactView(
            title = title,
            subtitle = subtitle,
            isPlaying = isPlaying
        )
        val expandedView = buildExpandedView(
            title = title,
            subtitle = subtitle,
            station = station,
            isPlaying = isPlaying
        )

        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_radio_fem)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(false)
            .setContentIntent(buildOpenAppIntent())
            .setDeleteIntent(buildStopIntent())
            .setCustomContentView(compactView)
            .setCustomBigContentView(expandedView)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .build()

        notification.flags = notification.flags and Notification.FLAG_ONGOING_EVENT.inv()
        notification.flags = notification.flags and Notification.FLAG_NO_CLEAR.inv()
        notification.deleteIntent = buildStopIntent()

        return MediaNotification(NOTIFICATION_ID, notification)
    }

    override fun handleCustomCommand(
        session: MediaSession,
        action: String,
        extras: android.os.Bundle
    ): Boolean {
        return false
    }

    private fun buildCompactView(
        title: String,
        subtitle: String,
        isPlaying: Boolean
    ): RemoteViews {
        return RemoteViews(appContext.packageName, R.layout.notification_radio_player_small).apply {
            setTextViewText(R.id.notification_title, title)
            setTextViewText(R.id.notification_subtitle, subtitle)
            setImageViewResource(
                R.id.notification_toggle,
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            )
            setOnClickPendingIntent(R.id.notification_root, buildOpenAppIntent())
            setOnClickPendingIntent(R.id.notification_toggle, buildToggleIntent())
            setOnClickPendingIntent(R.id.notification_stop, buildStopIntent())
        }
    }

    private fun buildExpandedView(
        title: String,
        subtitle: String,
        station: String,
        isPlaying: Boolean
    ): RemoteViews {
        return RemoteViews(appContext.packageName, R.layout.notification_radio_player_big).apply {
            setTextViewText(R.id.notification_title_big, title)
            setTextViewText(R.id.notification_subtitle_big, subtitle)
            setTextViewText(R.id.notification_station_big, station)
            setImageViewResource(
                R.id.notification_toggle_big,
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            )
            setOnClickPendingIntent(R.id.notification_root_big, buildOpenAppIntent())
            setOnClickPendingIntent(R.id.notification_toggle_big, buildToggleIntent())
            setOnClickPendingIntent(R.id.notification_stop_big, buildStopIntent())
        }
    }

    private fun buildToggleIntent(): PendingIntent {
        val toggleIntent = Intent(appContext, RadioPlaybackService::class.java).apply {
            action = RadioPlaybackService.ACTION_TOGGLE_FROM_NOTIFICATION
        }
        return PendingIntent.getService(
            appContext,
            9002,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildStopIntent(): PendingIntent {
        val stopIntent = Intent(appContext, RadioPlaybackService::class.java).apply {
            action = RadioPlaybackService.ACTION_STOP_FROM_NOTIFICATION
        }
        return PendingIntent.getService(
            appContext,
            9001,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildOpenAppIntent(): PendingIntent {
        val openIntent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            appContext,
            9003,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            appContext.getString(R.string.playback_channel_name),
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = appContext.getString(R.string.playback_channel_description)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }
}
