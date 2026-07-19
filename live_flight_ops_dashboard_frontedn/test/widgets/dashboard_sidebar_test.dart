import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/widgets/dashboard_sidebar.dart';

void main() {
  testWidgets('shows the FlightStates timestamp in the user local time', (
    tester,
  ) async {
    const timestamp = 1_735_689_600;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSidebar(
            selectedPage: 0,
            onPageSelected: (_) {},
            onToggleTheme: () {},
            flightStatesTime: timestamp,
          ),
        ),
      ),
    );

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(DashboardSidebar)),
    );
    final localTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
        .toLocal();
    final expectedTimestamp =
        '${localizations.formatMediumDate(localTime)} at '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localTime))}';

    expect(find.text('Data as of'), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-data-timestamp')), findsOneWidget);
    expect(find.text(expectedTimestamp), findsOneWidget);
  });
}
