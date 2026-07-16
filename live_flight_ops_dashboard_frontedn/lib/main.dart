
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/app_colors.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              'icons/logo-white.svg',
              height: 122,
              colorFilter: ColorFilter.mode(
                AppColors.light.surface,
                BlendMode.srcIn,
              ),
            ),
          ),
          backgroundColor: AppColors.light.brandPrimary,
          toolbarHeight: 160,
        ),
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
