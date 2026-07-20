import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/widgets/settings_view.dart';

void main() {
  testWidgets('rejects intervals below the backend minimum', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsView(
            refreshInterval: const Duration(seconds: 10),
            onRefreshIntervalUpdated: (_) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '4');
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(
      find.text('Enter a whole number of at least 5 seconds.'),
      findsOneWidget,
    );
  });
}
