import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../state/game_provider.dart';
import '../../widgets/game/dice_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingCtrl;
  late Animation<double> _loadingAnim;

  @override
  void initState() {
    super.initState();
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadingAnim = Tween<double>(
      begin: -1.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _loadingCtrl, curve: Curves.easeInOut));

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final gp = Provider.of<GameProvider?>(context, listen: false);
    if (gp != null) {
      await Future.wait<void>([
        Future<void>.delayed(const Duration(seconds: 2)),
        gp.initializationDone,
      ]);
    } else {
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo felt verde
          Container(
            decoration: const BoxDecoration(color: AppColors.primaryContainer),
            child: CustomPaint(painter: _FeltPainter(), size: Size.infinite),
          ),
          // Brillo central
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Contenido central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Text(
                  'Dado Triple',
                  style: GoogleFonts.newsreader(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurface,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'THE MODERN CROUPIER',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 48),
                // Dados decorativos
                SizedBox(
                  width: 192,
                  height: 192,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -8,
                        top: 8,
                        child: DiceWidget(value: 4, size: 64, rotation: -12),
                      ),
                      Positioned(
                        right: 16,
                        top: 24,
                        child: DiceWidget(value: 1, size: 56, rotation: 45),
                      ),
                      Positioned(
                        left: 40,
                        bottom: 8,
                        child: DiceWidget(value: 5, size: 80, rotation: -25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Loading bar inferior
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: 192,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: AnimatedBuilder(
                        animation: _loadingAnim,
                        builder: (context, _) {
                          return Container(
                            height: 1,
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment(
                                (_loadingAnim.value).clamp(-1.0, 1.0),
                                0,
                              ),
                              widthFactor: 0.33,
                              child: Container(color: AppColors.primary),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'PREPARING THE TABLE',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.outline,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E5231)
      ..style = PaintingStyle.fill;

    const spacing = 4.0;
    const dotRadius = 0.6;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
