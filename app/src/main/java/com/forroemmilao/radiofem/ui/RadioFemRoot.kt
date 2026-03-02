package com.forroemmilao.radiofem.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.PauseCircle
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import com.forroemmilao.radiofem.R
import java.util.Locale
import kotlinx.coroutines.launch

private const val CONTACT_EMAIL = "info@radio.forroemmilao.com"

private enum class TabItem { PLAYER, SCHEDULE, PODCASTS, CONTACT }
private enum class ScheduleCalendarMode { WEEKLY, MONTHLY }

@Composable
fun RadioFemRoot(viewModel: RadioViewModel = viewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val pagerState = rememberPagerState(
        initialPage = TabItem.PLAYER.ordinal,
        pageCount = { TabItem.entries.size }
    )
    val coroutineScope = rememberCoroutineScope()

    val scrim = Brush.verticalGradient(
        colors = listOf(Color(0xA6000000), Color(0xBF000000), Color(0xD9000000))
    )

    val forroScheme = darkColorScheme(
        primary = Color(0xFFFFCC00),
        secondary = Color(0xFF228B22),
        tertiary = Color(0xFFB22222),
        background = Color(0xFF121212),
        surface = Color(0xFF1F2329),
        onPrimary = Color(0xFF1A1A1A),
        onBackground = Color(0xFFF2F2F2),
        onSurface = Color(0xFFF2F2F2)
    )

    MaterialTheme(colorScheme = forroScheme) {
        Box(modifier = Modifier.fillMaxSize()) {
            Image(
                painter = painterResource(id = R.drawable.radio_bg),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(scrim)
            )

            Surface(
                modifier = Modifier.fillMaxSize(),
                color = Color.Transparent,
                contentColor = MaterialTheme.colorScheme.onBackground
            ) {
                Scaffold(
                    containerColor = Color.Transparent,
                    bottomBar = {
                        NavigationBar(containerColor = Color(0xDD3E2A1F)) {
                            NavigationBarItem(
                                selected = pagerState.currentPage == TabItem.PLAYER.ordinal,
                                onClick = {
                                    coroutineScope.launch {
                                        pagerState.animateScrollToPage(TabItem.PLAYER.ordinal)
                                    }
                                },
                                icon = { Icon(Icons.Default.GraphicEq, contentDescription = "Live") },
                                label = { Text("Live") }
                            )
                            NavigationBarItem(
                                selected = pagerState.currentPage == TabItem.SCHEDULE.ordinal,
                                onClick = {
                                    coroutineScope.launch {
                                        pagerState.animateScrollToPage(TabItem.SCHEDULE.ordinal)
                                    }
                                },
                                icon = { Icon(Icons.Default.CalendarMonth, contentDescription = "Schedule") },
                                label = { Text("Schedule") }
                            )
                            NavigationBarItem(
                                selected = pagerState.currentPage == TabItem.PODCASTS.ordinal,
                                onClick = {
                                    coroutineScope.launch {
                                        pagerState.animateScrollToPage(TabItem.PODCASTS.ordinal)
                                    }
                                },
                                icon = { Icon(Icons.Default.Mic, contentDescription = "Podcasts") },
                                label = { Text("Podcasts") }
                            )
                            NavigationBarItem(
                                selected = pagerState.currentPage == TabItem.CONTACT.ordinal,
                                onClick = {
                                    coroutineScope.launch {
                                        pagerState.animateScrollToPage(TabItem.CONTACT.ordinal)
                                    }
                                },
                                icon = { Icon(Icons.Default.Email, contentDescription = "Contact") },
                                label = { Text("Contact") }
                            )
                        }
                    }
                ) { contentPadding ->
                    HorizontalPager(
                        state = pagerState,
                        modifier = Modifier.fillMaxSize(),
                        beyondViewportPageCount = 1
                    ) { page ->
                        when (TabItem.entries[page]) {
                            TabItem.PLAYER -> PlayerTab(
                                state = uiState,
                                onPlayPause = viewModel::togglePlayPause,
                                onSeekTo = viewModel::seekPodcastTo,
                                onSkipBackward = { viewModel.skipPodcastBy(-15_000) },
                                onSkipForward = { viewModel.skipPodcastBy(30_000) },
                                onReturnToLive = viewModel::returnToLiveRadio,
                                onRefresh = viewModel::refreshNowPlaying,
                                paddingValues = contentPadding
                            )

                            TabItem.SCHEDULE -> ScheduleTab(
                                state = uiState,
                                onRefresh = viewModel::refreshSchedule,
                                onEnsureRange = viewModel::ensureScheduleRange,
                                paddingValues = contentPadding
                            )

                            TabItem.PODCASTS -> PodcastsTab(
                                state = uiState,
                                onRefresh = viewModel::refreshPodcasts,
                                onOpenPodcast = viewModel::openPodcast,
                                onClosePodcast = viewModel::closePodcast,
                                onPlayEpisode = { episode ->
                                    viewModel.playPodcastEpisode(
                                        episodeTitle = episode.title,
                                        episodeUrl = episode.playUrl,
                                        episodeDescription = episode.description
                                    )
                                    coroutineScope.launch {
                                        pagerState.animateScrollToPage(TabItem.PLAYER.ordinal)
                                    }
                                },
                                paddingValues = contentPadding
                            )

                            TabItem.CONTACT -> ContactTab(
                                paddingValues = contentPadding
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PlayerTab(
    state: RadioUiState,
    onPlayPause: () -> Unit,
    onSeekTo: (Long) -> Unit,
    onSkipBackward: () -> Unit,
    onSkipForward: () -> Unit,
    onReturnToLive: () -> Unit,
    onRefresh: () -> Unit,
    paddingValues: PaddingValues
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues)
            .padding(horizontal = 20.dp, vertical = 24.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Top
    ) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xB0151515))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 14.dp, vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = state.stationName,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFFFF4D6),
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Now Playing",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color(0xFFFFCC00)
                )

                Spacer(modifier = Modifier.height(6.dp))

                if (state.isLiveStreamMode) {
                    Text(
                        text = state.nowPlayingArtist,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFF7F7F7),
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = state.nowPlayingTitle,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFFFF4D6),
                        textAlign = TextAlign.Center
                    )
                } else {
                    Text(
                        text = state.currentPodcastEpisodeTitle.ifBlank { state.nowPlayingTitle },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFFFF4D6),
                        textAlign = TextAlign.Center
                    )
                    if (state.currentPodcastEpisodeDescription.isNotBlank()) {
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = state.currentPodcastEpisodeDescription,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFFF1F1F1),
                            textAlign = TextAlign.Center
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Source: ${state.playbackSourceLabel}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFFFFCC00),
                    textAlign = TextAlign.Center
                )

                if (!state.isLiveStreamMode && state.nowPlayingArtist.isNotBlank()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Podcast: ${state.nowPlayingArtist}",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFFF1F1F1),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (state.isLoading || state.isBuffering) {
            CircularProgressIndicator()
            Spacer(modifier = Modifier.height(16.dp))
        }

        Button(
            onClick = onPlayPause,
            enabled = state.isPlayerConnected
        ) {
            Icon(
                imageVector = if (state.isPlaying) Icons.Default.PauseCircle else Icons.Default.PlayCircle,
                contentDescription = null
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(if (state.isPlaying) "Pause" else "Listen Now")
        }

        if (!state.isLiveStreamMode) {
            Spacer(modifier = Modifier.height(10.dp))
            OutlinedButton(
                onClick = onReturnToLive,
                enabled = state.isPlayerConnected
            ) {
                Text("Back to Live")
            }

            Spacer(modifier = Modifier.height(12.dp))

            val sliderMax = if (state.podcastDurationMs > 0L) state.podcastDurationMs.toFloat() else 1f
            val sliderValue = state.podcastPositionMs
                .coerceAtLeast(0L)
                .coerceAtMost(state.podcastDurationMs.takeIf { it > 0L } ?: Long.MAX_VALUE)
                .toFloat()

            Slider(
                value = sliderValue,
                onValueChange = { onSeekTo(it.toLong()) },
                valueRange = 0f..sliderMax,
                enabled = state.isPlayerConnected && state.podcastDurationMs > 0L
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = formatPlaybackTime(state.podcastPositionMs),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFFF1F1F1)
                )
                Text(
                    text = formatPlaybackTime(state.podcastDurationMs),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFFF1F1F1)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(
                    onClick = onSkipBackward,
                    enabled = state.isPlayerConnected && state.podcastDurationMs > 0L
                ) {
                    Text("-15s")
                }
                OutlinedButton(
                    onClick = onSkipForward,
                    enabled = state.isPlayerConnected && state.podcastDurationMs > 0L
                ) {
                    Text("+30s")
                }
            }
        }

        if (!state.isPlayerConnected) {
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = "Connecting media player...",
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFFF1F1F1),
                textAlign = TextAlign.Center
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        IconButton(onClick = onRefresh) {
            Icon(Icons.Default.Refresh, contentDescription = "Refresh")
        }

        Text(
            text = "Listeners now: ${state.listeners}",
            style = MaterialTheme.typography.bodyLarge,
            color = Color(0xFFF7F7F7)
        )

        if (state.lastUpdated.isNotBlank()) {
            Text(
                text = "Updated at ${state.lastUpdated}",
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFFF1F1F1)
            )
        }

        state.apiErrorMessage?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center
            )
        }

        state.playerErrorMessage?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun ScheduleTab(
    state: RadioUiState,
    onRefresh: () -> Unit,
    onEnsureRange: (Long, Long) -> Unit,
    paddingValues: PaddingValues
) {
    var calendarMode by rememberSaveable { mutableStateOf(ScheduleCalendarMode.WEEKLY) }
    var weekOffset by rememberSaveable { mutableStateOf(0) }
    var monthOffset by rememberSaveable { mutableStateOf(0) }

    val periodRange = when (calendarMode) {
        ScheduleCalendarMode.WEEKLY -> currentWeekRangeMillis(weekOffset = weekOffset)
        ScheduleCalendarMode.MONTHLY -> currentMonthRangeMillis(monthOffset = monthOffset)
    }
    val rangeStart = periodRange.first
    val rangeEnd = periodRange.second
    val periodLabel = when (calendarMode) {
        ScheduleCalendarMode.WEEKLY -> formatWeekRangeLabel(rangeStart, rangeEnd)
        ScheduleCalendarMode.MONTHLY -> formatMonthRangeLabel(rangeStart)
    }

    LaunchedEffect(rangeStart, rangeEnd) {
        onEnsureRange(rangeStart, rangeEnd)
    }

    val visibleSchedule = remember(state.schedule, calendarMode, rangeStart, rangeEnd) {
        state.schedule
            .filter { item ->
                if (item.startAtMillis <= 0L || item.endAtMillis <= 0L) return@filter false
                item.endAtMillis >= rangeStart && item.startAtMillis <= rangeEnd
            }
            .sortedBy { item ->
                item.startAtMillis
            }
    }

    val currentProgram = visibleSchedule.firstOrNull { it.isNow }
    val otherPrograms = visibleSchedule.filterNot { it.isNow }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues)
            .padding(horizontal = 16.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Schedule",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Station calendar",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                IconButton(onClick = onRefresh) {
                    Icon(Icons.Default.Refresh, contentDescription = "Refresh schedule")
                }
            }
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (calendarMode == ScheduleCalendarMode.WEEKLY) {
                    Button(onClick = {}, enabled = false) {
                        Text("Weekly")
                    }
                } else {
                    OutlinedButton(onClick = {
                        calendarMode = ScheduleCalendarMode.WEEKLY
                        weekOffset = 0
                    }) {
                        Text("Weekly")
                    }
                }

                if (calendarMode == ScheduleCalendarMode.MONTHLY) {
                    Button(onClick = {}, enabled = false) {
                        Text("Monthly")
                    }
                } else {
                    OutlinedButton(onClick = {
                        calendarMode = ScheduleCalendarMode.MONTHLY
                        monthOffset = 0
                    }) {
                        Text("Monthly")
                    }
                }
            }
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                IconButton(
                    onClick = {
                        if (calendarMode == ScheduleCalendarMode.WEEKLY) {
                            weekOffset -= 1
                        } else {
                            monthOffset -= 1
                        }
                    }
                ) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous period")
                }

                Text(
                    text = periodLabel,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center
                )

                IconButton(
                    onClick = {
                        if (calendarMode == ScheduleCalendarMode.WEEKLY) {
                            weekOffset += 1
                        } else {
                            monthOffset += 1
                        }
                    }
                ) {
                    Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next period")
                }
            }
        }

        if (state.isScheduleLoading) {
            item {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    CircularProgressIndicator()
                }
            }
        }

        state.scheduleErrorMessage?.let { error ->
            item {
                Text(
                    text = error,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }

        if (!state.isScheduleLoading && visibleSchedule.isEmpty() && state.scheduleErrorMessage == null) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF1F2329))
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(
                            text = if (calendarMode == ScheduleCalendarMode.WEEKLY) {
                                "No programs found for this week."
                            } else {
                                "No programs found for this month."
                            },
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }

        currentProgram?.let { item ->
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFB22222))
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(
                            text = "ON AIR NOW",
                            style = MaterialTheme.typography.labelLarge,
                            color = Color.White
                        )
                        Text(
                            text = item.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "${item.dateLabel} • ${item.timeRangeLabel}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White
                        )
                    }
                }
            }
        }

        items(otherPrograms) { item ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                )
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = "${item.dateLabel} • ${item.timeRangeLabel}",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = item.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = item.description,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
}

@Composable
private fun ContactTab(
    paddingValues: PaddingValues
) {
    val context = LocalContext.current

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues)
            .padding(horizontal = 16.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Column {
                Text(
                    text = "Contact",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Talk to the Radio FEM team",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                )
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = "About Radio FEM",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Radio FEM is an independent and collaborative radio project focused on Forro culture.",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Our proposal is to deliver high-quality curation with artistic freedom, no commercial pressure, and strong respect for Brazilian roots and community values.",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                )
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = "Email",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = CONTACT_EMAIL,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Button(onClick = { openEmail(context, CONTACT_EMAIL) }) {
                        Icon(Icons.Default.Email, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Send Email")
                    }
                }
            }
        }
    }
}

@Composable
private fun PodcastsTab(
    state: RadioUiState,
    onRefresh: () -> Unit,
    onOpenPodcast: (String) -> Unit,
    onClosePodcast: () -> Unit,
    onPlayEpisode: (PodcastEpisodeUiItem) -> Unit,
    paddingValues: PaddingValues
) {
    val context = LocalContext.current

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues)
            .padding(horizontal = 16.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Podcasts",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Recorded content from Radio FEM",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                IconButton(onClick = onRefresh) {
                    Icon(Icons.Default.Refresh, contentDescription = "Refresh podcasts")
                }
            }
        }

        if (state.isPodcastsLoading) {
            item {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    CircularProgressIndicator()
                }
            }
        }

        state.podcastsErrorMessage?.let { error ->
            item {
                Text(
                    text = error,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }

        if (state.selectedPodcastId == null) {
            items(state.podcasts) { podcast ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                    )
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(
                            text = podcast.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${podcast.author} • ${podcast.episodesCount} episodes • ${podcast.language}",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = podcast.description,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(10.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(onClick = { onOpenPodcast(podcast.id) }) {
                                Text("View Episodes")
                            }
                            OutlinedButton(
                                onClick = { openExternalUrl(context, podcast.feedUrl) },
                                enabled = podcast.feedUrl.isNotBlank()
                            ) {
                                Icon(Icons.AutoMirrored.Filled.OpenInNew, contentDescription = null)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("RSS Feed")
                            }
                        }
                    }
                }
            }
        } else {
            item {
                OutlinedButton(onClick = onClosePodcast) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Back to Podcasts")
                }
            }

            item {
                Text(
                    text = state.selectedPodcastTitle,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }

            if (state.isEpisodesLoading) {
                item {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                        CircularProgressIndicator()
                    }
                }
            }

            state.episodesErrorMessage?.let { error ->
                item {
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            items(state.podcastEpisodes) { episode ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                    )
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(
                            text = episode.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = episode.publishLabel,
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = episode.description,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(10.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = { onPlayEpisode(episode) },
                                enabled = episode.playUrl.isNotBlank()
                            ) {
                                Text("Listen in App")
                            }
                            OutlinedButton(
                                onClick = { openExternalUrl(context, episode.playUrl) },
                                enabled = episode.playUrl.isNotBlank()
                            ) {
                                Icon(Icons.AutoMirrored.Filled.OpenInNew, contentDescription = null)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Open")
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun openExternalUrl(context: Context, url: String) {
    if (url.isBlank()) return
    runCatching {
        context.startActivity(
            Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
    }
}

private fun openEmail(context: Context, email: String) {
    if (email.isBlank()) return
    runCatching {
        context.startActivity(
            Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("mailto:$email")
                putExtra(Intent.EXTRA_EMAIL, arrayOf(email))
                putExtra(Intent.EXTRA_SUBJECT, "Radio FEM Contact")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
    }
}

private fun formatPlaybackTime(ms: Long): String {
    if (ms <= 0L) return "00:00"
    val totalSeconds = ms / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) {
        String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.US, "%02d:%02d", minutes, seconds)
    }
}

private fun currentWeekRangeMillis(
    referenceTimeMillis: Long = System.currentTimeMillis(),
    weekOffset: Int = 0
): Pair<Long, Long> {
    val calendar = Calendar.getInstance().apply {
        timeInMillis = referenceTimeMillis
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }

    val firstDayOfWeek = calendar.firstDayOfWeek
    val currentDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
    val diffToWeekStart = (7 + (currentDayOfWeek - firstDayOfWeek)) % 7
    calendar.add(Calendar.DAY_OF_MONTH, -diffToWeekStart)
    if (weekOffset != 0) {
        calendar.add(Calendar.WEEK_OF_YEAR, weekOffset)
    }
    val start = calendar.timeInMillis

    calendar.add(Calendar.DAY_OF_MONTH, 7)
    calendar.add(Calendar.MILLISECOND, -1)
    val end = calendar.timeInMillis
    return start to end
}

private fun currentMonthRangeMillis(
    referenceTimeMillis: Long = System.currentTimeMillis(),
    monthOffset: Int = 0
): Pair<Long, Long> {
    val calendar = Calendar.getInstance().apply {
        timeInMillis = referenceTimeMillis
        set(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    if (monthOffset != 0) {
        calendar.add(Calendar.MONTH, monthOffset)
    }

    val start = calendar.timeInMillis
    calendar.add(Calendar.MONTH, 1)
    calendar.add(Calendar.MILLISECOND, -1)
    val end = calendar.timeInMillis
    return start to end
}

private fun formatWeekRangeLabel(startMillis: Long, endMillis: Long): String {
    val startFmt = SimpleDateFormat("dd MMM", Locale.getDefault())
    val endFmt = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
    return "${startFmt.format(Date(startMillis))} - ${endFmt.format(Date(endMillis))}"
}

private fun formatMonthRangeLabel(startMillis: Long): String {
    val monthFmt = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
    return monthFmt.format(Date(startMillis))
}
