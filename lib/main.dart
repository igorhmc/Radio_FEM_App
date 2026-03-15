import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/controllers/radio_controller.dart';
import 'src/services/radio_api_service.dart';
import 'src/services/radio_audio_handler.dart';
import 'src/ui/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RadioFemApp());
}

class RadioFemApp extends StatelessWidget {
  const RadioFemApp({super.key});

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
        playbackService: JustAudioRadioPlaybackService(),
      )..initialize(),
      child: MaterialApp(
        title: 'Radio FEM',
        debugShowCheckedModeBanner: false,
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
