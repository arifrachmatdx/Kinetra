import 'package:flutter/material.dart';
import 'package:kinetra/core/theme/app_colors.dart';

class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 0 ? '$count' : 'Mulai!';
    return Container(
      color: Colors.black54,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: ShaderMask(
                shaderCallback: (b) => AppColors.gradient.createShader(b),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
