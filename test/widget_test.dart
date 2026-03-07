import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:radio_fem_app/src/controllers/radio_controller.dart';
import 'package:radio_fem_app/src/services/radio_api_service.dart';
import 'package:radio_fem_app/src/ui/home_shell.dart';

void main() {
  testWidgets('shows core navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RadioController(
          apiService: RadioApiService(),
          audioHandler: _FakeAudioHandler(),
        ),
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Podcasts'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
  });
}

class _FakeAudioHandler extends BaseAudioHandler {}
