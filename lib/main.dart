import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/controllers/radio_controller.dart';
import 'src/services/radio_api_service.dart';
import 'src/services/radio_audio_handler.dart';
import 'src/ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: RadioAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.forroemmilao.radiofem.playback',
      androidNotificationChannelName: 'Radio FEM Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      preloadArtwork: false,
    ),
  );

  runApp(RadioFemApp(audioHandler: audioHandler));
}

class RadioFemApp extends StatelessWidget {
  const RadioFemApp({super.key, required this.audioHandler});

  final AudioHandler audioHandler;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD7A814),
      brightness: Brightness.dark,
      primary: const Color(0xFFFFD34D),
      secondary: const Color(0xFF4AA35E),
      tertiary: const Color(0xFFC1553C),
      surface: const Color(0xFF1E1A18),
      background: const Color(0xFF120F0E),
    );

    return ChangeNotifierProvider(
      create: (_) => RadioController(
        apiService: RadioApiService(),
        audioHandler: audioHandler,
      )..initialize(),
      child: MaterialApp(
        title: 'Radio FEM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: scheme.background,
          cardTheme: CardThemeData(
            color: const Color(0xE0191716),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          textTheme: Typography.whiteMountainView.apply(
            bodyColor: scheme.onBackground,
            displayColor: scheme.onBackground,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
