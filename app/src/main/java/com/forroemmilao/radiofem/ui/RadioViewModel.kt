package com.forroemmilao.radiofem.ui

import android.app.Application
import android.content.ComponentName
import androidx.core.content.ContextCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.forroemmilao.radiofem.BuildConfig
import com.forroemmilao.radiofem.data.PodcastEpisodeResponse
import com.forroemmilao.radiofem.data.PodcastResponse
import com.forroemmilao.radiofem.data.RadioRepository
import com.forroemmilao.radiofem.data.ScheduleItemResponse
import com.forroemmilao.radiofem.data.Song
import com.forroemmilao.radiofem.playback.RadioPlaybackService
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class ScheduleUiItem(
    val id: Long,
    val title: String,
    val description: String,
    val dateLabel: String,
    val timeRangeLabel: String,
    val startAtMillis: Long,
    val endAtMillis: Long,
    val isNow: Boolean
)

data class PodcastUiItem(
    val id: String,
    val title: String,
    val description: String,
    val author: String,
    val episodesCount: Int,
    val language: String,
    val feedUrl: String
)

data class PodcastEpisodeUiItem(
    val id: String,
    val title: String,
    val description: String,
    val publishLabel: String,
    val playUrl: String
)

data class RadioUiState(
    val stationName: String = "Radio FEM",
    val nowPlayingText: String = "Loading track...",
    val nowPlayingArtist: String = "Loading artist...",
    val nowPlayingTitle: String = "Loading track...",
    val listeners: Int = 0,
    val isPlaying: Boolean = false,
    val isBuffering: Boolean = false,
    val isPlayerConnected: Boolean = false,
    val isLiveStreamMode: Boolean = true,
    val playbackSourceLabel: String = "Live",
    val currentPodcastEpisodeTitle: String = "",
    val currentPodcastEpisodeDescription: String = "",
    val podcastPositionMs: Long = 0L,
    val podcastDurationMs: Long = 0L,
    val isLoading: Boolean = true,
    val lastUpdated: String = "",
    val apiErrorMessage: String? = null,
    val playerErrorMessage: String? = null,
    val schedule: List<ScheduleUiItem> = emptyList(),
    val isScheduleLoading: Boolean = false,
    val scheduleErrorMessage: String? = null,
    val podcasts: List<PodcastUiItem> = emptyList(),
    val isPodcastsLoading: Boolean = false,
    val podcastsErrorMessage: String? = null,
    val selectedPodcastId: String? = null,
    val selectedPodcastTitle: String = "",
    val podcastEpisodes: List<PodcastEpisodeUiItem> = emptyList(),
    val isEpisodesLoading: Boolean = false,
    val episodesErrorMessage: String? = null
)

private data class ScheduleFetchWindow(
    val startDate: String,
    val endDate: String,
    val startMillis: Long,
    val endMillis: Long
)

class RadioViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = RadioRepository()

    private val _uiState = MutableStateFlow(RadioUiState())
    val uiState: StateFlow<RadioUiState> = _uiState.asStateFlow()

    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var controller: MediaController? = null

    private val episodesCache = mutableMapOf<String, List<PodcastEpisodeUiItem>>()
    private var loadedScheduleStartMillis: Long? = null
    private var loadedScheduleEndMillis: Long? = null

    private val playerListener = object : Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _uiState.update { it.copy(isPlaying = isPlaying) }
            syncPodcastProgress()
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            _uiState.update {
                it.copy(
                    isBuffering = playbackState == Player.STATE_BUFFERING,
                    isPlaying = controller?.isPlaying == true
                )
            }
            syncPodcastProgress()
        }

        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            syncPodcastProgress()
        }

        override fun onPlayerError(error: PlaybackException) {
            _uiState.update {
                it.copy(playerErrorMessage = "Player error: ${error.errorCodeName}")
            }
        }
    }

    init {
        connectToPlaybackService()
        refreshNowPlaying()
        refreshSchedule()
        refreshPodcasts()
        startPolling()
        startPlaybackProgressUpdates()
    }

    fun togglePlayPause() {
        val mediaController = controller
        if (mediaController == null) {
            _uiState.update { it.copy(playerErrorMessage = "Media player is not ready yet.") }
            return
        }

        if (mediaController.isPlaying) {
            mediaController.pause()
            return
        }

        if (mediaController.playbackState == Player.STATE_IDLE) {
            mediaController.prepare()
        }
        mediaController.play()
    }

    fun returnToLiveRadio() {
        val mediaController = controller
        if (mediaController == null) {
            _uiState.update { it.copy(playerErrorMessage = "Media player is not ready yet.") }
            return
        }

        val liveMedia = MediaItem.Builder()
            .setUri(BuildConfig.STREAM_URL)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("RadioFEM Live")
                    .setArtist("Radio FEM")
                    .build()
            )
            .build()

        runCatching {
            mediaController.setMediaItem(liveMedia)
            mediaController.prepare()
            mediaController.play()
        }.onSuccess {
            _uiState.update {
                it.copy(
                    isLiveStreamMode = true,
                    playbackSourceLabel = "Live",
                    currentPodcastEpisodeTitle = "",
                    currentPodcastEpisodeDescription = "",
                    podcastPositionMs = 0L,
                    podcastDurationMs = 0L,
                    nowPlayingArtist = "Radio FEM",
                    nowPlayingTitle = "Syncing live stream...",
                    nowPlayingText = "Radio FEM - Syncing live stream...",
                    playerErrorMessage = null
                )
            }
            refreshNowPlaying()
        }.onFailure {
            _uiState.update {
                it.copy(playerErrorMessage = "Could not switch back to live stream.")
            }
        }
    }

    fun playPodcastEpisode(
        episodeTitle: String,
        episodeUrl: String,
        episodeDescription: String = ""
    ) {
        if (episodeUrl.isBlank()) {
            _uiState.update { it.copy(playerErrorMessage = "Episode has no playback URL.") }
            return
        }

        val mediaController = controller
        if (mediaController == null) {
            _uiState.update { it.copy(playerErrorMessage = "Media player is not ready yet.") }
            return
        }

        val podcastName = _uiState.value.selectedPodcastTitle.ifBlank { "Radio FEM Podcast" }
        val podcastMedia = MediaItem.Builder()
            .setUri(episodeUrl)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(episodeTitle.ifBlank { "Episode" })
                    .setArtist(podcastName)
                    .build()
            )
            .build()

        runCatching {
            mediaController.setMediaItem(podcastMedia)
            mediaController.prepare()
            mediaController.play()
        }.onSuccess {
            _uiState.update {
                it.copy(
                    isLiveStreamMode = false,
                    playbackSourceLabel = "Podcast",
                    currentPodcastEpisodeTitle = episodeTitle.ifBlank { "Episode" },
                    currentPodcastEpisodeDescription = episodeDescription.ifBlank { "No description" },
                    podcastPositionMs = 0L,
                    podcastDurationMs = 0L,
                    nowPlayingArtist = podcastName,
                    nowPlayingTitle = episodeTitle.ifBlank { "Episode" },
                    nowPlayingText = "$podcastName - ${episodeTitle.ifBlank { "Episode" }}",
                    playerErrorMessage = null
                )
            }
            syncPodcastProgress()
        }.onFailure {
            _uiState.update {
                it.copy(playerErrorMessage = "Could not play this episode.")
            }
        }
    }

    fun seekPodcastTo(positionMs: Long) {
        val mediaController = controller ?: return
        if (_uiState.value.isLiveStreamMode) return

        val safeDuration = mediaController.duration.takeIf { it > 0 } ?: 0L
        val target = if (safeDuration > 0) {
            positionMs.coerceIn(0L, safeDuration)
        } else {
            positionMs.coerceAtLeast(0L)
        }

        mediaController.seekTo(target)
        syncPodcastProgress()
    }

    fun skipPodcastBy(deltaMs: Long) {
        val mediaController = controller ?: return
        if (_uiState.value.isLiveStreamMode) return
        seekPodcastTo(mediaController.currentPosition + deltaMs)
    }

    fun refreshNowPlaying() {
        viewModelScope.launch {
            val showFirstLoading = _uiState.value.lastUpdated.isBlank()
            _uiState.update { it.copy(isLoading = showFirstLoading, apiErrorMessage = null) }

            runCatching {
                repository.fetchNowPlaying()
            }.onSuccess { payload ->
                val (artist, title) = resolveNowPlaying(payload.nowPlaying.song)
                val songText = "$artist - $title"
                var shouldUpdateLiveNotificationMetadata = false

                _uiState.update { current ->
                    if (current.isLiveStreamMode) {
                        shouldUpdateLiveNotificationMetadata =
                            current.nowPlayingArtist != artist || current.nowPlayingTitle != title
                        current.copy(
                            stationName = payload.station.name.ifBlank { "Radio FEM" },
                            nowPlayingText = songText,
                            nowPlayingArtist = artist,
                            nowPlayingTitle = title,
                            listeners = payload.listeners.current,
                            isLoading = false,
                            lastUpdated = formatCurrentDateTime(),
                            apiErrorMessage = null
                        )
                    } else {
                        current.copy(
                            stationName = payload.station.name.ifBlank { "Radio FEM" },
                            listeners = payload.listeners.current,
                            isLoading = false,
                            lastUpdated = formatCurrentDateTime(),
                            apiErrorMessage = null
                        )
                    }
                }

                if (shouldUpdateLiveNotificationMetadata) {
                    updateLiveNotificationMetadata(artist = artist, title = title)
                }
            }.onFailure {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        apiErrorMessage = "Could not update live status."
                    )
                }
            }
        }
    }

    fun refreshSchedule(
        targetRangeStartMillis: Long? = null,
        targetRangeEndMillis: Long? = null
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isScheduleLoading = true, scheduleErrorMessage = null) }
            val fetchWindow = scheduleFetchRange(
                referenceTimeMillis = System.currentTimeMillis(),
                targetRangeStartMillis = targetRangeStartMillis,
                targetRangeEndMillis = targetRangeEndMillis
            )

            runCatching {
                repository.fetchSchedule(
                    startDate = fetchWindow.startDate,
                    endDate = fetchWindow.endDate
                )
            }.onSuccess { payload ->
                val programScheduleItems = payload
                    .filter(::isProgramScheduleItem)
                    .map(::mapSchedule)

                _uiState.update { current ->
                    val mergedSchedule = if (
                        targetRangeStartMillis != null &&
                        targetRangeEndMillis != null &&
                        current.schedule.isNotEmpty()
                    ) {
                        mergeScheduleItems(current.schedule, programScheduleItems)
                    } else {
                        programScheduleItems
                    }

                    current.copy(
                        isScheduleLoading = false,
                        schedule = mergedSchedule,
                        scheduleErrorMessage = null
                    )
                }
                loadedScheduleStartMillis = loadedScheduleStartMillis
                    ?.coerceAtMost(fetchWindow.startMillis)
                    ?: fetchWindow.startMillis
                loadedScheduleEndMillis = loadedScheduleEndMillis
                    ?.coerceAtLeast(fetchWindow.endMillis)
                    ?: fetchWindow.endMillis
            }.onFailure {
                _uiState.update {
                    it.copy(
                        isScheduleLoading = false,
                        scheduleErrorMessage = "Could not load schedule."
                    )
                }
            }
        }
    }

    fun ensureScheduleRange(rangeStartMillis: Long, rangeEndMillis: Long) {
        val loadedStart = loadedScheduleStartMillis
        val loadedEnd = loadedScheduleEndMillis
        if (
            loadedStart != null &&
            loadedEnd != null &&
            rangeStartMillis >= loadedStart &&
            rangeEndMillis <= loadedEnd
        ) {
            return
        }
        refreshSchedule(
            targetRangeStartMillis = rangeStartMillis,
            targetRangeEndMillis = rangeEndMillis
        )
    }

    fun refreshPodcasts() {
        viewModelScope.launch {
            _uiState.update { it.copy(isPodcastsLoading = true, podcastsErrorMessage = null) }

            runCatching {
                repository.fetchPodcasts()
            }.onSuccess { payload ->
                _uiState.update {
                    it.copy(
                        isPodcastsLoading = false,
                        podcasts = payload.map(::mapPodcast),
                        podcastsErrorMessage = null
                    )
                }
            }.onFailure {
                _uiState.update {
                    it.copy(
                        isPodcastsLoading = false,
                        podcastsErrorMessage = "Could not load podcasts."
                    )
                }
            }
        }
    }

    fun openPodcast(podcastId: String) {
        val selected = _uiState.value.podcasts.firstOrNull { it.id == podcastId } ?: return
        _uiState.update {
            it.copy(
                selectedPodcastId = selected.id,
                selectedPodcastTitle = selected.title,
                episodesErrorMessage = null
            )
        }
        loadEpisodesForPodcast(selected.id)
    }

    fun closePodcast() {
        _uiState.update {
            it.copy(
                selectedPodcastId = null,
                selectedPodcastTitle = "",
                podcastEpisodes = emptyList(),
                isEpisodesLoading = false,
                episodesErrorMessage = null
            )
        }
    }

    private fun loadEpisodesForPodcast(podcastId: String) {
        episodesCache[podcastId]?.let { cached ->
            _uiState.update {
                it.copy(
                    podcastEpisodes = cached,
                    isEpisodesLoading = false,
                    episodesErrorMessage = null
                )
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isEpisodesLoading = true, episodesErrorMessage = null) }

            runCatching {
                repository.fetchPodcastEpisodes(podcastId)
            }.onSuccess { payload ->
                val mapped = payload.map(::mapEpisode)
                episodesCache[podcastId] = mapped
                if (_uiState.value.selectedPodcastId == podcastId) {
                    _uiState.update {
                        it.copy(
                            isEpisodesLoading = false,
                            podcastEpisodes = mapped,
                            episodesErrorMessage = null
                        )
                    }
                }
            }.onFailure {
                if (_uiState.value.selectedPodcastId == podcastId) {
                    _uiState.update {
                        it.copy(
                            isEpisodesLoading = false,
                            episodesErrorMessage = "Could not load episodes for this podcast."
                        )
                    }
                }
            }
        }
    }

    private fun connectToPlaybackService() {
        val context = getApplication<Application>().applicationContext
        val sessionToken = SessionToken(context, ComponentName(context, RadioPlaybackService::class.java))

        val future = MediaController.Builder(context, sessionToken).buildAsync()
        controllerFuture = future
        future.addListener(
            {
                runCatching { future.get() }
                    .onSuccess { mediaController ->
                        controller = mediaController
                        mediaController.addListener(playerListener)
                        _uiState.update {
                            it.copy(
                                isPlayerConnected = true,
                                isPlaying = mediaController.isPlaying,
                                isBuffering = mediaController.playbackState == Player.STATE_BUFFERING,
                                playerErrorMessage = null
                            )
                        }
                    }
                    .onFailure {
                        _uiState.update {
                            it.copy(
                                isPlayerConnected = false,
                                playerErrorMessage = "Could not connect to media player."
                            )
                        }
                    }
            },
            ContextCompat.getMainExecutor(context)
        )
    }

    private fun startPolling() {
        viewModelScope.launch {
            var scheduleCycles = 0
            while (isActive) {
                delay(15_000)
                refreshNowPlaying()
                scheduleCycles += 1
                if (scheduleCycles >= 4) {
                    refreshSchedule()
                    scheduleCycles = 0
                }
            }
        }
    }

    private fun startPlaybackProgressUpdates() {
        viewModelScope.launch {
            while (isActive) {
                delay(1000)
                syncPodcastProgress()
            }
        }
    }

    private fun syncPodcastProgress() {
        val mediaController = controller ?: return
        if (_uiState.value.isLiveStreamMode) {
            if (_uiState.value.podcastPositionMs != 0L || _uiState.value.podcastDurationMs != 0L) {
                _uiState.update { it.copy(podcastPositionMs = 0L, podcastDurationMs = 0L) }
            }
            return
        }

        val duration = mediaController.duration.takeIf { it > 0 } ?: 0L
        val position = mediaController.currentPosition.coerceAtLeast(0L)
        _uiState.update {
            it.copy(
                podcastPositionMs = position.coerceAtMost(duration.takeIf { d -> d > 0 } ?: Long.MAX_VALUE),
                podcastDurationMs = duration
            )
        }
    }

    private fun updateLiveNotificationMetadata(artist: String, title: String) {
        val mediaController = controller ?: return
        if (!_uiState.value.isLiveStreamMode) return

        val currentUri = mediaController.currentMediaItem
            ?.localConfiguration
            ?.uri
            ?.toString()
            .orEmpty()
            .ifBlank { BuildConfig.STREAM_URL }

        val updatedLiveMedia = MediaItem.Builder()
            .setUri(currentUri)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(title.ifBlank { "Live Track" })
                    .setArtist(artist.ifBlank { "Radio FEM" })
                    .setAlbumTitle(_uiState.value.stationName.ifBlank { "Radio FEM" })
                    .build()
            )
            .build()

        runCatching {
            val index = mediaController.currentMediaItemIndex
            if (mediaController.mediaItemCount > 0 && index >= 0) {
                mediaController.replaceMediaItem(index, updatedLiveMedia)
            } else {
                mediaController.setMediaItem(updatedLiveMedia)
                mediaController.prepare()
                if (_uiState.value.isPlaying) {
                    mediaController.play()
                }
            }
        }
    }

    private fun mapSchedule(item: ScheduleItemResponse): ScheduleUiItem {
        val cleanedDescription = item.description
            .removePrefix("Playlist:")
            .trim()
            .ifBlank { "No description" }
        val startAtMillis = parseIsoDateTimeMillis(item.start) ?: 0L
        val endAtMillis = parseIsoDateTimeMillis(item.end) ?: 0L

        return ScheduleUiItem(
            id = item.id,
            title = formatProgramTitle(item.title),
            description = cleanedDescription,
            dateLabel = formatIsoDate(item.start),
            timeRangeLabel = "${formatIsoTime(item.start)} - ${formatIsoTime(item.end)}",
            startAtMillis = startAtMillis,
            endAtMillis = endAtMillis,
            isNow = item.isNow
        )
    }

    private fun mapPodcast(item: PodcastResponse): PodcastUiItem {
        return PodcastUiItem(
            id = item.id,
            title = item.title,
            description = item.descriptionShort.ifBlank { "No description" },
            author = item.author.ifBlank { "Radio FEM" },
            episodesCount = item.episodesCount,
            language = item.languageName.ifBlank { "N/A" },
            feedUrl = item.links.publicFeed
        )
    }

    private fun mapEpisode(item: PodcastEpisodeResponse): PodcastEpisodeUiItem {
        val timestamp = item.publishAt ?: item.createdAt
        return PodcastEpisodeUiItem(
            id = item.id,
            title = item.title.ifBlank { "Episode" },
            description = item.descriptionShort.ifBlank { "No description" },
            publishLabel = timestamp?.let(::formatEpochDateTime) ?: "No date",
            playUrl = item.links.download.ifBlank { item.links.publicUrl }
        )
    }

    private fun formatIsoDate(value: String): String {
        if (value.length < 10) return value
        val date = value.substring(0, 10)
        val parts = date.split("-")
        if (parts.size != 3) return date
        return "${parts[2]}/${parts[1]}/${parts[0]}"
    }

    private fun formatIsoTime(value: String): String {
        if (value.length < 16) return "--:--"
        return value.substring(11, 16)
    }

    private fun formatProgramTitle(value: String): String {
        val raw = value
            .ifBlank { "Program" }
            .replaceFirst("PROG_", "", ignoreCase = true)
            .replaceFirst("PROG ", "", ignoreCase = true)

        val words = raw.replace('_', ' ').split(' ').filter { it.isNotBlank() }
        if (words.isEmpty()) return "Program"
        return words.joinToString(" ") { word ->
            word.lowercase().replaceFirstChar { first ->
                if (first.isLowerCase()) first.titlecase(Locale.getDefault()) else first.toString()
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

    private fun isProgramScheduleItem(item: ScheduleItemResponse): Boolean {
        val title = item.title.trim().uppercase(Locale.ROOT)
        return title.startsWith("PROG")
    }

    private fun mergeScheduleItems(
        existing: List<ScheduleUiItem>,
        incoming: List<ScheduleUiItem>
    ): List<ScheduleUiItem> {
        val mergedByKey = linkedMapOf<String, ScheduleUiItem>()
        existing.forEach { mergedByKey[scheduleItemKey(it)] = it }
        incoming.forEach { mergedByKey[scheduleItemKey(it)] = it }
        return mergedByKey.values.sortedBy { it.startAtMillis }
    }

    private fun scheduleItemKey(item: ScheduleUiItem): String {
        return "${item.title}|${item.startAtMillis}|${item.endAtMillis}"
    }

    private fun scheduleFetchRange(
        referenceTimeMillis: Long = System.currentTimeMillis(),
        targetRangeStartMillis: Long? = null,
        targetRangeEndMillis: Long? = null
    ): ScheduleFetchWindow {
        val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)

        val startCalendar = Calendar.getInstance()
        val endCalendar = Calendar.getInstance()

        if (targetRangeStartMillis != null && targetRangeEndMillis != null) {
            startCalendar.timeInMillis = targetRangeStartMillis
            startCalendar.set(Calendar.HOUR_OF_DAY, 0)
            startCalendar.set(Calendar.MINUTE, 0)
            startCalendar.set(Calendar.SECOND, 0)
            startCalendar.set(Calendar.MILLISECOND, 0)
            startCalendar.add(Calendar.DAY_OF_MONTH, -1)

            endCalendar.timeInMillis = targetRangeEndMillis
            endCalendar.set(Calendar.HOUR_OF_DAY, 23)
            endCalendar.set(Calendar.MINUTE, 59)
            endCalendar.set(Calendar.SECOND, 59)
            endCalendar.set(Calendar.MILLISECOND, 999)
            endCalendar.add(Calendar.DAY_OF_MONTH, 1)
        } else {
            startCalendar.timeInMillis = referenceTimeMillis
            startCalendar.set(Calendar.DAY_OF_MONTH, 1)
            startCalendar.set(Calendar.HOUR_OF_DAY, 0)
            startCalendar.set(Calendar.MINUTE, 0)
            startCalendar.set(Calendar.SECOND, 0)
            startCalendar.set(Calendar.MILLISECOND, 0)
            startCalendar.add(Calendar.MONTH, -1)

            endCalendar.timeInMillis = referenceTimeMillis
            endCalendar.set(Calendar.DAY_OF_MONTH, 1)
            endCalendar.set(Calendar.HOUR_OF_DAY, 23)
            endCalendar.set(Calendar.MINUTE, 59)
            endCalendar.set(Calendar.SECOND, 59)
            endCalendar.set(Calendar.MILLISECOND, 999)
            endCalendar.add(Calendar.MONTH, 3)
            endCalendar.add(Calendar.DAY_OF_MONTH, -1)
        }

        return ScheduleFetchWindow(
            startDate = formatter.format(startCalendar.time),
            endDate = formatter.format(endCalendar.time),
            startMillis = startCalendar.timeInMillis,
            endMillis = endCalendar.timeInMillis
        )
    }

    private fun parseIsoDateTimeMillis(value: String): Long? {
        return runCatching {
            val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            formatter.parse(value)?.time
        }.getOrNull()
    }

    private fun formatEpochDateTime(epochSeconds: Long): String {
        val formatter = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
        return formatter.format(Date(epochSeconds * 1000))
    }

    private fun formatCurrentDateTime(): String {
        val formatter = SimpleDateFormat("dd/MM HH:mm", Locale.getDefault())
        return formatter.format(Date())
    }

    override fun onCleared() {
        controller?.removeListener(playerListener)
        controller = null
        controllerFuture?.let(MediaController::releaseFuture)
        controllerFuture = null
        super.onCleared()
    }
}
