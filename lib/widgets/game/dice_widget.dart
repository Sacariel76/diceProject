import 'package:flutter/material.dart';
import '../../app/app_colors.dart';

// Posiciones de puntos en grilla 3x3 para cada valor del dado
const _dotPositions = {
  1: [4],
  2: [0, 8],
  3: [0, 4, 8],
  4: [0, 2, 6, 8],
  5: [0, 2, 4, 6, 8],
  6: [0, 2, 3, 5, 6, 8],
};

class DiceWidget extends StatelessWidget {
  final int value;
  final double size;
  final Color faceColor;
  final Color dotColor;
  final double rotation;
  final String color;
  final bool animateRoll;

  const DiceWidget({
    super.key,
    required this.value,
    this.size = 64,
    this.faceColor = AppColors.surfaceContainerHighest,
    this.dotColor = AppColors.secondaryContainer,
    this.rotation = 0,
    this.color = 'white',
    this.animateRoll = false
  });

Color getDiceColor() {
  switch (color) {
    case 'red':
      return Color(0xFF83000D);
    case 'blue':
      return Color(0xFF164B9E);
    default:
      return faceColor;
  }
}

Color getResolvedDotColor() {
  switch (color) {
    case 'red':
    case 'blue':
      return Colors.white;
    default:
      return dotColor;
  }
}

  @override
  Widget build(BuildContext context) {
    final positions = _dotPositions[value.clamp(1, 6)] ?? [4];
    final dotSize = size * 0.15;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${value}_${color}_$animateRoll'),
      tween: Tween<double>(
        begin: animateRoll ? 2.0 : 0.0,
        end: 0.0,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedTurns, child) {
        return Transform.rotate(
          angle: (rotation + animatedTurns) * (3.14159 / 180),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: getDiceColor(),
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(9, (i) {
              final hasDot = positions.contains(i);
              return Center(
                child: hasDot
                    ? Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: getResolvedDotColor(),
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox(),
              );
            }),
          ),
        ),
      ),
    );
  }
}
