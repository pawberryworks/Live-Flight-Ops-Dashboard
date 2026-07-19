import 'package:flutter/material.dart';

import 'core/api_configuration.dart';
import 'features/dashboard/dashboard_controller.dart';
import 'repositories/http_dashboard_repositories.dart';
import 'services/flight_states_service.dart';
import 'services/geographic_bounds_service.dart';
import 'services/refresh_interval_service.dart';
import 'theme/app_colors.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/flight_states_list.dart';
import 'widgets/flight_states_table.dart';
import 'widgets/geographic_bounds_map.dart';
import 'widgets/settings_view.dart';

void main() => runApp(const MainApp());

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() => setState(() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Flight Ops Dashboard',
      theme: ThemeData(colorScheme: AppColors.light),
      darkTheme: ThemeData(colorScheme: AppColors.dark),
      themeMode: _themeMode,
      home: DashboardPage(onToggleTheme: _toggleTheme),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.onToggleTheme, this.controller, super.key});

  final VoidCallback onToggleTheme;
  final DashboardController? controller;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;
  late final bool _ownsController;
  var _selectedPage = 0;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? _createController();
    _controller.load();
  }

  DashboardController _createController() {
    final configuration = ApiConfiguration.fromEnvironment();
    final flightStatesRepository = HttpFlightStatesRepository(
      FlightStatesService(configuration: configuration),
    );
    final geographicBoundsRepository = HttpGeographicBoundsRepository(
      GeographicBoundsService(configuration: configuration),
    );
    final refreshIntervalRepository = HttpRefreshIntervalRepository(
      RefreshIntervalService(configuration: configuration),
    );
    return DashboardController(
      flightStatesRepository: flightStatesRepository,
      geographicBoundsRepository: geographicBoundsRepository,
      refreshIntervalRepository: refreshIntervalRepository,
      resources: [
        flightStatesRepository,
        geographicBoundsRepository,
        refreshIntervalRepository,
      ],
    );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DashboardSidebar(
            selectedPage: _selectedPage,
            onPageSelected: (page) => setState(() => _selectedPage = page),
            onToggleTheme: widget.onToggleTheme,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _DashboardBody(
                controller: _controller,
                selectedPage: _selectedPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller, required this.selectedPage});

  final DashboardController controller;
  final int selectedPage;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (!state.isReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load dashboard data.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final bounds = state.bounds!;
    final flightStates = state.flightStates!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: IndexedStack(
        index: selectedPage,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Semantics(
                  label: 'Map of the configured geographic bounds',
                  child: AircraftMapScope(
                    aircraft: flightStates.states,
                    selectedAircraftIcao24: state.selectedAircraftIcao24,
                    onAircraftSelected: controller.selectAircraft,
                    onAircraftDeselected: controller.clearAircraftSelection,
                    child: GeographicBoundsMap(
                      bounds: bounds,
                      aircraftCount: flightStates.states.length,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: FlightStatesList(
                  states: flightStates.states,
                  selectedAircraftIcao24: state.selectedAircraftIcao24,
                  onAircraftSelected: controller.selectAircraft,
                  onAircraftDeselected: controller.clearAircraftSelection,
                ),
              ),
            ],
          ),
          FlightStatesTable(states: flightStates.states, bounds: bounds),
          SettingsView(
            refreshInterval: state.refreshInterval!,
            onRefreshIntervalUpdated: controller.updateRefreshInterval,
          ),
        ],
      ),
    );
  }
}
