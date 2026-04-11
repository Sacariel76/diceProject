import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/player_model.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/game/dice_widget.dart';

class GameTableScreen extends StatelessWidget {
  const GameTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNavBar(active: NavTab.games),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [AppColors.primaryContainer, AppColors.surface],
                stops: [0, 0.85],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                _PhaseChip(
                  label:
                      'Ronda ${gp.currentRound} de ${gp.totalRounds} - ${_phaseLabel(gp.gameTurnPhase)}',
                ),
                const SizedBox(height: 18),
                Text(
                  'Mesa de juego',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  gp.players.isEmpty
                      ? 'Esperando sincronizacion de jugadores'
                      : 'Turno de ${gp.currentTurnPlayerName}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (gp.isRoundPaused) ...[
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.pause_circle,
                    title: 'Ronda en pausa',
                    message:
                        gp.infoMessage ??
                        'Se detecto una desconexion temporal. Esperando reconexion.',
                  ),
                ],
                const SizedBox(height: 20),
                _DiceZone(
                  title: 'Dados visibles',
                  dice: gp.visibleDice,
                  emptyLabel: 'Aun no se han lanzado dados en esta ronda.',
                ),
                const SizedBox(height: 12),
                _DiceZone(
                  title: 'Tu torre oculta',
                  dice: gp.hiddenDice,
                  emptyLabel: 'Sin dados ocultos sincronizados.',
                ),
                const SizedBox(height: 18),
                _ScorePreview(players: gp.players, totals: gp.totalScores),
                const SizedBox(height: 12),
                if (gp.selectedCombination != null)
                  _InfoCard(
                    icon: Icons.style,
                    title: 'Combinacion enviada',
                    message: gp.selectedCombination!,
                  ),
                if (gp.selectedPrediction != null) ...[
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.lock_clock,
                    title: 'Prediccion secreta',
                    message: gp.selectedPrediction!,
                  ),
                ],
                if (gp.tieDetected && gp.tieMessage != null) ...[
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.balance,
                    title: 'Empate tecnico',
                    message: gp.tieMessage!,
                  ),
                ],
                if (gp.activityFeed.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ActivityFeed(entries: gp.activityFeed),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: gp.canRollDice ? gp.rollDice : null,
                        icon: const Icon(Icons.casino_outlined),
                        label: const Text('Lanzar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: gp.canPresentHand
                            ? () => context.push('/play/select-dice')
                            : null,
                        icon: const Icon(Icons.touch_app),
                        label: const Text('Presentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                if (gp.canOpenPrediction) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/play/prediction?combination=${gp.selectedCombination ?? 'Sencillo'}',
                      ),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Ir a Prediccion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryContainer,
                        foregroundColor: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                if (gp.gameTurnPhase == GameTurnPhase.rolling)
                  _InfoCard(
                    icon: Icons.info_outline,
                    title: 'Siguiente paso',
                    message:
                        'Todos deben lanzar una vez. Cuando termine esta fase, se habilita Prediccion y luego Presentaciones.',
                  ),
                if (gp.gameTurnPhase == GameTurnPhase.predicting)
                  _InfoCard(
                    icon: Icons.style,
                    title: 'Prediccion',
                    message:
                        'Todos eligen carta Zero/Min/More/Max. Luego se pasa a Presentacion 1.',
                  ),
                if (gp.gameTurnPhase == GameTurnPhase.selecting)
                  _InfoCard(
                    icon: Icons.touch_app,
                    title: 'Presentacion',
                    message:
                        'Selecciona 3 dados y confirma combinacion. Se requieren 3 presentaciones por ronda.',
                  ),
                if (gp.gameTurnPhase == GameTurnPhase.rolling ||
                    gp.gameTurnPhase == GameTurnPhase.predicting ||
                    gp.gameTurnPhase == GameTurnPhase.selecting)
                  const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: gp.gameTurnPhase == GameTurnPhase.roundResults
                        ? () => context.go('/round-results')
                        : (gp.gameTurnPhase == GameTurnPhase.finalResults
                              ? () => context.go('/final-results')
                              : null),
                    icon: const Icon(Icons.leaderboard),
                    label: Text(
                      gp.gameTurnPhase == GameTurnPhase.finalResults
                          ? 'Ver resultados finales'
                          : 'Ver resultados de ronda',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.primary,
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

  String _phaseLabel(GameTurnPhase phase) {
    switch (phase) {
      case GameTurnPhase.waiting:
        return 'Esperando';
      case GameTurnPhase.rolling:
        return 'Lanzando';
      case GameTurnPhase.selecting:
        return 'Seleccion';
      case GameTurnPhase.predicting:
        return 'Prediccion';
      case GameTurnPhase.roundResults:
        return 'Resultados ronda';
      case GameTurnPhase.finalResults:
        return 'Resultados finales';
    }
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;

  const _PhaseChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _DiceZone extends StatelessWidget {
  final String title;
  final List<int> dice;
  final String emptyLabel;

  const _DiceZone({
    required this.title,
    required this.dice,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.outline,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (dice.isEmpty)
            Text(
              emptyLabel,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: dice
                  .map((value) => DiceWidget(value: value, size: 56))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ScorePreview extends StatelessWidget {
  final List<PlayerModel> players;
  final Map<String, int> totals;

  const _ScorePreview({required this.players, required this.totals});

  @override
  Widget build(BuildContext context) {
    final hasPlayers = players.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de puntaje',
            style: GoogleFonts.newsreader(
              fontSize: 24,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasPlayers)
            Text(
              'Aun no hay jugadores sincronizados.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.outline,
              ),
            )
          else
            ...players.take(4).map((p) {
              final score = totals[p.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: p.isConnected
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$score pts',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.outline,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.onSurface,
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

class _ActivityFeed extends StatelessWidget {
  final List<String> entries;

  const _ActivityFeed({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.outline,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...entries
              .take(4)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '- $entry',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
