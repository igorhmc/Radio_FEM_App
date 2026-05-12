import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'src/config/app_config.dart';
import 'src/controllers/radio_controller.dart';
import 'src/services/azuracast_reports_service.dart';
import 'src/services/radio_api_service.dart';
import 'src/services/radio_audio_handler.dart';
import 'src/ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.forroemmilao.radiofem.playback',
    androidNotificationChannelName: 'Radio FEM Playback',
    androidNotificationChannelDescription:
        'Controles de reproducao da Radio FEM',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: false,
    androidBrowsableRootExtras: const <String, dynamic>{
      AndroidContentStyle.supportedKey: true,
      AndroidContentStyle.playableHintKey:
          AndroidContentStyle.listItemHintValue,
      AndroidContentStyle.browsableHintKey:
          AndroidContentStyle.listItemHintValue,
    },
  );
  runApp(RadioFemApp(playbackService: JustAudioRadioPlaybackService()));
}

class RadioFemApp extends StatelessWidget {
  const RadioFemApp({required this.playbackService, super.key});

  final RadioPlaybackService playbackService;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD7A814),
      brightness: Brightness.dark,
      primary: const Color(0xFFFFD34D),
      secondary: const Color(0xFF4AA35E),
      tertiary: const Color(0xFFC1553C),
      surface: const Color(0xFF1E1A18),
    );

    return ChangeNotifierProvider(
      create: (_) => RadioController(
        apiService: RadioApiService(),
        reportsService: AzuraCastReportsService(
          apiKey: AppConfig.analyticsApiKey,
        ),
        playbackService: playbackService,
      )..initialize(),
      child: MaterialApp(
        title: 'Radio FEM',
        debugShowCheckedModeBanner: false,
        locale: const Locale('en', 'US'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFF120F0E),
          cardTheme: CardThemeData(
            color: const Color(0xE0191716),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          textTheme: Typography.whiteMountainView.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
