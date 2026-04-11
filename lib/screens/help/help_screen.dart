import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/app_colors.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(showBack: true),
      bottomNavigationBar: const AppBottomNavBar(active: NavTab.rankings),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [AppColors.primaryContainer, AppColors.surface],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Ayuda y reglas',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Guia rapida para jugar Dado Triple.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const _RuleTile(
                  title: 'Triple',
                  body:
                      'Tres dados del mismo valor. Maxima prioridad de combinacion.',
                ),
                const _RuleTile(
                  title: 'Escalera',
                  body: 'Tres dados consecutivos (ejemplo: 2-3-4).',
                ),
                const _RuleTile(
                  title: 'Doble',
                  body: 'Dos dados iguales y uno diferente.',
                ),
                const _RuleTile(
                  title: 'Sencillo',
                  body: 'Sin pares ni secuencia.',
                ),
                const SizedBox(height: 12),
                const _RuleTile(
                  title: 'Desempate',
                  body: 'Se compara el valor mas alto y luego el siguiente.',
                ),
                const _RuleTile(
                  title: 'Cartas de prediccion',
                  body:
                      'Zero, Min, More y Max otorgan bonificacion situacional.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String body;

  const _RuleTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.newsreader(
              fontSize: 26,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
