import 'dart:async';

import 'package:just_audio/just_audio.dart';

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

  void dispose();
}

class JustAudioRadioPlaybackService implements RadioPlaybackService {
  JustAudioRadioPlaybackService() {
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
      _currentItem = _currentItem!.copyWith(duration: duration ?? Duration.zero);
      _mediaItemController.add(_currentItem);
    });
    _emitStatus();
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<PlaybackMediaItem?> _mediaItemController =
      StreamController<PlaybackMediaItem?>.broadcast();

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  PlaybackMode _mode = PlaybackMode.live;
  PlaybackMediaItem? _currentItem;
  bool _isDisposed = false;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackMediaItem?> get mediaItemStream => _mediaItemController.stream;

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
    _mediaItemController.add(_currentItem);
    await _player.stop();
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
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
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
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

    _currentItem = _currentItem!.copyWith(
      album: stationName,
      title: title,
      artist: artist,
      description: '',
    );
    _mediaItemController.add(_currentItem);
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
  void dispose() {
    _isDisposed = true;
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
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
      ),
    );
  }
}

enum PlaybackMode { live, podcast }

class PlaybackStatus {
  const PlaybackStatus({
    required this.isPlaying,
    required this.isBuffering,
    required this.isLive,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool isLive;
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
