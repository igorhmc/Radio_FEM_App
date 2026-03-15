import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../controllers/radio_controller.dart';
import '../models/radio_models.dart';

enum _AppTab { player, schedule, podcasts, partners, contact }

enum _ScheduleMode { weekly, monthly }

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
          bottomNavigationBar: NavigationBar(
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
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentTab = _AppTab.values[index]);
              },
              children: const <Widget>[
                _PlayerTab(),
                _ScheduleTab(),
                _PodcastsTab(),
                _PartnersTab(),
                _ContactTab(),
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
        final heroHeight = isWide ? 380.0 : 316.0;
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
                      border: Border.all(
                        color: const Color(0x33FFD34D),
                      ),
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
                            Wrap(
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
                              maxLines: isWide ? 3 : 4,
                              overflow: TextOverflow.ellipsis,
                              style: (isWide
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
                                controller.currentPodcastEpisodeDescription
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
                          if (controller.isLoading || controller.isBuffering) ...<Widget>[
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
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
                                      await controller.refreshAudienceSnapshot();
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
                                controller.isPlaying
                                    ? 'Pause'
                                    : 'Listen now',
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
                              value: controller.podcastDuration.inMilliseconds == 0
                                  ? 0
                                  : controller.podcastPosition.inMilliseconds
                                        .clamp(
                                          0,
                                          controller
                                              .podcastDuration
                                              .inMilliseconds,
                                        )
                                        .toDouble(),
                              max: controller.podcastDuration.inMilliseconds <= 0
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  _formatPlaybackTime(controller.podcastPosition),
                                ),
                                Text(
                                  _formatPlaybackTime(controller.podcastDuration),
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
                          if (controller.playerErrorMessage != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              controller.playerErrorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          if (controller.audienceErrorMessage != null) ...<Widget>[
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
            ),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
              'The app needs station analytics access to show the 30-day audience breakdown.',
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
  const _ScheduleTab();

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  _ScheduleMode _mode = _ScheduleMode.weekly;
  int _weekOffset = 0;
  int _monthOffset = 0;
  String? _lastRangeKey;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RadioController>();
    final range = _currentRange();
    _ensureRangeLoaded(controller, range);

    final visibleItems =
        controller.schedule
            .where(
              (item) =>
                  !item.endAt.isBefore(range.start) &&
                  !item.startAt.isAfter(range.end),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final currentCandidates = visibleItems.where((item) => item.isNow).toList()
      ..sort((a, b) {
        final priority = (b.isFeaturedProgram ? 1 : 0).compareTo(
          a.isFeaturedProgram ? 1 : 0,
        );
        if (priority != 0) {
          return priority;
        }
        return b.startAt.compareTo(a.startAt);
      });
    final currentItem = currentCandidates.firstOrNull;
    final remainingItems = visibleItems
        .where((item) => item.key != currentItem?.key)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        _SectionHeader(
          title: 'Schedule',
          subtitle: 'Weekly and monthly programming',
          trailing: IconButton(
            onPressed: () => controller.refreshSchedule(
              rangeStart: range.start,
              rangeEnd: range.end,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Weekly'),
              selected: _mode == _ScheduleMode.weekly,
              onSelected: (_) {
                setState(() {
                  _mode = _ScheduleMode.weekly;
                  _weekOffset = 0;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Monthly'),
              selected: _mode == _ScheduleMode.monthly,
              onSelected: (_) {
                setState(() {
                  _mode = _ScheduleMode.monthly;
                  _monthOffset = 0;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                setState(() {
                  if (_mode == _ScheduleMode.weekly) {
                    _weekOffset -= 1;
                  } else {
                    _monthOffset -= 1;
                  }
                });
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                _rangeLabel(range),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  if (_mode == _ScheduleMode.weekly) {
                    _weekOffset += 1;
                  } else {
                    _monthOffset += 1;
                  }
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.isScheduleLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (controller.scheduleErrorMessage != null) ...<Widget>[
          Text(
            controller.scheduleErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!controller.isScheduleLoading &&
            controller.scheduleErrorMessage == null &&
            visibleItems.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _mode == _ScheduleMode.weekly
                    ? 'No programs found for this week.'
                    : 'No programs found for this month.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        if (currentItem != null) ...<Widget>[
          Card(
            color: const Color(0xFFD04D3D),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ON AIR NOW',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentItem.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDate(currentItem.startAt)} • ${_formatTimeRange(currentItem)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final item in remainingItems) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${_formatDate(item.startAt)} • ${_formatTimeRange(item)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFFFD34D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _ensureRangeLoaded(RadioController controller, _Range range) {
    final key =
        '${range.start.millisecondsSinceEpoch}:${range.end.millisecondsSinceEpoch}';
    if (_lastRangeKey == key) {
      return;
    }
    _lastRangeKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureScheduleRange(range.start, range.end);
    });
  }

  _Range _currentRange() {
    if (_mode == _ScheduleMode.weekly) {
      final now = DateTime.now();
      final base = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: _weekOffset * 7));
      final weekday = base.weekday;
      final start = base.subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
      return _Range(start: start, end: end);
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month + _monthOffset, 1);
    final end = DateTime(now.year, now.month + _monthOffset + 1, 0, 23, 59, 59);
    return _Range(start: start, end: end);
  }

  String _rangeLabel(_Range range) {
    if (_mode == _ScheduleMode.weekly) {
      return '${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM').format(range.end)}';
    }
    return DateFormat('MMMM yyyy', 'en_US').format(range.start);
  }
}

class _PodcastsTab extends StatelessWidget {
  const _PodcastsTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RadioController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        _SectionHeader(
          title: 'Podcasts',
          subtitle: 'Recorded shows and station specials',
          trailing: IconButton(
            onPressed: controller.refreshPodcasts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.isPodcastsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (controller.podcastsErrorMessage != null) ...<Widget>[
          Text(
            controller.podcastsErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (controller.selectedPodcastId == null)
          ...controller.podcasts.expand((podcast) sync* {
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
                          label: const Text('RSS feed'),
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
            controller.selectedPodcastTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (controller.isEpisodesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (controller.episodesErrorMessage != null) ...<Widget>[
            Text(
              controller.episodesErrorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...controller.podcastEpisodes.expand((episode) sync* {
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
    final controller = context.watch<RadioController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        _SectionHeader(
          title: 'Partners',
          subtitle: 'Supporting projects synced with the radio website',
          trailing: IconButton(
            onPressed: controller.refreshPartners,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.isPartnersLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (controller.partnersErrorMessage != null) ...<Widget>[
          Text(
            controller.partnersErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...controller.partners.expand((partner) sync* {
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
                            child: const Icon(Icons.image_not_supported_outlined),
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
        if (!controller.isPartnersLoading &&
            controller.partnersErrorMessage == null &&
            controller.partners.isEmpty)
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
                  label: const Text('Open radio website'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _openUrl(AppConfig.forroEmMilaoWebsiteUrl),
                  icon: const Icon(Icons.language_rounded),
                  label: const Text('Open FEM Website'),
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

class _Range {
  const _Range({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
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
