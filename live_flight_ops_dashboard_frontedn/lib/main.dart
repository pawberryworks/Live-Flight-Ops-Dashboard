import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

import 'models/flight_states.dart';
import 'models/geographic_bounds.dart';
import 'services/flight_states_service.dart';
import 'services/geographic_bounds_service.dart';
import 'theme/app_colors.dart';
import 'widgets/flight_states_list.dart';
import 'widgets/geographic_bounds_map.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Flight Ops Dashboard',
      theme: ThemeData(
        colorScheme: AppColors.light,
      ),
      darkTheme: ThemeData(
        colorScheme: AppColors.dark,
      ),
      themeMode: _themeMode,
      home: DashboardPage(onToggleTheme: _toggleTheme),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GeographicBoundsService _geographicBoundsService =
      GeographicBoundsService();
  final FlightStatesService _flightStatesService = FlightStatesService();
  late Future<_DashboardData> _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    _dashboardData = _fetchDashboardData();
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final results = await Future.wait([
      _geographicBoundsService.getGeographicBounds(),
      _flightStatesService.getFlightStates(),
    ]);
    return _DashboardData(
      bounds: results[0] as GeographicBounds,
      flightStates: results[1] as FlightStates,
    );
  }

  void _retry() {
    setState(_loadDashboardData);
  }

  @override
  void dispose() {
    _geographicBoundsService.close();
    _flightStatesService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
          children: [
            SideMenu(
              mode: SideMenuMode.open,
              backgroundColor: Theme.of(context).colorScheme.primary,
              builder: (data) {
                return SideMenuData(
                  defaultTileData: SideMenuItemTileDefaults(
                    highlightSelectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    titleStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary, 
                    ),
                    selectedTitleStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary, 
                    ),
                    hoverColor: Theme.of(context).colorScheme.surfaceTint,

                  ),
                  animItems: SideMenuItemsAnimationData(),
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
                    child: SvgPicture.asset(
                      'assets/icons/logo-white.svg',
                      height: 80,
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onPrimary,
                        BlendMode.srcIn,
                        ),
                      ),
                  ),
                  items: [
                    SideMenuItemDataTile(isSelected: true, title: 'Map', onTap: () {}, icon: Icon(Icons.map)),
                    SideMenuItemDataTile(isSelected: false, title: 'List', onTap: () {}, icon: Icon(Icons.list)),
                  ],
                  footer: IconButton(
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.light
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 32,
                    ),
                    onPressed: widget.onToggleTheme,
                  )
                );
              },
            ),
            Expanded(
              child: FutureBuilder<_DashboardData>(
                future: _dashboardData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Unable to load dashboard data.'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.requireData;
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Semantics(
                            label: 'Map of the configured geographic bounds',
                            child: AircraftMapScope(
                              aircraft: data.flightStates.states,
                              child: GeographicBoundsMap(
                                bounds: data.bounds,
                                aircraftCount: data.flightStates.states.length,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: FlightStatesList(
                            states: data.flightStates.states,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ]
      )
    );
      // appBar: AppBar(
      //   title: Align(
      //     alignment: Alignment.centerLeft,
      //     child: Padding(
      //       padding: const EdgeInsets.only(left: 16.0),
      //       child: SvgPicture.asset(
      //         'assets/icons/logo-white.svg',
      //         height: 80,
      //         colorFilter: ColorFilter.mode(
      //           Theme.of(context).colorScheme.onPrimary,
      //           BlendMode.srcIn,
      //         ),
      //       ),
      //     )
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: Icon(
      //         Theme.of(context).brightness == Brightness.light
      //             ? Icons.dark_mode
      //             : Icons.light_mode,
      //         color: Theme.of(context).colorScheme.onPrimary,
      //         size: 32,
      //       ),
      //       onPressed: onToggleTheme,
      //     ),
      //   ],
      //   actionsPadding: const EdgeInsets.only(right: 32.0),
      //   backgroundColor: Theme.of(context).colorScheme.primary,
      //   toolbarHeight: 112,
      // ),
      // body: Center(
      //   child: Text(
      //     'Hello World!',
      //     style: TextStyle(
      //       color: Theme.of(context).colorScheme.onSurface,
      //       fontSize: 24,
      //     ),
      //   ),
      // ),
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Align(
  //         alignment: Alignment.centerLeft,
  //         child: Padding(
  //           padding: const EdgeInsets.only(left: 16.0),
  //           child: SvgPicture.asset(
  //             'assets/icons/logo-white.svg',
  //             height: 80,
  //             colorFilter: ColorFilter.mode(
  //               Theme.of(context).colorScheme.onPrimary,
  //               BlendMode.srcIn,
  //             ),
  //           ),
  //         )
  //       ),
  //       actions: [
  //         IconButton(
  //           icon: Icon(
  //             Theme.of(context).brightness == Brightness.light
  //                 ? Icons.dark_mode
  //                 : Icons.light_mode,
  //             color: Theme.of(context).colorScheme.onPrimary,
  //             size: 32,
  //           ),
  //           onPressed: onToggleTheme,
  //         ),
  //       ],
  //       actionsPadding: const EdgeInsets.only(right: 32.0),
  //       backgroundColor: Theme.of(context).colorScheme.primary,
  //       toolbarHeight: 112,
  //     ),
  //     body: Center(
  //       child: Text(
  //         'Hello World!',
  //         style: TextStyle(
  //           color: Theme.of(context).colorScheme.onSurface,
  //           fontSize: 24,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class _DashboardData {
  const _DashboardData({required this.bounds, required this.flightStates});

  final GeographicBounds bounds;
  final FlightStates flightStates;
}
