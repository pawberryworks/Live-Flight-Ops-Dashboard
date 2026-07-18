
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:simple_theme_switcher/simple_theme_switcher.dart';

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
      home: Scaffold(
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
            // Use ThemeManager to toggle theme
            final themeManager = ThemeManager();
            debugPrint('Current Theme Mode: ${themeManager.currentThemeMode} Current primary color: ${Theme.of(context).colorScheme.primary}');
            themeManager.toggleTheme(
              themeManager.currentThemeMode == AppThemeMode.light
                  ? AppThemeMode.dark
                  : AppThemeMode.light,
              seedColor: Colors.blue, // Optional seed color
            );
          },
          child: const Text('Toggle Theme'),
        ),
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
