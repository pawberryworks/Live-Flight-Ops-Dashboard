import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

import 'theme/app_colors.dart';

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

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

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
                    onPressed: onToggleTheme,
                  )
                );
              },
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