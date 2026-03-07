class NowPlayingInfo {
  const NowPlayingInfo({
    required this.stationName,
    required this.listeners,
    required this.artist,
    required this.title,
  });

  final String stationName;
  final int listeners;
  final String artist;
  final String title;

  factory NowPlayingInfo.fromJson(Map<String, dynamic> json) {
    final station = _asMap(json['station']);
    final listeners = _asMap(json['listeners']);
    final nowPlaying = _asMap(json['now_playing']);
    final song = _asMap(nowPlaying['song']);
    final rawArtist = _asString(song['artist']).trim();
    final rawTitle = _asString(song['title']).trim();
    final rawText = _asString(song['text']).trim();

    String artist = rawArtist;
    String title = rawTitle;

    if ((artist.isEmpty || title.isEmpty) && rawText.contains(' - ')) {
      final parts = rawText.split(' - ');
      if (artist.isEmpty) {
        artist = parts.first.trim();
      }
      if (title.isEmpty) {
        title = parts.skip(1).join(' - ').trim();
      }
    }

    return NowPlayingInfo(
      stationName: _asString(station['name']).trim().isEmpty
          ? 'Radio FEM'
          : _asString(station['name']).trim(),
      listeners: _asInt(listeners['current']),
      artist: artist.isEmpty ? 'Unknown Artist' : artist,
      title: title.isEmpty ? (rawText.isEmpty ? 'Live Track' : rawText) : title,
    );
  }
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.rawTitle,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.isNow,
  });

  final int id;
  final String rawTitle;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final bool isNow;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final normalizedTitle = _normalizeProgramTitle(_asString(json['title']));
    final description = _asString(
      json['description'],
    ).replaceFirst('Playlist:', '').trim();

    return ScheduleItem(
      id: _asInt(json['id']),
      rawTitle: _asString(json['title']).trim(),
      title: normalizedTitle.isEmpty ? 'Program' : normalizedTitle,
      description: description.isEmpty ? 'No description' : description,
      startAt: DateTime.parse(_asString(json['start'])).toLocal(),
      endAt: DateTime.parse(_asString(json['end'])).toLocal(),
      isNow: _asBool(json['is_now']),
    );
  }

  String get rawTitlePrefix => rawTitle.toUpperCase();

  String get key =>
      '$title|${startAt.millisecondsSinceEpoch}|${endAt.millisecondsSinceEpoch}';
}

class PodcastItem {
  const PodcastItem({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.episodesCount,
    required this.language,
    required this.feedUrl,
  });

  final String id;
  final String title;
  final String description;
  final String author;
  final int episodesCount;
  final String language;
  final String feedUrl;

  factory PodcastItem.fromJson(Map<String, dynamic> json) {
    final links = _asMap(json['links']);
    return PodcastItem(
      id: _asString(json['id']),
      title: _fallback(_asString(json['title']).trim(), 'Podcast'),
      description: _fallback(
        _asString(json['description_short']).trim(),
        'No description',
      ),
      author: _fallback(_asString(json['author']).trim(), 'Radio FEM'),
      episodesCount: _asInt(json['episodes']),
      language: _fallback(_asString(json['language_name']).trim(), 'N/A'),
      feedUrl: _asString(links['public_feed']).trim(),
    );
  }
}

class PodcastEpisode {
  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.publishAt,
    required this.playUrl,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? publishAt;
  final String playUrl;

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    final links = _asMap(json['links']);
    final publishSeconds = _asNullableInt(json['publish_at']);
    final createdSeconds = _asNullableInt(json['created_at']);
    final timestamp = publishSeconds ?? createdSeconds;

    return PodcastEpisode(
      id: _asString(json['id']),
      title: _fallback(_asString(json['title']).trim(), 'Episode'),
      description: _fallback(
        _asString(json['description_short']).trim(),
        'No description',
      ),
      publishAt: timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              timestamp * 1000,
              isUtc: true,
            ).toLocal(),
      playUrl: _asString(links['download']).trim().isNotEmpty
          ? _asString(links['download']).trim()
          : _asString(links['public']).trim(),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, data) => MapEntry(key.toString(), data));
  }
  return const <String, dynamic>{};
}

String _asString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String _fallback(String value, String fallback) {
  return value.isEmpty ? fallback : value;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(_asString(value)) ?? 0;
}

int? _asNullableInt(dynamic value) {
  final stringValue = _asString(value);
  if (stringValue.isEmpty) {
    return null;
  }
  return int.tryParse(stringValue);
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  return _asString(value).toLowerCase() == 'true';
}

String _normalizeProgramTitle(String value) {
  final trimmed = value.trim();
  final withoutPrefix = trimmed.replaceFirst(
    RegExp(r'^PROG[_\s]*', caseSensitive: false),
    '',
  );
  if (withoutPrefix.isEmpty) {
    return '';
  }

  return withoutPrefix
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
      })
      .join(' ');
}
