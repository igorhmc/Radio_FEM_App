import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../controllers/radio_controller.dart';
import '../models/radio_models.dart';

enum _AppTab { player, schedule, podcasts, partners, contact }

typedef _ScheduleTabViewState = ({
  List<ScheduleItem> schedule,
  bool isScheduleLoading,
  String? scheduleErrorMessage,
  String nowPlayingArtist,
  String nowPlayingTitle,
});

typedef _PodcastsTabViewState = ({
  bool isPodcastsLoading,
  String? podcastsErrorMessage,
  List<PodcastItem> podcasts,
  String? selectedPodcastId,
  String selectedPodcastTitle,
  bool isEpisodesLoading,
  String? episodesErrorMessage,
  List<PodcastEpisode> podcastEpisodes,
});

typedef _PartnersTabViewState = ({
  bool isPartnersLoading,
  String? partnersErrorMessage,
  List<PartnerItem> partners,
});

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  _AppTab _currentTab = _AppTab.player;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTab.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/radio_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xC814110F),
              Color(0xDF120F0E),
              Color(0xF5100D0C),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: SafeArea(
            top: false,
            child: NavigationBar(
              backgroundColor: const Color(0xD3211B18),
              selectedIndex: _currentTab.index,
              onDestinationSelected: (index) {
                setState(() => _currentTab = _AppTab.values[index]);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.graphic_eq_rounded),
                  label: 'Live',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: 'Schedule',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mic_none_rounded),
                  label: 'Podcasts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.handshake_outlined),
                  label: 'Partners',
                ),
                NavigationDestination(
                  icon: Icon(Icons.email_outlined),
                  label: 'Info',
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentTab = _AppTab.values[index]);
              },
              children: <Widget>[
                const _PlayerTab(),
                _ScheduleTab(isActive: _currentTab == _AppTab.schedule),
                const _PodcastsTab(),
                const _PartnersTab(),
                const _ContactTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerTab extends StatelessWidget {
  const _PlayerTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RadioController>();
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final currentTitle = controller.isLiveStreamMode
            ? controller.nowPlayingTitle
            : (controller.currentPodcastEpisodeTitle.isEmpty
                  ? controller.nowPlayingTitle
                  : controller.currentPodcastEpisodeTitle);
        final currentSubtitle = controller.isLiveStreamMode
            ? controller.nowPlayingArtist
            : controller.nowPlayingArtist.trim().isEmpty
            ? controller.playbackSourceLabel
            : controller.nowPlayingArtist;
        final currentProgram = controller.currentProgram;
        final currentArtworkUrl = controller.isLiveStreamMode
            ? controller.currentArtworkUrl
            : '';
        final heroHeight = currentArtworkUrl.isEmpty
            ? (isWide ? 380.0 : 316.0)
            : (isWide ? 400.0 : 380.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: heroHeight,
                    padding: EdgeInsets.all(isWide ? 28 : 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0x33FFD34D)),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/radio_bg.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x8A140F0C),
                            Color(0xD1120F0E),
                            Color(0xF1110E0D),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 28 : 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      _InfoPill(
                                        label: controller.playbackSourceLabel,
                                        value: controller.isPlaying
                                            ? 'Playing'
                                            : 'Paused',
                                      ),
                                      _InfoPill(
                                        label: controller.audienceWindowLabel,
                                        value: controller.hasAudienceAnalytics
                                            ? '${controller.listenersLast30Days}'
                                            : 'Unavailable',
                                      ),
                                    ],
                                  ),
                                ),
                                if (currentArtworkUrl.isNotEmpty) ...<Widget>[
                                  const SizedBox(width: 12),
                                  _NowPlayingArtwork(
                                    artworkUrl: currentArtworkUrl,
                                    size: isWide ? 112 : 86,
                                  ),
                                ],
                              ],
                            ),
                            const Spacer(),
                            Text(
                              controller.stationName,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentTitle,
                              maxLines: isWide || currentArtworkUrl.isNotEmpty
                                  ? 3
                                  : 4,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (isWide
                                          ? textTheme.displaySmall
                                          : textTheme.headlineMedium)
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 1.02,
                                      ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: const Color(0xFFFFD34D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!controller.isLiveStreamMode &&
                                controller
                                    .currentPodcastEpisodeDescription
                                    .isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              Text(
                                controller.currentPodcastEpisodeDescription,
                                maxLines: isWide ? 3 : 4,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (controller.isLiveStreamMode &&
                              currentProgram != null) ...<Widget>[
                            _CurrentProgramBanner(program: currentProgram),
                            const SizedBox(height: 14),
                          ],
                          if (controller.isLoading ||
                              controller.isBuffering) ...<Widget>[
                            const Center(child: CircularProgressIndicator()),
                            const SizedBox(height: 16),
                          ],
                          if (isWide)
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: controller.togglePlayPause,
                                    icon: Icon(
                                      controller.isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                    ),
                                    label: Text(
                                      controller.isPlaying
                                          ? 'Pause'
                                          : 'Listen now',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await controller.refreshNowPlaying();
                                      await controller
                                          .refreshAudienceSnapshot();
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Refresh status'),
                                  ),
                                ),
                              ],
                            )
                          else ...<Widget>[
                            FilledButton.icon(
                              onPressed: controller.togglePlayPause,
                              icon: Icon(
                                controller.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                              ),
                              label: Text(
                                controller.isPlaying ? 'Pause' : 'Listen now',
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await controller.refreshNowPlaying();
                                await controller.refreshAudienceSnapshot();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh status'),
                            ),
                          ],
                          if (!controller.isLiveStreamMode) ...<Widget>[
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: controller.returnToLive,
                              child: const Text('Back to live'),
                            ),
                            const SizedBox(height: 14),
                            Slider(
                              value:
                                  controller.podcastDuration.inMilliseconds == 0
                                  ? 0
                                  : controller.podcastPosition.inMilliseconds
                                        .clamp(
                                          0,
                                          controller
                                              .podcastDuration
                                              .inMilliseconds,
                                        )
                                        .toDouble(),
                              max:
                                  controller.podcastDuration.inMilliseconds <= 0
                                  ? 1
                                  : controller.podcastDuration.inMilliseconds
                                        .toDouble(),
                              onChanged:
                                  controller.podcastDuration.inMilliseconds <= 0
                                  ? null
                                  : (value) {
                                      controller.seekPodcastTo(
                                        Duration(milliseconds: value.round()),
                                      );
                                    },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  _formatPlaybackTime(
                                    controller.podcastPosition,
                                  ),
                                ),
                                Text(
                                  _formatPlaybackTime(
                                    controller.podcastDuration,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                OutlinedButton(
                                  onPressed: () => controller.skipPodcastBy(
                                    const Duration(seconds: -15),
                                  ),
                                  child: const Text('-15s'),
                                ),
                                OutlinedButton(
                                  onPressed: () => controller.skipPodcastBy(
                                    const Duration(seconds: 30),
                                  ),
                                  child: const Text('+30s'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              _StatTile(
                                label:
                                    'Listeners in the ${controller.audienceWindowLabel.toLowerCase()}',
                                value: controller.hasAudienceAnalytics
                                    ? '${controller.listenersLast30Days}'
                                    : 'Unavailable',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _TopCountriesCard(controller: controller),
                          if (controller.apiErrorMessage != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              controller.apiErrorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          if (controller.playerErrorMessage !=
                              null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              controller.playerErrorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          if (controller.audienceErrorMessage !=
                              null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              controller.audienceErrorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NowPlayingArtwork extends StatelessWidget {
  const _NowPlayingArtwork({required this.artworkUrl, required this.size});

  final String artworkUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetSize = (size * pixelRatio).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.square(
        dimension: size,
        child: Image.network(
          artworkUrl,
          cacheWidth: targetSize,
          cacheHeight: targetSize,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, error, stackTrace) => Container(
            color: const Color(0xAA1F1A17),
            alignment: Alignment.center,
            child: const Icon(Icons.album_rounded),
          ),
        ),
      ),
    );
  }
}

class _CurrentProgramBanner extends StatelessWidget {
  const _CurrentProgramBanner({required this.program});

  final ScheduleItem program;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x332A211B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x45FFD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.radio_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Program on air',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeRange(program),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFFD34D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x401F1A17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x40FFD34D)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: RichText(
          text: TextSpan(
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
            children: <InlineSpan>[
              TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.white70),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x261F1A17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x30FFD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TopCountriesCard extends StatelessWidget {
  const _TopCountriesCard({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x261F1A17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x30FFD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Top countries in the ${controller.audienceWindowLabel.toLowerCase()}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (controller.hasAudienceAnalytics &&
              controller.topCountriesLast30Days.isNotEmpty)
            ...controller.topCountriesLast30Days.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x40FFD34D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.countryCode,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.countryName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.listeners}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFFFD34D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'The app needs station analytics access to show the audience breakdown.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab({required this.isActive});

  final bool isActive;

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  final GlobalKey _nowMarkerKey = GlobalKey();
  final ScrollController _timelineScrollController = ScrollController();
  Timer? _clockTimer;
  Timer? _autoScrollTimer;
  DateTime _now = DateTime.now();
  bool _needsTimelineAutoScroll = true;
  bool _delayNextTimelineAutoScroll = false;
  int? _lastProgramSetSignature;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant _ScheduleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _needsTimelineAutoScroll = true;
      _delayNextTimelineAutoScroll = true;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _autoScrollTimer?.cancel();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RadioController>();
    final viewState = context.select<RadioController, _ScheduleTabViewState>(
      (value) => (
        schedule: value.schedule,
        isScheduleLoading: value.isScheduleLoading,
        scheduleErrorMessage: value.scheduleErrorMessage,
        nowPlayingArtist: value.nowPlayingArtist,
        nowPlayingTitle: value.nowPlayingTitle,
      ),
    );
    final programs =
        viewState.schedule
            .where((item) => item.rawTitlePrefix.startsWith('PROG'))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final pastPrograms = programs
        .where((item) => !item.endAt.isAfter(_now))
        .toList(growable: false);
    final currentPrograms = programs
        .where(
          (item) => !item.startAt.isAfter(_now) && item.endAt.isAfter(_now),
        )
        .toList(growable: false);
    final upcomingPrograms = programs
        .where((item) => item.startAt.isAfter(_now))
        .toList(growable: false);
    final currentItem = currentPrograms.firstOrNull;

    if (programs.isNotEmpty) {
      _queueTimelineAutoScrollIfNeeded(
        targetKey: _nowMarkerKey,
        programSetSignature: _programSetSignature(programs),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SectionHeader(
                title: 'Schedule',
                subtitle: 'Live timeline for curated radio programs',
                trailing: IconButton(
                  onPressed: controller.refreshSchedule,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _CurrentBroadcastCard(
                program: currentItem,
                artist: viewState.nowPlayingArtist,
                title: viewState.nowPlayingTitle,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('scheduleTimelineScrollView'),
            controller: _timelineScrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (viewState.isScheduleLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (viewState.scheduleErrorMessage != null) ...<Widget>[
                  Text(
                    viewState.scheduleErrorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!viewState.isScheduleLoading &&
                    viewState.scheduleErrorMessage == null &&
                    programs.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No curated radio programs were found in the loaded timeline.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                if (programs.isNotEmpty) ...<Widget>[
                  for (final item in pastPrograms)
                    _ProgramTimelineEntry(
                      item: item,
                      status: _TimelineStatus.past,
                    ),
                  _NowTimelineMarker(key: _nowMarkerKey, now: _now),
                  for (final item in currentPrograms)
                    _ProgramTimelineEntry(
                      item: item,
                      status: _TimelineStatus.onAir,
                    ),
                  for (final item in upcomingPrograms)
                    _ProgramTimelineEntry(
                      item: item,
                      status: _TimelineStatus.upcoming,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _programIdentity(ScheduleItem item) {
    return '${item.id}:${item.rawTitle}:${item.startAt.microsecondsSinceEpoch}:'
        '${item.endAt.microsecondsSinceEpoch}';
  }

  int _programSetSignature(List<ScheduleItem> programs) {
    return Object.hashAll(programs.map(_programIdentity));
  }

  void _queueTimelineAutoScrollIfNeeded({
    required GlobalKey targetKey,
    required int programSetSignature,
  }) {
    if (!widget.isActive) {
      return;
    }
    if (!_needsTimelineAutoScroll &&
        _lastProgramSetSignature == programSetSignature) {
      return;
    }

    _needsTimelineAutoScroll = false;
    _lastProgramSetSignature = programSetSignature;

    final delay = _delayNextTimelineAutoScroll
        ? const Duration(milliseconds: 380)
        : const Duration(milliseconds: 80);
    _delayNextTimelineAutoScroll = false;

    _autoScrollTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) {
        return;
      }
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer(delay, () {
        _scrollTimelineTo(targetKey, remainingAttempts: 3);
      });
    });
  }

  void _scrollTimelineTo(
    GlobalKey targetKey, {
    required int remainingAttempts,
  }) {
    if (!mounted || !widget.isActive) {
      return;
    }

    final targetContext = targetKey.currentContext;
    if (!_timelineScrollController.hasClients || targetContext == null) {
      if (remainingAttempts <= 0) {
        _needsTimelineAutoScroll = true;
        return;
      }
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer(const Duration(milliseconds: 120), () {
        _scrollTimelineTo(targetKey, remainingAttempts: remainingAttempts - 1);
      });
      return;
    }

    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.22,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }
}

enum _TimelineStatus { past, onAir, upcoming }

class _CurrentBroadcastCard extends StatelessWidget {
  const _CurrentBroadcastCard({
    required this.program,
    required this.artist,
    required this.title,
  });

  final ScheduleItem? program;
  final String artist;
  final String title;

  @override
  Widget build(BuildContext context) {
    final activeProgram = program;
    return Card(
      color: activeProgram == null
          ? const Color(0xE0191716)
          : const Color(0xFFD04D3D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.radio_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ON THE RADIO NOW',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    activeProgram?.title ?? '24/7 forró pé de serra curation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (activeProgram != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimeRange(activeProgram),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                  if (artist.trim().isNotEmpty &&
                      title.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 9),
                    Text(
                      '$artist — $title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowTimelineMarker extends StatelessWidget {
  const _NowTimelineMarker({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        children: <Widget>[
          const Positioned(
            left: 17,
            top: 0,
            bottom: 0,
            child: ColoredBox(
              color: Color(0xFFFFD34D),
              child: SizedBox(width: 2),
            ),
          ),
          Positioned(
            left: 9,
            top: 20,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD34D),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF120F0E), width: 4),
              ),
            ),
          ),
          Positioned(
            left: 46,
            right: 0,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0x33FFD34D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66FFD34D)),
              ),
              child: Text(
                'NOW • ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFFFD34D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramTimelineEntry extends StatelessWidget {
  const _ProgramTimelineEntry({required this.item, required this.status});

  final ScheduleItem item;
  final _TimelineStatus status;

  @override
  Widget build(BuildContext context) {
    final isPast = status == _TimelineStatus.past;
    final isOnAir = status == _TimelineStatus.onAir;
    final accent = isOnAir
        ? const Color(0xFFD04D3D)
        : isPast
        ? const Color(0xFF77706C)
        : const Color(0xFFFFD34D);

    return Opacity(
      opacity: isPast ? 0.62 : 1,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 17,
            top: 0,
            bottom: 0,
            child: ColoredBox(color: accent, child: const SizedBox(width: 2)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171311),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 3),
                  ),
                  child: Icon(
                    isOnAir
                        ? Icons.graphic_eq_rounded
                        : isPast
                        ? Icons.check_rounded
                        : Icons.schedule_rounded,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: isOnAir
                        ? const Color(0xFFD04D3D)
                        : const Color(0xE0191716),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${_formatDate(item.startAt)} • ${_formatTimeRange(item)}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: isOnAir ? Colors.white : accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastsTab extends StatelessWidget {
  const _PodcastsTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RadioController>();
    final viewState = context.select<RadioController, _PodcastsTabViewState>(
      (value) => (
        isPodcastsLoading: value.isPodcastsLoading,
        podcastsErrorMessage: value.podcastsErrorMessage,
        podcasts: value.podcasts,
        selectedPodcastId: value.selectedPodcastId,
        selectedPodcastTitle: value.selectedPodcastTitle,
        isEpisodesLoading: value.isEpisodesLoading,
        episodesErrorMessage: value.episodesErrorMessage,
        podcastEpisodes: value.podcastEpisodes,
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        _SectionHeader(
          title: 'Podcasts',
          subtitle: 'Recorded shows, specials, and radio culture',
          trailing: IconButton(
            onPressed: controller.refreshPodcasts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 12),
        if (viewState.isPodcastsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (viewState.podcastsErrorMessage != null) ...<Widget>[
          Text(
            viewState.podcastsErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (viewState.selectedPodcastId == null)
          ...viewState.podcasts.expand((podcast) sync* {
            yield Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      podcast.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${podcast.author} • ${podcast.episodesCount} episodes • ${podcast.language}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFFFD34D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(podcast.description),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton(
                          onPressed: () => controller.openPodcast(podcast.id),
                          child: const Text('View episodes'),
                        ),
                        OutlinedButton.icon(
                          onPressed: podcast.feedUrl.isEmpty
                              ? null
                              : () => _openUrl(podcast.feedUrl),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Feed RSS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
            yield const SizedBox(height: 12);
          })
        else ...<Widget>[
          OutlinedButton.icon(
            onPressed: controller.closePodcast,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to podcasts'),
          ),
          const SizedBox(height: 12),
          Text(
            viewState.selectedPodcastTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (viewState.isEpisodesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (viewState.episodesErrorMessage != null) ...<Widget>[
            Text(
              viewState.episodesErrorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...viewState.podcastEpisodes.expand((episode) sync* {
            yield Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      episode.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      episode.publishAt == null
                          ? 'No date'
                          : DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(episode.publishAt!),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFFFD34D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(episode.description),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton(
                          onPressed: episode.playUrl.isEmpty
                              ? null
                              : () => controller.playPodcastEpisode(episode),
                          child: const Text('Listen in app'),
                        ),
                        OutlinedButton.icon(
                          onPressed: episode.playUrl.isEmpty
                              ? null
                              : () => _openUrl(episode.playUrl),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
            yield const SizedBox(height: 12);
          }),
        ],
      ],
    );
  }
}

class _PartnersTab extends StatelessWidget {
  const _PartnersTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RadioController>();
    final viewState = context.select<RadioController, _PartnersTabViewState>(
      (value) => (
        isPartnersLoading: value.isPartnersLoading,
        partnersErrorMessage: value.partnersErrorMessage,
        partners: value.partners,
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        _SectionHeader(
          title: 'Partners',
          subtitle: 'Projects connected to the Forró em Milão community',
          trailing: IconButton(
            onPressed: controller.refreshPartners,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 12),
        if (viewState.isPartnersLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (viewState.partnersErrorMessage != null) ...<Widget>[
          Text(
            viewState.partnersErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...viewState.partners.expand((partner) sync* {
          yield Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (partner.imageUrl.isNotEmpty) ...<Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          partner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            color: const Color(0x261F1A17),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    partner.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    partner.subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFFFD34D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(partner.description),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openUrl(partner.websiteUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open partner website'),
                  ),
                ],
              ),
            ),
          );
          yield const SizedBox(height: 12);
        }),
        if (!viewState.isPartnersLoading &&
            viewState.partnersErrorMessage == null &&
            viewState.partners.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No partners are available right now.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        const _SectionHeader(
          title: 'Info',
          subtitle: 'About Radio FEM and how to contact us',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'About Radio FEM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(AppConfig.aboutShort),
                const SizedBox(height: 8),
                const Text(AppConfig.aboutLong),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openUrl(AppConfig.websiteUrl),
                  icon: const Icon(Icons.radio_rounded),
                  label: const Text('Open full radio page'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _openUrl(AppConfig.forroEmMilaoWebsiteUrl),
                  icon: const Icon(Icons.language_rounded),
                  label: const Text('Open Forró em Milão'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Android app',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan this QR code to open the Android app page on Google Play.',
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: QrImageView(
                      data: AppConfig.androidDownloadUrl,
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF120F0E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF120F0E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _openUrl(AppConfig.androidDownloadUrl),
                  icon: const Icon(Icons.android),
                  label: const Text('Open on Google Play'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Contact email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.contactEmail,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFFD34D),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openUrl('mailto:${AppConfig.contactEmail}'),
                  icon: const Icon(Icons.email_rounded),
                  label: const Text('Send email'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[trailing!],
      ],
    );
  }
}

String _formatDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

String _formatTimeRange(ScheduleItem item) {
  final formatter = DateFormat('HH:mm');
  return '${formatter.format(item.startAt)} - ${formatter.format(item.endAt)}';
}

String _formatPlaybackTime(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<void> _openUrl(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
