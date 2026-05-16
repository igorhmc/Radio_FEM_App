import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/azuracast_reports_models.dart';
import '../models/radio_models.dart';
import '../services/azuracast_reports_service.dart';
import '../services/radio_api_service.dart';
import '../services/radio_audio_handler.dart';
import '../services/watch_control_bridge.dart';

class RadioController extends ChangeNotifier {
  RadioController({
    required RadioApiService apiService,
    required AzuraCastReportsService reportsService,
    required RadioPlaybackService playbackService,
    this.autoplayOnInitialize = false,
  }) : _apiService = apiService,
       _reportsService = reportsService,
       _playbackService = playbackService;

  final RadioApiService _apiService;
  final AzuraCastReportsService _reportsService;
  final RadioPlaybackService _playbackService;
  final WatchControlBridgeServer _watchBridgeServer =
      WatchControlBridgeServer();
  final bool autoplayOnInitialize;

  static const _metadataRegressionWindow = Duration(minutes: 2);

  final Map<String, List<PodcastEpisode>> _episodesCache =
      <String, List<PodcastEpisode>>{};

  StreamSubscription<PlaybackStatus>? _playbackSubscription;
  StreamSubscription<PlaybackMediaItem?>? _mediaItemSubscription;
  Timer? _pollTimer;
  Timer? _progressTimer;

  bool _initialized = false;
  int _schedulePollCount = 0;
  DateTime? _loadedScheduleStart;
  DateTime? _loadedScheduleEnd;
  DateTime? _lastAudienceRefreshAt;
  DateTime? _liveMetadataChangedAt;
  _LiveMetadataSnapshot? _currentLiveMetadata;
  _LiveMetadataSnapshot? _previousLiveMetadata;

  String stationName = AppConfig.stationName;
  String nowPlayingArtist = 'Loading artist...';
  String nowPlayingTitle = 'Loading track...';
  int listeners = 0;
  bool isPlaying = false;
  bool isBuffering = false;
  bool isLiveStreamMode = true;
  bool isLoading = true;
  bool isScheduleLoading = false;
  bool isPodcastsLoading = false;
  bool isEpisodesLoading = false;
  bool isPartnersLoading = false;
  String playbackSourceLabel = 'Live';
  double volume = 1.0;
  String currentArtworkUrl = '';
  String currentPodcastEpisodeTitle = '';
  String currentPodcastEpisodeDescription = '';
  String selectedPodcastTitle = '';
  String? selectedPodcastId;
  String? apiErrorMessage;
  String? playerErrorMessage;
  String? scheduleErrorMessage;
  String? podcastsErrorMessage;
  String? episodesErrorMessage;
  String? partnersErrorMessage;
  String? audienceErrorMessage;
  String lastUpdated = '';
  Duration podcastPosition = Duration.zero;
  Duration podcastDuration = Duration.zero;
  List<ScheduleItem> schedule = const <ScheduleItem>[];
  List<PodcastItem> podcasts = const <PodcastItem>[];
  List<PodcastEpisode> podcastEpisodes = const <PodcastEpisode>[];
  List<PartnerItem> partners = const <PartnerItem>[];
  List<TopCountryAudience> topCountriesLast30Days =
      const <TopCountryAudience>[];
  int listenersLast30Days = 0;
  int audienceWindowDays = 30;
  bool hasAudienceAnalytics = false;

  String get audienceWindowLabel => 'Last $audienceWindowDays days';

  ScheduleItem? get currentProgram {
    final now = DateTime.now();
    final currentItems =
        schedule.where((item) {
          return !now.isBefore(item.startAt) && now.isBefore(item.endAt);
        }).toList()..sort((a, b) {
          final priority = (b.isFeaturedProgram ? 1 : 0).compareTo(
            a.isFeaturedProgram ? 1 : 0,
          );
          if (priority != 0) {
            return priority;
          }
          return b.startAt.compareTo(a.startAt);
        });

    return currentItems.firstOrNull;
  }

  Future<void> initialize() {
    if (_initialized) {
      return Future<void>.value();
    }
    _initialized = true;

    _playbackSubscription = _playbackService.statusStream.listen((state) {
      if (isPlaying == state.isPlaying &&
          isBuffering == state.isBuffering &&
          isLiveStreamMode == state.isLive &&
          volume == state.volume) {
        return;
      }
      isPlaying = state.isPlaying;
      isBuffering = state.isBuffering;
      isLiveStreamMode = state.isLive;
      volume = state.volume;
      notifyListeners();
    });

    _mediaItemSubscription = _playbackService.mediaItemStream.listen((item) {
      if (item == null) {
        return;
      }
      if (isLiveStreamMode) {
        final changed = _applyLiveMetadata(
          artist: item.artist,
          title: item.title,
          artworkUrl: item.artworkUrl,
        );
        if (changed) {
          notifyListeners();
        }
      }
    });

    unawaited(
      _watchBridgeServer.start(
        statusProvider: _bridgeStatus,
        commandHandler: _handleBridgeCommand,
      ),
    );
    unawaited(refreshNowPlaying());
    unawaited(refreshAudienceSnapshot());
    unawaited(refreshSchedule());
    unawaited(refreshPodcasts());
    unawaited(refreshPartners());

    if (autoplayOnInitialize && !isPlaying) {
      unawaited(startLivePlayback());
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(refreshNowPlaying());
      _schedulePollCount += 1;
      if (_schedulePollCount >= 4) {
        _schedulePollCount = 0;
        unawaited(refreshSchedule());
      }
      final now = DateTime.now();
      final lastAudienceRefreshAt = _lastAudienceRefreshAt;
      if (now.minute % 10 == 0 &&
          (lastAudienceRefreshAt == null ||
              now.difference(lastAudienceRefreshAt) >=
                  const Duration(minutes: 5))) {
        _lastAudienceRefreshAt = now;
        unawaited(refreshAudienceSnapshot());
      }
    });

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshPlaybackProgress());
    });

    return Future<void>.value();
  }

  Future<void> togglePlayPause() async {
    playerErrorMessage = null;
    if (isPlaying) {
      await _playbackService.pause();
      return;
    }

    if (isLiveStreamMode) {
      await startLivePlayback();
      return;
    }

    await _playbackService.play();
  }

  Future<void> startLivePlayback() async {
    playerErrorMessage = null;
    try {
      await _playbackService.playLive(
        url: AppConfig.streamUrl,
        stationName: stationName,
        artist: nowPlayingArtist,
        title: nowPlayingTitle,
        artworkUrl: currentArtworkUrl,
      );
      isLiveStreamMode = true;
      playbackSourceLabel = 'Live';
      currentPodcastEpisodeTitle = '';
      currentPodcastEpisodeDescription = '';
      podcastPosition = Duration.zero;
      podcastDuration = Duration.zero;
      notifyListeners();
      await refreshNowPlaying();
    } catch (_) {
      playerErrorMessage = 'Could not start the live stream.';
      notifyListeners();
    }
  }

  Future<void> returnToLive() async {
    await startLivePlayback();
  }

  Future<void> playPodcastEpisode(PodcastEpisode episode) async {
    if (episode.playUrl.isEmpty) {
      playerErrorMessage = 'This episode has no playback URL.';
      notifyListeners();
      return;
    }

    playerErrorMessage = null;
    try {
      await _playbackService.playPodcast(
        url: episode.playUrl,
        title: episode.title,
        podcastTitle: selectedPodcastTitle.isEmpty
            ? AppConfig.stationName
            : selectedPodcastTitle,
        description: episode.description,
      );
      isLiveStreamMode = false;
      playbackSourceLabel = 'Podcast';
      currentArtworkUrl = '';
      currentPodcastEpisodeTitle = episode.title;
      currentPodcastEpisodeDescription = episode.description;
      nowPlayingArtist = selectedPodcastTitle.isEmpty
          ? AppConfig.stationName
          : selectedPodcastTitle;
      nowPlayingTitle = episode.title;
      podcastPosition = Duration.zero;
      podcastDuration = Duration.zero;
      notifyListeners();
    } catch (_) {
      playerErrorMessage = 'Could not play this episode.';
      notifyListeners();
    }
  }

  Future<void> seekPodcastTo(Duration position) async {
    if (isLiveStreamMode) {
      return;
    }
    final maxDuration = podcastDuration;
    final clamped = maxDuration > Duration.zero && position > maxDuration
        ? maxDuration
        : position;
    await _playbackService.seek(
      clamped < Duration.zero ? Duration.zero : clamped,
    );
    await _refreshPlaybackProgress();
  }

  Future<void> skipPodcastBy(Duration delta) async {
    if (isLiveStreamMode) {
      return;
    }
    await _playbackService.seekRelative(delta);
    await _refreshPlaybackProgress();
  }

  Future<void> refreshNowPlaying() async {
    final showLoading = lastUpdated.isEmpty;
    isLoading = showLoading;
    apiErrorMessage = null;
    notifyListeners();

    try {
      final payload = await _apiService.fetchNowPlaying();
      stationName = payload.stationName;
      listeners = payload.listeners;
      lastUpdated = DateFormat('dd/MM HH:mm').format(DateTime.now());
      isLoading = false;
      apiErrorMessage = null;

      if (isLiveStreamMode) {
        final metadataChanged = _applyLiveMetadata(
          artist: payload.artist,
          title: payload.title,
          artworkUrl: payload.artworkUrl,
        );
        if (metadataChanged) {
          await _playbackService.updateLiveMetadata(
            stationName: payload.stationName,
            artist: nowPlayingArtist,
            title: nowPlayingTitle,
            artworkUrl: currentArtworkUrl,
          );
        }
      }

      notifyListeners();
    } catch (_) {
      isLoading = false;
      apiErrorMessage = 'Could not update live status.';
      notifyListeners();
    }
  }

  Future<void> refreshAudienceSnapshot() async {
    if (!_reportsService.isConfigured) {
      hasAudienceAnalytics = false;
      listenersLast30Days = 0;
      audienceWindowDays = 30;
      topCountriesLast30Days = const <TopCountryAudience>[];
      audienceErrorMessage = null;
      notifyListeners();
      return;
    }

    audienceErrorMessage = null;
    notifyListeners();

    try {
      final payload = await _reportsService.fetchAudienceSummary30d();
      _lastAudienceRefreshAt = DateTime.now();
      hasAudienceAnalytics = true;
      listenersLast30Days = payload.listenersUnique30d;
      audienceWindowDays = payload.end.difference(payload.start).inDays + 1;
      topCountriesLast30Days = payload.topCountries;
      audienceErrorMessage = null;
      notifyListeners();
    } catch (_) {
      hasAudienceAnalytics = false;
      listenersLast30Days = 0;
      audienceWindowDays = 30;
      topCountriesLast30Days = const <TopCountryAudience>[];
      audienceErrorMessage = 'Could not load the audience analytics.';
      notifyListeners();
    }
  }

  bool _applyLiveMetadata({
    required String artist,
    required String title,
    String? artworkUrl,
  }) {
    final next = _LiveMetadataSnapshot(
      artist: artist,
      title: title,
      artworkUrl: artworkUrl ?? currentArtworkUrl,
    );
    if (!next.hasUsefulTrack) {
      return false;
    }

    final current =
        _currentLiveMetadata ??
        _LiveMetadataSnapshot(
          artist: nowPlayingArtist,
          title: nowPlayingTitle,
          artworkUrl: currentArtworkUrl,
        );
    final previous = _previousLiveMetadata;
    final changedAt = _liveMetadataChangedAt;
    final looksLikeRecentRegression =
        previous != null &&
        changedAt != null &&
        next.sameTrack(previous) &&
        !next.sameTrack(current) &&
        DateTime.now().difference(changedAt) < _metadataRegressionWindow;
    if (looksLikeRecentRegression) {
      return false;
    }

    var changed = false;
    final nextArtist = artist.trim();
    if (nextArtist.isNotEmpty && nextArtist != nowPlayingArtist) {
      nowPlayingArtist = nextArtist;
      changed = true;
    }
    final nextTitle = title.trim();
    if (nextTitle.isNotEmpty && nextTitle != nowPlayingTitle) {
      nowPlayingTitle = nextTitle;
      changed = true;
    }
    final nextArtworkUrl = artworkUrl?.trim() ?? '';
    if (nextArtworkUrl.isNotEmpty && nextArtworkUrl != currentArtworkUrl) {
      currentArtworkUrl = nextArtworkUrl;
      changed = true;
    }

    final applied = _LiveMetadataSnapshot(
      artist: nowPlayingArtist,
      title: nowPlayingTitle,
      artworkUrl: currentArtworkUrl,
    );
    if (!applied.sameTrack(current)) {
      if (current.hasUsefulTrack) {
        _previousLiveMetadata = current;
      }
      _liveMetadataChangedAt = DateTime.now();
    }
    _currentLiveMetadata = applied;
    return changed;
  }

  WatchBridgeStatus _bridgeStatus() {
    final message =
        playerErrorMessage ??
        apiErrorMessage ??
        (isPlaying
            ? (isLiveStreamMode ? 'Live radio playing' : 'Podcast playing')
            : 'Radio paused');

    return WatchBridgeStatus(
      bridgeRunning: _watchBridgeServer.isRunning,
      isPlaying: isPlaying,
      volume: volume,
      message: message,
      source: playbackSourceLabel,
    );
  }

  Future<WatchBridgeResponse> _handleBridgeCommand(String command) async {
    playerErrorMessage = null;

    try {
      switch (command) {
        case 'play-live':
          await startLivePlayback();
          unawaited(refreshNowPlaying());
          return WatchBridgeResponse(
            ok: true,
            message: 'Live radio started',
            volume: volume,
            isPlaying: true,
          );
        case 'pause':
          await _playbackService.pause();
          return WatchBridgeResponse(
            ok: true,
            message: 'Radio paused',
            volume: volume,
            isPlaying: false,
          );
        case 'resume':
          await _playbackService.play();
          return WatchBridgeResponse(
            ok: true,
            message: 'Playback resumed',
            volume: volume,
            isPlaying: true,
          );
        case 'volume-up':
          final nextVolume = await _playbackService.changeVolumeBy(0.1);
          volume = nextVolume;
          notifyListeners();
          return WatchBridgeResponse(
            ok: true,
            message: 'Volume ${(nextVolume * 100).round()}%',
            volume: nextVolume,
            isPlaying: isPlaying,
          );
        case 'volume-down':
          final nextVolume = await _playbackService.changeVolumeBy(-0.1);
          volume = nextVolume;
          notifyListeners();
          return WatchBridgeResponse(
            ok: true,
            message: 'Volume ${(nextVolume * 100).round()}%',
            volume: nextVolume,
            isPlaying: isPlaying,
          );
        default:
          return WatchBridgeResponse(
            ok: false,
            message: 'Unknown command: $command',
            volume: volume,
            isPlaying: isPlaying,
          );
      }
    } catch (_) {
      return WatchBridgeResponse(
        ok: false,
        message: 'Failed to execute command $command',
        volume: volume,
        isPlaying: isPlaying,
      );
    }
  }

  Future<void> refreshSchedule({
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    isScheduleLoading = true;
    scheduleErrorMessage = null;
    notifyListeners();

    final window = _scheduleFetchWindow(
      targetRangeStart: rangeStart,
      targetRangeEnd: rangeEnd,
    );

    try {
      final payload = await _apiService.fetchSchedule(
        start: window.start,
        end: window.end,
      );
      final merged =
          (rangeStart != null && rangeEnd != null && schedule.isNotEmpty)
          ? _mergeSchedule(schedule, payload)
          : payload;
      schedule = merged..sort((a, b) => a.startAt.compareTo(b.startAt));
      isScheduleLoading = false;
      scheduleErrorMessage = null;
      _loadedScheduleStart = _loadedScheduleStart == null
          ? window.start
          : (_loadedScheduleStart!.isBefore(window.start)
                ? _loadedScheduleStart
                : window.start);
      _loadedScheduleEnd = _loadedScheduleEnd == null
          ? window.end
          : (_loadedScheduleEnd!.isAfter(window.end)
                ? _loadedScheduleEnd
                : window.end);
      notifyListeners();
    } catch (_) {
      isScheduleLoading = false;
      scheduleErrorMessage = 'Could not load the schedule.';
      notifyListeners();
    }
  }

  Future<void> ensureScheduleRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final loadedStart = _loadedScheduleStart;
    final loadedEnd = _loadedScheduleEnd;
    if (loadedStart != null &&
        loadedEnd != null &&
        !rangeStart.isBefore(loadedStart) &&
        !rangeEnd.isAfter(loadedEnd)) {
      return;
    }

    await refreshSchedule(rangeStart: rangeStart, rangeEnd: rangeEnd);
  }

  Future<void> refreshPodcasts() async {
    isPodcastsLoading = true;
    podcastsErrorMessage = null;
    notifyListeners();

    try {
      podcasts = await _apiService.fetchPodcasts();
      isPodcastsLoading = false;
      podcastsErrorMessage = null;
      notifyListeners();
    } catch (_) {
      isPodcastsLoading = false;
      podcastsErrorMessage = 'Could not load podcasts.';
      notifyListeners();
    }
  }

  Future<void> refreshPartners() async {
    isPartnersLoading = true;
    partnersErrorMessage = null;
    notifyListeners();

    try {
      partners = await _apiService.fetchPartners();
      isPartnersLoading = false;
      partnersErrorMessage = null;
      notifyListeners();
    } catch (_) {
      isPartnersLoading = false;
      partnersErrorMessage = 'Could not load the partners section.';
      notifyListeners();
    }
  }

  Future<void> openPodcast(String podcastId) async {
    final selected = podcasts.where((item) => item.id == podcastId).firstOrNull;
    if (selected == null) {
      return;
    }

    selectedPodcastId = selected.id;
    selectedPodcastTitle = selected.title;
    podcastEpisodes = const <PodcastEpisode>[];
    episodesErrorMessage = null;
    notifyListeners();

    final cached = _episodesCache[podcastId];
    if (cached != null) {
      podcastEpisodes = cached;
      notifyListeners();
      return;
    }

    isEpisodesLoading = true;
    notifyListeners();

    try {
      final episodes = await _apiService.fetchPodcastEpisodes(podcastId)
        ..sort((a, b) {
          final left = a.publishAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.publishAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
      _episodesCache[podcastId] = episodes;
      if (selectedPodcastId == podcastId) {
        podcastEpisodes = episodes;
        isEpisodesLoading = false;
        episodesErrorMessage = null;
        notifyListeners();
      }
    } catch (_) {
      if (selectedPodcastId == podcastId) {
        isEpisodesLoading = false;
        episodesErrorMessage = 'Could not load episodes for this podcast.';
        notifyListeners();
      }
    }
  }

  void closePodcast() {
    selectedPodcastId = null;
    selectedPodcastTitle = '';
    podcastEpisodes = const <PodcastEpisode>[];
    isEpisodesLoading = false;
    episodesErrorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshPlaybackProgress() async {
    if (isLiveStreamMode) {
      if (podcastPosition != Duration.zero ||
          podcastDuration != Duration.zero) {
        podcastPosition = Duration.zero;
        podcastDuration = Duration.zero;
        notifyListeners();
      }
      return;
    }

    final result = await _playbackService.progress();
    final nextPosition = result.position;
    final nextDuration = result.duration;
    if (nextPosition != podcastPosition || nextDuration != podcastDuration) {
      podcastPosition = nextPosition;
      podcastDuration = nextDuration;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_playbackSubscription?.cancel());
    unawaited(_mediaItemSubscription?.cancel());
    _pollTimer?.cancel();
    _progressTimer?.cancel();
    unawaited(_watchBridgeServer.stop());
    _playbackService.dispose();
    super.dispose();
  }
}

class _ScheduleFetchWindow {
  const _ScheduleFetchWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _LiveMetadataSnapshot {
  const _LiveMetadataSnapshot({
    required this.artist,
    required this.title,
    required this.artworkUrl,
  });

  final String artist;
  final String title;
  final String artworkUrl;

  bool get hasUsefulTrack {
    final normalizedArtist = _normalize(artist);
    final normalizedTitle = _normalize(title);
    return normalizedArtist.isNotEmpty &&
        normalizedTitle.isNotEmpty &&
        normalizedArtist != 'loading artist...' &&
        normalizedTitle != 'loading track...' &&
        normalizedArtist != 'unknown artist' &&
        normalizedTitle != 'live track';
  }

  bool sameTrack(_LiveMetadataSnapshot other) {
    return _normalize(artist) == _normalize(other.artist) &&
        _normalize(title) == _normalize(other.title);
  }

  static String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}

_ScheduleFetchWindow _scheduleFetchWindow({
  DateTime? targetRangeStart,
  DateTime? targetRangeEnd,
}) {
  if (targetRangeStart != null && targetRangeEnd != null) {
    final start = DateTime(
      targetRangeStart.year,
      targetRangeStart.month,
      targetRangeStart.day,
    ).subtract(const Duration(days: 1));
    final end = DateTime(
      targetRangeEnd.year,
      targetRangeEnd.month,
      targetRangeEnd.day,
      23,
      59,
      59,
    ).add(const Duration(days: 1));
    return _ScheduleFetchWindow(start: start, end: end);
  }

  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 1, 1);
  final end = DateTime(now.year, now.month + 3, 0, 23, 59, 59);
  return _ScheduleFetchWindow(start: start, end: end);
}

List<ScheduleItem> _mergeSchedule(
  List<ScheduleItem> existing,
  List<ScheduleItem> incoming,
) {
  final items = <String, ScheduleItem>{
    for (final item in existing) item.key: item,
    for (final item in incoming) item.key: item,
  };
  return items.values.toList();
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
