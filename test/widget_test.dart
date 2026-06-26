// Basic smoke test for the Pace app.
//
// This just verifies that PaceApp boots and renders its main navigation
// without throwing. The individual screens (Home, Leaderboard, Search,
// Profile, Settings) make real network calls to speedrun.com on init,
// so this test intentionally avoids tester.pumpAndSettle() — that would
// wait indefinitely on those in-flight requests. For deeper screen-level
// tests, mock SpeedrunApiService instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pace/main.dart';
import 'package:pace/providers/settings_provider.dart';

void main() {
  testWidgets('PaceApp builds and shows the main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const PaceApp(),
      ),
    );

    // One frame is enough to confirm it built without crashing.
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}