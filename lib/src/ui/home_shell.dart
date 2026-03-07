import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../controllers/radio_controller.dart';
import '../models/radio_models.dart';

enum _AppTab { player, schedule, podcasts, contact }

enum _ScheduleMode { weekly, monthly }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  _AppTab _currentTab = _AppTab.player;

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
                icon: Icon(Icons.email_outlined),
                label: 'Contact',
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _currentTab.index,
              children: const <Widget>[
                _PlayerTab(),
                _ScheduleTab(),
                _PodcastsTab(),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(
                    controller.stationName,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Now Playing',
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFD34D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (controller.isLiveStreamMode) ...<Widget>[
                    Text(
                      controller.nowPlayingArtist,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.nowPlayingTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else ...<Widget>[
                    Text(
                      controller.currentPodcastEpisodeTitle.isEmpty
                          ? controller.nowPlayingTitle
                          : controller.currentPodcastEpisodeTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (controller
                        .currentPodcastEpisodeDescription
                        .isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        controller.currentPodcastEpisodeDescription,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Source: ${controller.playbackSourceLabel}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFFD34D),
                    ),
                  ),
                  if (!controller.isLiveStreamMode &&
                      controller.nowPlayingArtist
                          .trim()
                          .isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Podcast: ${controller.nowPlayingArtist}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (controller.isLoading || controller.isBuffering) ...<Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
          ],
          FilledButton.icon(
            onPressed: controller.togglePlayPause,
            icon: Icon(
              controller.isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
            ),
            label: Text(controller.isPlaying ? 'Pause' : 'Listen Now'),
          ),
          if (!controller.isLiveStreamMode) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.returnToLive,
              child: const Text('Back to Live'),
            ),
            const SizedBox(height: 14),
            Slider(
              value: controller.podcastDuration.inMilliseconds == 0
                  ? 0
                  : controller.podcastPosition.inMilliseconds
                        .clamp(0, controller.podcastDuration.inMilliseconds)
                        .toDouble(),
              max: controller.podcastDuration.inMilliseconds <= 0
                  ? 1
                  : controller.podcastDuration.inMilliseconds.toDouble(),
              onChanged: controller.podcastDuration.inMilliseconds <= 0
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
                Text(_formatPlaybackTime(controller.podcastPosition)),
                Text(_formatPlaybackTime(controller.podcastDuration)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () =>
                      controller.skipPodcastBy(const Duration(seconds: -15)),
                  child: const Text('-15s'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      controller.skipPodcastBy(const Duration(seconds: 30)),
                  child: const Text('+30s'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          IconButton(
            onPressed: controller.refreshNowPlaying,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Text(
            'Listeners now: ${controller.listeners}',
            style: textTheme.titleMedium,
          ),
          if (controller.lastUpdated.isNotEmpty)
            Text(
              'Updated at ${controller.lastUpdated}',
              style: textTheme.bodySmall,
            ),
          if (controller.apiErrorMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              controller.apiErrorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (controller.playerErrorMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              controller.playerErrorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
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

    final currentItem = visibleItems.where((item) => item.isNow).firstOrNull;
    final remainingItems = visibleItems
        .where((item) => item.key != currentItem?.key)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        _SectionHeader(
          title: 'Schedule',
          subtitle: 'Station calendar',
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
    return DateFormat('MMMM yyyy').format(range.start);
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
          subtitle: 'Recorded content from Radio FEM',
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
                          child: const Text('View Episodes'),
                        ),
                        OutlinedButton.icon(
                          onPressed: podcast.feedUrl.isEmpty
                              ? null
                              : () => _openUrl(podcast.feedUrl),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('RSS Feed'),
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
            label: const Text('Back to Podcasts'),
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
                          child: const Text('Listen in App'),
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

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: <Widget>[
        const _SectionHeader(
          title: 'Contact',
          subtitle: 'Talk to the Radio FEM team',
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
                const Text(
                  'Radio FEM is an independent and collaborative radio project focused on Forro culture.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'The proposal is to deliver high-quality curation with artistic freedom, no commercial pressure, and strong respect for Brazilian roots and community values.',
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
                  'Email',
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
                  label: const Text('Send Email'),
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
        if (trailing != null) trailing!,
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
