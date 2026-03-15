import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class WatchBridgeStatus {
  const WatchBridgeStatus({
    required this.bridgeRunning,
    required this.isPlaying,
    required this.volume,
    required this.message,
    required this.source,
  });

  final bool bridgeRunning;
  final bool isPlaying;
  final double volume;
  final String message;
  final String source;
}

class WatchBridgeResponse {
  const WatchBridgeResponse({
    required this.ok,
    required this.message,
    required this.volume,
    required this.isPlaying,
  });

  final bool ok;
  final String message;
  final double volume;
  final bool isPlaying;
}

class WatchControlBridgeServer {
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _subscription;

  bool get isRunning => _server != null;

  Future<void> start({
    required WatchBridgeStatus Function() statusProvider,
    required Future<WatchBridgeResponse> Function(String command) commandHandler,
  }) async {
    if (_server != null) {
      return;
    }

    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        AppConfig.localBridgePort,
        shared: false,
      );
      _server = server;
      _subscription = server.listen((request) {
        unawaited(_handleRequest(request, statusProvider, commandHandler));
      });
    } catch (error, stackTrace) {
      debugPrint('Watch bridge failed to start: $error\n$stackTrace');
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _server?.close(force: true);
    _subscription = null;
    _server = null;
  }

  Future<void> _handleRequest(
    HttpRequest request,
    WatchBridgeStatus Function() statusProvider,
    Future<WatchBridgeResponse> Function(String command) commandHandler,
  ) async {
    final response = request.response;
    response.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set(HttpHeaders.connectionHeader, 'close');

    try {
      if (request.method != 'GET') {
        await _writeJson(
          response,
          HttpStatus.methodNotAllowed,
          <String, Object?>{
            'ok': false,
            'message': 'Only GET is supported',
          },
        );
        return;
      }

      if (!_isAuthorized(request.uri)) {
        await _writeJson(
          response,
          HttpStatus.unauthorized,
          <String, Object?>{
            'ok': false,
            'message': 'Invalid bridge key',
          },
        );
        return;
      }

      if (request.uri.path == '/status') {
        final status = statusProvider();
        await _writeJson(
          response,
          HttpStatus.ok,
          <String, Object?>{
            'ok': true,
            'bridgeRunning': status.bridgeRunning,
            'isPlaying': status.isPlaying,
            'volume': status.volume,
            'message': status.message,
            'source': status.source,
          },
        );
        return;
      }

      if (request.uri.pathSegments.length == 2 &&
          request.uri.pathSegments.first == 'command') {
        final command = request.uri.pathSegments.last.trim();
        final result = await commandHandler(command);
        await _writeJson(
          response,
          result.ok ? HttpStatus.ok : HttpStatus.badRequest,
          <String, Object?>{
            'ok': result.ok,
            'message': result.message,
            'volume': result.volume,
            'isPlaying': result.isPlaying,
          },
        );
        return;
      }

      await _writeJson(
        response,
        HttpStatus.notFound,
        <String, Object?>{
          'ok': false,
          'message': 'Unknown route',
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Watch bridge request failed: $error\n$stackTrace');
      await _writeJson(
        response,
        HttpStatus.internalServerError,
        <String, Object?>{
          'ok': false,
          'message': 'Internal bridge error',
        },
      );
    }
  }

  bool _isAuthorized(Uri uri) {
    return uri.queryParameters['key'] == AppConfig.localBridgeKey;
  }

  Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, Object?> body,
  ) async {
    response.statusCode = statusCode;
    response.write(jsonEncode(body));
    await response.close();
  }
}
