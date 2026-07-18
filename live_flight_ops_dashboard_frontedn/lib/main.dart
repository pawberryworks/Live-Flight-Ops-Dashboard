import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            'assets/icons/logo-white.svg',
            height: 80,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        toolbarHeight: 112,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            debugPrint(
              'Current primary color: '
              '${Theme.of(context).colorScheme.primary}',
            );
            onToggleTheme();
          },
          child: const Text('Toggle Theme'),
        ),
      ),
    );
  }
}

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Align(
//             alignment: Alignment.centerLeft,
//             child: SvgPicture.asset(
//               'icons/logo-white.svg',
//               height: 80,
//               colorFilter: ColorFilter.mode(
//                 AppColorSchemes.light.onPrimary,
//                 BlendMode.srcIn,
//               ),
//             ),
//           ),
//           backgroundColor: AppColorSchemes.light.primary,
//           toolbarHeight: 112,
//         ),
//         body: Center(
//           child: Text('Hello World!'),
//         ),
//       ),
//     );
//   }
// }
