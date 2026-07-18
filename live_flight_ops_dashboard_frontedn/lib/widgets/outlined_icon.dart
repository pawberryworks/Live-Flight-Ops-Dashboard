import 'package:flutter/material.dart';

/// An icon with a soft outline that remains visible over busy backgrounds.
class OutlinedIcon extends StatelessWidget {
  const OutlinedIcon(
    this.iconData, {
    this.color,
    this.outlineColor,
    this.size,
    super.key,
  });

  final IconData iconData;
  final Color? color;
  final Color? outlineColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconData,
      size: size,
      color: color,
      shadows: List.generate(
        10,
        (_) => Shadow(
          blurRadius: 2,
          color: outlineColor ?? Theme.of(context).canvasColor,
        ),
      ),
    );
  }
}
