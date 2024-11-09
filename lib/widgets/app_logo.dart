// lib/widgets/app_logo.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_assets.dart';

enum LogoSize { small, medium, large }

class AppLogo extends StatelessWidget {
  final LogoSize size;
  final bool withText;
  final bool withTagline;
  final double? customWidth;

  const AppLogo({
    Key? key,
    this.size = LogoSize.medium,
    this.withText = true,
    this.withTagline = true,
    this.customWidth,
  }) : super(key: key);

  double get _width {
    if (customWidth != null) return customWidth!;
    return switch (size) {
      LogoSize.small => 32.0,
      LogoSize.medium => 120.0,
      LogoSize.large => 200.0,
    };
  }

  String get _assetPath {
    if (!withText) return AppAssets.logoIcon;
    return withTagline ? AppAssets.logoFull : AppAssets.logoMedium;
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: _width,
      fit: BoxFit.contain,
    );
  }
}