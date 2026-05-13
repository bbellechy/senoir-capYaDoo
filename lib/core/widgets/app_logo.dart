import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          width: 250.w,
          height: 105.h,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
