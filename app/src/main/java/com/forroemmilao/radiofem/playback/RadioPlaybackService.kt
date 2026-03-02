package com.forroemmilao.radiofem.playback

import android.content.Intent
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.forroemmilao.radiofem.BuildConfig
import com.forroemmilao.radiofem.data.RadioRepository
import com.forroemmilao.radiofem.data.Song
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class RadioPlaybackService : MediaSessionService() {
    companion object {
        const val ACTION_STOP_FROM_NOTIFICATION =
            "com.forroemmilao.radiofem.action.STOP_FROM_NOTIFICATION"
    }

    private val repository = RadioRepository()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var mediaSession: MediaSession? = null
    private var player: ExoPlayer? = null
    private var metadataSyncJob: Job? = null
    private var lastLiveArtist = ""
    private var lastLiveTitle = ""
    private var lastLiveStation = "Radio FEM"
    private var liveStreamUri = BuildConfig.STREAM_URL

    override fun onCreate() {
        super.onCreate()
        setMediaNotificationProvider(RadioMediaNotificationProvider(this))

        val exoPlayer = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                true
            )
            setHandleAudioBecomingNoisy(true)
            setMediaItem(buildLiveMediaItem())
            prepare()
            addListener(object : Player.Listener {
                override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                    if (isLiveStreamItem(mediaItem)) {
                        lastLiveArtist = ""
                        lastLiveTitle = ""
                        lastLiveStation = "Radio FEM"
                        requestImmediateMetadataRefresh()
                    }
                }
            })
        }
        player = exoPlayer

        mediaSession = MediaSession.Builder(this, exoPlayer)
            .setId("radiofem_live_session")
            .build()

        startMetadataSyncLoop()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP_FROM_NOTIFICATION) {
            pauseAllPlayersAndStopSelf()
            return START_NOT_STICKY
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        val player = mediaSession?.player
        if (player == null || !player.isPlaying) {
            stopSelf()
        }
    }

    override fun onDestroy() {
        metadataSyncJob?.cancel()
        metadataSyncJob = null
        serviceScope.cancel()
        mediaSession?.let { session ->
            session.player.release()
            session.release()
        }
        player = null
        mediaSession = null
        super.onDestroy()
    }

    private fun startMetadataSyncLoop() {
        metadataSyncJob?.cancel()
        metadataSyncJob = serviceScope.launch {
            while (isActive) {
                runCatching { syncLiveNowPlayingMetadata() }
                delay(15_000)
            }
        }
    }

    private fun requestImmediateMetadataRefresh() {
        serviceScope.launch {
            runCatching { syncLiveNowPlayingMetadata() }
        }
    }

    private suspend fun syncLiveNowPlayingMetadata() {
        val isLiveMode = withContext(Dispatchers.Main.immediate) {
            val currentPlayer = player ?: return@withContext false
            val currentItem = currentPlayer.currentMediaItem
            if (!isLiveStreamItem(currentItem)) return@withContext false

            liveStreamUri = currentItem
                ?.localConfiguration
                ?.uri
                ?.toString()
                .orEmpty()
                .ifBlank { BuildConfig.STREAM_URL }
            true
        }
        if (!isLiveMode) return

        val payload = runCatching { repository.fetchNowPlaying() }.getOrNull() ?: return
        val (artist, title) = resolveNowPlaying(payload.nowPlaying.song)
        val stationName = payload.station.name.ifBlank { "Radio FEM" }

        if (artist == lastLiveArtist && title == lastLiveTitle && stationName == lastLiveStation) return

        lastLiveArtist = artist
        lastLiveTitle = title
        lastLiveStation = stationName

        withContext(Dispatchers.Main) {
            val currentPlayer = player ?: return@withContext
            if (!isLiveStreamItem(currentPlayer.currentMediaItem)) return@withContext

            val updatedLiveMedia = MediaItem.Builder()
                .setUri(liveStreamUri)
                .setMediaMetadata(
                    MediaMetadata.Builder()
                        .setTitle(title.ifBlank { "Live Track" })
                        .setArtist(artist.ifBlank { "Radio FEM" })
                        .setAlbumTitle(stationName)
                        .build()
                )
                .build()

            val index = currentPlayer.currentMediaItemIndex
            if (currentPlayer.mediaItemCount > 0 && index >= 0 && index < currentPlayer.mediaItemCount) {
                currentPlayer.replaceMediaItem(index, updatedLiveMedia)
            }
        }
    }

    private fun resolveNowPlaying(song: Song): Pair<String, String> {
        val rawArtist = song.artist.trim()
        val rawTitle = song.title.trim()
        if (rawArtist.isNotBlank() && rawTitle.isNotBlank()) {
            return rawArtist to rawTitle
        }

        val rawText = song.text.trim()
        if (rawText.contains(" - ")) {
            val parts = rawText.split(" - ", limit = 2)
            val artist = rawArtist.ifBlank { parts[0].trim() }.ifBlank { "Unknown Artist" }
            val title = rawTitle.ifBlank { parts[1].trim() }.ifBlank { "Live Track" }
            return artist to title
        }

        val artist = rawArtist.ifBlank { "Unknown Artist" }
        val title = rawTitle.ifBlank { rawText.ifBlank { "Live Track" } }
        return artist to title
    }

    private fun isLiveStreamItem(item: MediaItem?): Boolean {
        val itemUri = normalizeUrl(item?.localConfiguration?.uri?.toString().orEmpty())
        val streamUrl = normalizeUrl(BuildConfig.STREAM_URL)
        return itemUri.isBlank() || itemUri == streamUrl
    }

    private fun normalizeUrl(url: String): String {
        return url.trim().substringBefore('#').substringBefore('?').trimEnd('/')
    }

    private fun buildLiveMediaItem(): MediaItem {
        return MediaItem.Builder()
            .setUri(BuildConfig.STREAM_URL)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("RadioFEM Live")
                    .setArtist("Radio FEM")
                    .build()
            )
            .build()
    }
}
