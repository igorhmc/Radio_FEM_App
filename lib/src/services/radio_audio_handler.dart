import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  RadioAudioHandler() {
    _player.playbackEventStream.listen((_) => _broadcastState());
    _player.playerStateStream.listen((state) {
      _broadcastState();
      if (state.processingState == ProcessingState.completed &&
          _mode == PlaybackMode.podcast) {
        unawaited(_player.pause());
        unawaited(_player.seek(Duration.zero));
      }
    });
    _player.durationStream.listen((duration) {
      if (_currentItem == null) {
        return;
      }
      _currentItem = _currentItem!.copyWith(duration: duration);
      mediaItem.add(_currentItem);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  PlaybackMode _mode = PlaybackMode.live;
  MediaItem? _currentItem;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    final payload = extras ?? const <String, dynamic>{};

    switch (name) {
      case 'playLive':
        await _playLive(
          url: payload['url'] as String? ?? '',
          stationName: payload['stationName'] as String? ?? 'Radio FEM',
          artist: payload['artist'] as String? ?? 'Radio FEM',
          title: payload['title'] as String? ?? 'Live Stream',
        );
        return null;
      case 'playPodcast':
        await _playPodcast(
          url: payload['url'] as String? ?? '',
          title: payload['title'] as String? ?? 'Episode',
          podcastTitle: payload['podcastTitle'] as String? ?? 'Podcast',
          description: payload['description'] as String? ?? '',
        );
        return null;
      case 'updateLiveMetadata':
        _updateLiveMetadata(
          stationName: payload['stationName'] as String? ?? 'Radio FEM',
          artist: payload['artist'] as String? ?? 'Radio FEM',
          title: payload['title'] as String? ?? 'Live Stream',
        );
        return null;
      case 'seekRelative':
        final deltaMs = payload['deltaMs'] as int? ?? 0;
        final target = _player.position + Duration(milliseconds: deltaMs);
        await _player.seek(target < Duration.zero ? Duration.zero : target);
        return null;
      case 'progress':
        return <String, dynamic>{
          'positionMs': _player.position.inMilliseconds,
          'durationMs': _player.duration?.inMilliseconds ?? 0,
          'isLive': _mode == PlaybackMode.live,
        };
    }

    return super.customAction(name, payload);
  }

  Future<void> _playLive({
    required String url,
    required String stationName,
    required String artist,
    required String title,
  }) async {
    if (url.isEmpty) {
      throw const AudioPlaybackException('Missing live stream URL.');
    }

    _mode = PlaybackMode.live;
    _currentItem = MediaItem(
      id: url,
      album: stationName,
      title: title,
      artist: artist,
      displayTitle: title,
      displaySubtitle: artist,
      extras: const <String, dynamic>{'mode': 'live'},
    );
    mediaItem.add(_currentItem);
    queue.add([_currentItem!]);

    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await _player.play();
  }

  Future<void> _playPodcast({
    required String url,
    required String title,
    required String podcastTitle,
    required String description,
  }) async {
    if (url.isEmpty) {
      throw const AudioPlaybackException('Missing podcast URL.');
    }

    _mode = PlaybackMode.podcast;
    _currentItem = MediaItem(
      id: url,
      album: podcastTitle,
      title: title,
      artist: podcastTitle,
      displayTitle: title,
      displaySubtitle: podcastTitle,
      displayDescription: description,
      extras: const <String, dynamic>{'mode': 'podcast'},
    );
    mediaItem.add(_currentItem);
    queue.add([_currentItem!]);

    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await _player.play();
  }

  void _updateLiveMetadata({
    required String stationName,
    required String artist,
    required String title,
  }) {
    if (_mode != PlaybackMode.live || _currentItem == null) {
      return;
    }

    _currentItem = _currentItem!.copyWith(
      album: stationName,
      title: title,
      artist: artist,
      displayTitle: title,
      displaySubtitle: artist,
    );
    mediaItem.add(_currentItem);
  }

  void _broadcastState() {
    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const <int>[0],
        processingState: const <ProcessingState, AudioProcessingState>{
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }
}

enum PlaybackMode { live, podcast }

class AudioPlaybackException implements Exception {
  const AudioPlaybackException(this.message);

  final String message;

  @override
  String toString() => message;
}
