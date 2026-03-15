class AudienceSummary30d {
  const AudienceSummary30d({
    required this.listenersUnique30d,
    required this.topCountries,
    required this.start,
    required this.end,
  });

  final int listenersUnique30d;
  final List<TopCountryAudience> topCountries;
  final DateTime start;
  final DateTime end;
}

class TopCountryAudience {
  const TopCountryAudience({
    required this.countryCode,
    required this.countryName,
    required this.listeners,
    required this.connectedSeconds,
  });

  final String countryCode;
  final String countryName;
  final int listeners;
  final double connectedSeconds;

  factory TopCountryAudience.fromJson(Map<String, dynamic> json) {
    return TopCountryAudience(
      countryCode: _normalizeCountryCode(_asString(json['country_code'])),
      countryName: _fallback(_asString(json['country']), 'Unknown country'),
      listeners: _asInt(json['listeners']),
      connectedSeconds: _asDouble(json['connected_seconds']),
    );
  }
}

class ListeningTimeValue {
  const ListeningTimeValue({required this.label, required this.value});

  final String label;
  final int value;

  factory ListeningTimeValue.fromJson(Map<String, dynamic> json) {
    return ListeningTimeValue(
      label: _fallback(_asString(json['label']), 'Unknown'),
      value: _asInt(json['value']),
    );
  }
}

String _asString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  final asString = _asString(value);
  if (asString.isEmpty) {
    return 0;
  }
  return int.tryParse(asString) ?? double.tryParse(asString)?.round() ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(_asString(value)) ?? 0;
}

String _fallback(String value, String fallback) {
  return value.isEmpty ? fallback : value;
}

String _normalizeCountryCode(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.length == 2) {
    return normalized;
  }
  return '--';
}
