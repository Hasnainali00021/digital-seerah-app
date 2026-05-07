import 'package:flutter/material.dart';

class QuizBackground extends StatelessWidget {
  final Widget child;

  const QuizBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF121212) : const Color(0xFFE0F2F1);

    return Stack(
      children: [
        // Base Color
        Container(
          color: baseColor,
        ),
        // Decorative Circles (Soft Polka Dots)
        Positioned(
          top: -50,
          left: -50,
          child: _buildCircle(150, isDark),
        ),
        Positioned(
          top: 100,
          right: -30,
          child: _buildCircle(100, isDark),
        ),
        Positioned(
          bottom: -50,
          left: 50,
          child: _buildCircle(200, isDark),
        ),
        Positioned(
          top: 300,
          left: -40,
          child: _buildCircle(80, isDark),
        ),
        Positioned(
          bottom: 150,
          right: -40,
          child: _buildCircle(120, isDark),
        ),
        // Content
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildCircle(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.teal.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
    );
  }
}
