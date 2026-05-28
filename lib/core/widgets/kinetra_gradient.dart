import 'package:flutter/material.dart';
import 'package:kinetra/core/theme/app_colors.dart';

class KinetraGradient extends StatelessWidget {
  const KinetraGradient({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
