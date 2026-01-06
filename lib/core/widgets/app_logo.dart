import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final bool showText;

  const AppLogo({super.key, this.size, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo-blue-png.png',
          width: 250,
          height: 105,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
