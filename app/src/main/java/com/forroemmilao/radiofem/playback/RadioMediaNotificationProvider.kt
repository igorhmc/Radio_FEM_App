package com.forroemmilao.radiofem.playback

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.media3.session.CommandButton
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import com.google.common.collect.ImmutableList

class RadioMediaNotificationProvider(
    private val appContext: Context
) : MediaNotification.Provider {
    private val delegate = DefaultMediaNotificationProvider(appContext)

    override fun createNotification(
        mediaSession: MediaSession,
        mediaButtons: ImmutableList<CommandButton>,
        actionFactory: MediaNotification.ActionFactory,
        callback: MediaNotification.Provider.Callback
    ): MediaNotification {
        val base = delegate.createNotification(mediaSession, mediaButtons, actionFactory, callback)
        val notification = base.notification

        notification.flags = notification.flags and Notification.FLAG_ONGOING_EVENT.inv()
        notification.flags = notification.flags and Notification.FLAG_NO_CLEAR.inv()
        notification.deleteIntent = buildDeleteIntent()

        return MediaNotification(base.notificationId, notification)
    }

    override fun handleCustomCommand(
        session: MediaSession,
        action: String,
        extras: android.os.Bundle
    ): Boolean {
        return delegate.handleCustomCommand(session, action, extras)
    }

    private fun buildDeleteIntent(): PendingIntent {
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
}
