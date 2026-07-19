import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/api_configuration.dart';
import 'features/dashboard/dashboard_controller.dart';
import 'repositories/http_dashboard_repositories.dart';
import 'services/flight_states_service.dart';
import 'services/geographic_bounds_service.dart';
import 'services/refresh_interval_service.dart';
import 'theme/app_colors.dart';
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
          _NavigationMenu(
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

class _NavigationMenu extends StatelessWidget {
  const _NavigationMenu({
    required this.selectedPage,
    required this.onPageSelected,
    required this.onToggleTheme,
  });

  final int selectedPage;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandHeader(colors: colors),
              const SizedBox(height: 32),
              Text(
                'WORKSPACE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _NavigationItem(
                page: 0,
                title: 'Flight map',
                subtitle: 'Live airspace',
                icon: Icons.public_rounded,
                isSelected: selectedPage == 0,
                onTap: onPageSelected,
              ),
              const SizedBox(height: 6),
              _NavigationItem(
                page: 1,
                title: 'Flight list',
                subtitle: 'Aircraft activity',
                icon: Icons.format_list_bulleted_rounded,
                isSelected: selectedPage == 1,
                onTap: onPageSelected,
              ),
              const SizedBox(height: 6),
              _NavigationItem(
                page: 2,
                title: 'Settings',
                subtitle: 'Dashboard controls',
                icon: Icons.tune_rounded,
                isSelected: selectedPage == 2,
                onTap: onPageSelected,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      color: colors.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operations online',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live data connection',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onToggleTheme,
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                label: Text(isDark ? 'Use light theme' : 'Use dark theme'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.outlineVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 46,
        width: 46,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.22),
              blurRadius: 16,
            ),
          ],
        ),
        child: SvgPicture.asset('assets/icons/logo-white.svg'),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIVE FLIGHT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Operations center',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ],
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.page,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.onPrimaryContainer : colors.onSurface;
    return Semantics(
      selected: isSelected,
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(page),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? foreground
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
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
