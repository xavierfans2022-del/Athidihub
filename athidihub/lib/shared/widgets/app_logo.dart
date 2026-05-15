import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final bool compact;
  const AppLogo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 52.0;
    final imageSize = compact ? 26.0 : 34.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            child: Padding(
              padding: EdgeInsets.all(compact ? 6 : 8),
              child: Image.asset(
                'assets/images/Athidihub_logo.png',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Athidihub',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
