import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart' as bg;

abstract class RadioPlaybackService {
  Stream<PlaybackStatus> get statusStream;

  Stream<PlaybackMediaItem?> get mediaItemStream;

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> stop();

  Future<void> playLive({
    required String url,
    required String stationName,
    required String artist,
    required String title,
  });

  Future<void> playPodcast({
    required String url,
    required String title,
    required String podcastTitle,
    required String description,
  });

  Future<void> updateLiveMetadata({
    required String stationName,
    required String artist,
    required String title,
  });

  Future<void> seekRelative(Duration delta);

  Future<PlaybackProgress> progress();

  double get volume;

  Future<double> setVolume(double value);

  Future<double> changeVolumeBy(double delta);

  void dispose();
}

class JustAudioRadioPlaybackService implements RadioPlaybackService {
  JustAudioRadioPlaybackService() : _artUriFuture = _ensureArtworkUri() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _mode == PlaybackMode.podcast) {
        unawaited(_player.pause());
        unawaited(_player.seek(Duration.zero));
      }
      _emitStatus();
    });
    _durationSubscription = _player.durationStream.listen((duration) {
      if (_isDisposed || _currentItem == null) {
        return;
      }
      _currentItem = _currentItem!.copyWith(
        duration: duration ?? Duration.zero,
      );
      _mediaItemController.add(_currentItem);
    });
    _volumeSubscription = _player.volumeStream.listen((_) {
      _emitStatus();
    });
    _icyMetadataSubscription = _player.icyMetadataStream.listen(
      _handleIcyMetadataChanged,
    );
    _emitStatus();
  }

  final AudioPlayer _player = AudioPlayer(useProxyForRequestHeaders: false);
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<PlaybackMediaItem?> _mediaItemController =
      StreamController<PlaybackMediaItem?>.broadcast();
  final Future<Uri> _artUriFuture;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<IcyMetadata?>? _icyMetadataSubscription;
  PlaybackMode _mode = PlaybackMode.live;
  PlaybackMediaItem? _currentItem;
  int _liveMetadataRevision = 0;
  bool _isDisposed = false;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackMediaItem?> get mediaItemStream => _mediaItemController.stream;

  @override
  double get volume => _player.volume;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> playLive({
    required String url,
    required String stationName,
    required String artist,
    required String title,
  }) async {
    if (url.isEmpty) {
      throw const AudioPlaybackException('Missing live stream URL.');
    }

    _mode = PlaybackMode.live;
    _currentItem = PlaybackMediaItem(
      id: url,
      album: stationName,
      title: title,
      artist: artist,
      description: '',
      duration: Duration.zero,
    );
    _liveMetadataRevision += 1;
    _mediaItemController.add(_currentItem);
    await _player.stop();
    await _player.setAudioSource(await _buildLiveAudioSource(_currentItem!));
    await _player.play();
    _emitStatus();
  }

  @override
  Future<void> playPodcast({
    required String url,
    required String title,
    required String podcastTitle,
    required String description,
  }) async {
    if (url.isEmpty) {
      throw const AudioPlaybackException('Missing podcast URL.');
    }

    _mode = PlaybackMode.podcast;
    _currentItem = PlaybackMediaItem(
      id: url,
      album: podcastTitle,
      title: title,
      artist: podcastTitle,
      description: description,
      duration: Duration.zero,
    );
    _mediaItemController.add(_currentItem);
    await _player.stop();
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        tag: await _buildSystemMediaItem(
          id: url,
          album: podcastTitle,
          title: title,
          artist: podcastTitle,
          description: description,
        ),
      ),
    );
    await _player.play();
    _emitStatus();
  }

  @override
  Future<void> updateLiveMetadata({
    required String stationName,
    required String artist,
    required String title,
  }) async {
    if (_mode != PlaybackMode.live || _currentItem == null) {
      return;
    }

    final nextItem = _currentItem!.copyWith(
      album: stationName,
      title: title,
      artist: artist,
      description: '',
    );
    final currentItem = _currentItem!;
    if (nextItem.album == currentItem.album &&
        nextItem.title == currentItem.title &&
        nextItem.artist == currentItem.artist &&
        nextItem.description == currentItem.description) {
      return;
    }

    _currentItem = nextItem;
    _liveMetadataRevision += 1;
    _mediaItemController.add(_currentItem);
    await _reloadLiveAudioSource();
  }

  @override
  Future<void> seekRelative(Duration delta) async {
    final target = _player.position + delta;
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Future<PlaybackProgress> progress() async {
    return PlaybackProgress(
      position: _player.position,
      duration: _player.duration ?? Duration.zero,
      isLive: _mode == PlaybackMode.live,
    );
  }

  @override
  Future<double> setVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(next);
    _emitStatus();
    return _player.volume;
  }

  @override
  Future<double> changeVolumeBy(double delta) async {
    return setVolume(_player.volume + delta);
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_volumeSubscription?.cancel());
    unawaited(_icyMetadataSubscription?.cancel());
    _statusController.close();
    _mediaItemController.close();
    unawaited(_player.dispose());
  }

  void _emitStatus() {
    if (_isDisposed) {
      return;
    }
    _statusController.add(
      PlaybackStatus(
        isPlaying: _player.playing,
        isBuffering:
            _player.processingState == ProcessingState.loading ||
            _player.processingState == ProcessingState.buffering,
        isLive: _mode == PlaybackMode.live,
        volume: _player.volume,
      ),
    );
  }

  Future<bg.MediaItem> _buildSystemMediaItem({
    required String id,
    required String album,
    required String title,
    required String artist,
    required String description,
  }) async {
    return bg.MediaItem(
      id: id,
      album: album,
      title: title,
      artist: artist,
      displayTitle: title,
      displaySubtitle: artist,
      displayDescription: description,
      artUri: await _artUriFuture,
    );
  }

  Future<AudioSource> _buildLiveAudioSource(PlaybackMediaItem item) async {
    return AudioSource.uri(
      Uri.parse(item.id),
      headers: const <String, String>{'Icy-MetaData': '1'},
      tag: await _buildSystemMediaItem(
        id: _buildLiveMediaItemId(item),
        album: item.album,
        title: item.title.isEmpty ? 'Radio FEM ao vivo' : item.title,
        artist: item.artist.isEmpty ? item.album : item.artist,
        description: 'Transmissao ao vivo',
      ),
    );
  }

  String _buildLiveMediaItemId(PlaybackMediaItem item) {
    return '${item.id}#live-meta=$_liveMetadataRevision';
  }

  Future<void> _reloadLiveAudioSource() async {
    final currentItem = _currentItem;
    if (_isDisposed ||
        currentItem == null ||
        _mode != PlaybackMode.live ||
        currentItem.id.isEmpty) {
      return;
    }

    final wasPlaying = _player.playing;
    try {
      await _player.setAudioSource(await _buildLiveAudioSource(currentItem));
      if (wasPlaying) {
        await _player.play();
      }
    } catch (_) {
      // Ignore platform refresh failures so playback/UI updates keep working.
    }
  }

  void _handleIcyMetadataChanged(IcyMetadata? metadata) {
    if (_isDisposed || _mode != PlaybackMode.live || _currentItem == null) {
      return;
    }

    final parsed = _parseIcyStreamTitle(metadata?.info?.title);
    if (parsed == null) {
      return;
    }

    unawaited(
      updateLiveMetadata(
        stationName: _currentItem!.album,
        artist: parsed.artist,
        title: parsed.title,
      ),
    );
  }

  _ParsedLiveMetadata? _parseIcyStreamTitle(String? rawTitle) {
    final text = rawTitle?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    final parts = text
        .split(' - ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 1) {
      final title = parts.first;
      return _ParsedLiveMetadata(artist: _currentItem!.artist, title: title);
    }

    return _ParsedLiveMetadata(
      artist: parts.first,
      title: parts.skip(1).join(' - '),
    );
  }

  static Future<Uri> _ensureArtworkUri() async {
    final file = File(
      '${Directory.systemTemp.path}/radio_fem_notification_artwork.png',
    );
    if (!await file.exists()) {
      final asset = await rootBundle.load('assets/images/radio_bg.png');
      await file.writeAsBytes(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        flush: true,
      );
    }
    return file.uri;
  }
}

enum PlaybackMode { live, podcast }

class PlaybackStatus {
  const PlaybackStatus({
    required this.isPlaying,
    required this.isBuffering,
    required this.isLive,
    required this.volume,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool isLive;
  final double volume;
}

class PlaybackMediaItem {
  const PlaybackMediaItem({
    required this.id,
    required this.album,
    required this.title,
    required this.artist,
    required this.description,
    required this.duration,
  });

  final String id;
  final String album;
  final String title;
  final String artist;
  final String description;
  final Duration duration;

  PlaybackMediaItem copyWith({
    String? id,
    String? album,
    String? title,
    String? artist,
    String? description,
    Duration? duration,
  }) {
    return PlaybackMediaItem(
      id: id ?? this.id,
      album: album ?? this.album,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      description: description ?? this.description,
      duration: duration ?? this.duration,
    );
  }
}

class PlaybackProgress {
  const PlaybackProgress({
    required this.position,
    required this.duration,
    required this.isLive,
  });

  final Duration position;
  final Duration duration;
  final bool isLive;
}

class AudioPlaybackException implements Exception {
  const AudioPlaybackException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ParsedLiveMetadata {
  const _ParsedLiveMetadata({required this.artist, required this.title});

  final String artist;
  final String title;
}
