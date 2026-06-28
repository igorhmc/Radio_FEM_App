import 'package:flutter/foundation.dart';
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
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.forroemmilao.radiofem.playback',
    androidNotificationChannelName: 'Radio FEM Playback',
    androidNotificationOngoing: true,
  );
  runApp(const RadioFemApp());
}

class RadioFemApp extends StatelessWidget {
  const RadioFemApp({super.key});

  static const SystemUiOverlayStyle _systemUiOverlayStyle =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF3E7),
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF1010),
      brightness: Brightness.light,
      primary: const Color(0xFFFF1010),
      onPrimary: Colors.white,
      secondary: const Color(0xFFFFD83D),
      onSecondary: const Color(0xFF14100E),
      tertiary: const Color(0xFF006CFF),
      onTertiary: Colors.white,
      surface: const Color(0xFFFFF8EF),
      onSurface: const Color(0xFF14100E),
      error: const Color(0xFFC62828),
    );

    return ChangeNotifierProvider(
      create: (_) => RadioController(
        apiService: RadioApiService(),
        reportsService: AzuraCastReportsService(
          apiKey: AppConfig.analyticsApiKey,
        ),
        playbackService: JustAudioRadioPlaybackService(),
        autoplayOnInitialize:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      )..initialize(),
      child: MaterialApp(
        title: 'Radio FEM',
        debugShowCheckedModeBanner: false,
        locale: const Locale('en', 'US'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFFFFF3E7),
          cardTheme: CardThemeData(
            color: const Color(0xFFFFF8EF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF14100E)),
            ),
          ),
          textTheme: Typography.blackMountainView.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFFFFF3E7),
            indicatorColor: const Color(0xFFFFD83D),
            labelTextStyle: WidgetStatePropertyAll(
              Typography.blackMountainView.labelMedium?.copyWith(
                color: const Color(0xFF14100E),
                fontWeight: FontWeight.w800,
              ),
            ),
            iconTheme: const WidgetStatePropertyAll(
              IconThemeData(color: Color(0xFF14100E)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF1010),
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 46),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF14100E),
              side: const BorderSide(color: Color(0xFF14100E)),
              minimumSize: const Size(48, 46),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF14100E),
              backgroundColor: const Color(0xFFFFD83D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF14100E)),
              ),
            ),
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFFFF1010),
            inactiveTrackColor: Color(0xFFFFD83D),
            thumbColor: Color(0xFF14100E),
            overlayColor: Color(0x26FF1010),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFFFF1010),
          ),
        ),
        home: const AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiOverlayStyle,
          child: HomeShell(),
        ),
      ),
    );
  }
}
