import 'package:flutter/material.dart';

class PremiumOutline extends StatelessWidget {
  final Widget child;
  final double radius;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const PremiumOutline({
    super.key,
    required this.child,
    this.radius = 18,
    this.borderWidth = 2,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5E7A),
            Color(0xFFFFA94D),
            Color(0xFFFFE066),
            Color(0xFF37D67A),
            Color(0xFF3B82F6),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow:
            shadows ??
            const [
              BoxShadow(
                color: Color(0x12FF7A59),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x103B82F6),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: child,
    );
  }
}
