import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/round_score_model.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/app_top_bar.dart';

class RoundResultsScreen extends StatelessWidget {
  const RoundResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final rows = gp.roundScores;
    final hasData = rows.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(showBack: true),
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
                  'Resultados de ronda',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ronda ${gp.currentRound} de ${gp.totalRounds}.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: hasData
                      ? Column(
                          children: rows
                              .map((row) => _ResultRow(score: row))
                              .toList(),
                        )
                      : Text(
                          'Aun no llegaron resultados del servidor. Puedes continuar para el flujo UX.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                if (gp.tieDetected)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      gp.tieMessage ?? 'Empate detectado en la ronda actual.',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                if (gp.tieDetected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Regla de desempate: se compara el valor mas alto; si persiste, segundo y tercer dado en orden descendente.',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      gp.continueAfterRoundResults();
                      if (gp.gameTurnPhase == GameTurnPhase.finalResults) {
                        context.go('/final-results');
                      } else {
                        context.go('/game-table');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      gp.currentRound >= gp.totalRounds
                          ? 'Ver cierre final'
                          : 'Siguiente ronda',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
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

class _ResultRow extends StatelessWidget {
  final RoundScoreModel score;

  const _ResultRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              score.playerName,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              score.combination,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '+${score.totalPoints}',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
