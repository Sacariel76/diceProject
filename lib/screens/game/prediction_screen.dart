import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/app_top_bar.dart';

class PredictionScreen extends StatefulWidget {
  final String combination;

  const PredictionScreen({super.key, required this.combination});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  late final GameProvider _gp;
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _gp = context.read<GameProvider>();
      _gp.addListener(_handlePhaseNavigation);
      _listenerAttached = true;
      _handlePhaseNavigation();
    });
  }

  void _handlePhaseNavigation() {
    if (!mounted) {
      return;
    }

    final gp = _gp;

    if (gp.shouldUseSpectatorViews &&
        gp.gameTurnPhase == GameTurnPhase.predicting) {
      context.go('/game-table');
      return;
    }

    if (gp.gameTurnPhase == GameTurnPhase.finalResults) {
      context.go('/final-results');
      return;
    }

    if (gp.gameTurnPhase == GameTurnPhase.roundResults) {
      context.go('/round-results');
      return;
    }

    if (gp.gameTurnPhase == GameTurnPhase.selecting) {
      context.go(
        gp.shouldUseSpectatorViews ? '/spectator/presentations' : '/game-table',
      );
      return;
    }

    if (gp.gameTurnPhase == GameTurnPhase.rolling ||
        gp.gameTurnPhase == GameTurnPhase.waiting) {
      context.go('/game-table');
      return;
    }
  }

  @override
  void dispose() {
    if (_listenerAttached) {
      _gp.removeListener(_handlePhaseNavigation);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final selected = gp.selectedPrediction;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(showBack: true),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.1,
                colors: [AppColors.primaryContainer, AppColors.surface],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Prediccion secreta',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona tu carta secreta para esta ronda.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (gp.predictionSubmitted)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Prediccion enviada. Esperando a que el servidor habilite la presentacion.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _cards
                        .map(
                          (card) => _PredictionCard(
                            label: card,
                            selected: selected == card,
                            onTap: () => context
                                .read<GameProvider>()
                                .setPredictionDraft(card),
                          ),
                        )
                        .toList(),
                  ),
                if (!gp.predictionSubmitted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: selected == null
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmar prediccion'),
                                  content: Text(
                                    'Tu carta quedara privada hasta cierre de ronda.\n\nCarta: $selected',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Confirmar'),
                                    ),
                                  ],
                                ),
                              );

                              if (!context.mounted || confirmed != true) {
                                return;
                              }

                              context.read<GameProvider>().submitPrediction(
                                selected,
                              );
                            },
                      icon: const Icon(Icons.lock),
                      label: const Text('Confirmar prediccion privada'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: gp.gameTurnPhase == GameTurnPhase.selecting
                        ? () => context.go('/game-table')
                        : (gp.gameTurnPhase == GameTurnPhase.roundResults
                              ? () => context.go('/round-results')
                              : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      disabledBackgroundColor: AppColors.secondaryContainer
                          .withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      gp.gameTurnPhase == GameTurnPhase.selecting
                          ? 'Volver a mesa'
                          : 'Ver resultados de ronda',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  gp.predictionSubmitted
                      ? 'Prediccion enviada. Cuando la fase cambie a Presentacion, volveras a la mesa.'
                      : 'Tu eleccion se mantiene privada hasta el cierre de ronda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.outline,
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

const _cards = ['ZERO', 'MIN', 'MORE', 'MAX'];

class _PredictionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PredictionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.45)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.newsreader(
                fontSize: 30,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _descriptionFor(label),
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _descriptionFor(String label) {
    switch (label) {
      case 'ZERO':
        return 'Espera cero aciertos de prediccion.';
      case 'MIN':
        return 'Apuesta por resultado minimo controlado.';
      case 'MORE':
        return 'Busca superar el promedio de mesa.';
      case 'MAX':
        return 'Objetivo de maximo impacto en ronda.';
      default:
        return '';
    }
  }
}