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

class SpectatorPresentationsScreen extends StatefulWidget {
  const SpectatorPresentationsScreen({super.key});

  @override
  State<SpectatorPresentationsScreen> createState() =>
      _SpectatorPresentationsScreenState();
}

class _SpectatorPresentationsScreenState
    extends State<SpectatorPresentationsScreen> {
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

  @override
  void dispose() {
    if (_listenerAttached) {
      _gp.removeListener(_handlePhaseNavigation);
    }
    super.dispose();
  }

  void _handlePhaseNavigation() {
    if (!mounted) {
      return;
    }

    final gp = _gp;

    if (!gp.shouldUseSpectatorViews) {
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

    if (gp.gameTurnPhase != GameTurnPhase.selecting) {
      context.go('/game-table');
      return;
    }
  }

  List<PlayerModel?> _buildSlots(List<PlayerModel> players) {
    final slots = List<PlayerModel?>.filled(
      GameProvider.maxRoomPlayers,
      null,
      growable: false,
    );

    final count =
        players.length < GameProvider.maxRoomPlayers
            ? players.length
            : GameProvider.maxRoomPlayers;

    for (var i = 0; i < count; i += 1) {
      slots[i] = players[i];
    }

    return slots;
  }

  int _normalizeSubmittedCount(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 3) {
      return 3;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final currentStep = gp.currentPresentationStep <= 0
        ? 1
        : (gp.currentPresentationStep > 3 ? 3 : gp.currentPresentationStep);

    final diceByPlayerId = <String, List<int>>{
      for (final row in gp.tableVisibleDice) row.playerId: row.whiteDice,
    };

    final slots = _buildSlots(gp.players);

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
                radius: 1.25,
                colors: [AppColors.primaryContainer, AppColors.surface],
                stops: [0, 0.82],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Presentaciones en vivo',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Modo espectador: observa el avance y los dados visibles de cada jugador en tiempo real.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _OverviewCard(
                  currentStep: currentStep,
                  currentPlayerName: gp.currentTurnPlayerName,
                  hasCurrentTurn: gp.currentTurnPlayerId.isNotEmpty,
                ),
                const SizedBox(height: 14),
                ...slots.asMap().entries.map((entry) {
                  final seatNumber = entry.key + 1;
                  final player = entry.value;

                  if (player == null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EmptySeatCard(seatNumber: seatNumber),
                    );
                  }

                  final presentedCount = _normalizeSubmittedCount(
                    gp.playerPresentationCounts[player.id] ?? 0,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlayerPresentationCard(
                      player: player,
                      dice: diceByPlayerId[player.id] ?? const <int>[],
                      isCurrentTurn: gp.currentTurnPlayerId == player.id,
                      currentStep: currentStep,
                      presentedCount: presentedCount,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int currentStep;
  final String currentPlayerName;
  final bool hasCurrentTurn;

  const _OverviewCard({
    required this.currentStep,
    required this.currentPlayerName,
    required this.hasCurrentTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Presentacion $currentStep de 3',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryContainer,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentStep / 3,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: AppColors.secondaryContainer,
            backgroundColor: AppColors.surfaceContainerHighest,
          ),
          const SizedBox(height: 10),
          Text(
            hasCurrentTurn
                ? 'Turno actual: $currentPlayerName'
                : 'Esperando asignacion de turno...',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerPresentationCard extends StatelessWidget {
  final PlayerModel player;
  final List<int> dice;
  final bool isCurrentTurn;
  final int currentStep;
  final int presentedCount;

  const _PlayerPresentationCard({
    required this.player,
    required this.dice,
    required this.isCurrentTurn,
    required this.currentStep,
    required this.presentedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isReadyForCurrentStep = presentedCount >= currentStep;

    Color statusColor = AppColors.outline;
    String statusLabel = 'Esperando';

    if (isCurrentTurn) {
      statusColor = AppColors.secondaryContainer;
      statusLabel = 'Presentando';
    } else if (isReadyForCurrentStep) {
      statusColor = AppColors.primary;
      statusLabel = 'Listo';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn
              ? AppColors.secondaryContainer.withValues(alpha: 0.45)
              : AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.isHost ? '${player.name} (Host)' : player.name,
                  style: GoogleFonts.newsreader(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: statusColor,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Presentaciones enviadas: $presentedCount/3',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: presentedCount / 3,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHighest,
          ),
          const SizedBox(height: 12),
          Text(
            'Dados visibles en mesa',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.outline,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: dice.isEmpty
                ? Text(
                    'Sin dados visibles por ahora.',
                    key: ValueKey('empty-${player.id}'),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    key: ValueKey('dice-${player.id}-${dice.join('-')}'),
                    spacing: 8,
                    runSpacing: 8,
                    children: dice
                        .map((value) => DiceWidget(value: value, size: 48))
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptySeatCard extends StatelessWidget {
  final int seatNumber;

  const _EmptySeatCard({required this.seatNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.outline, size: 18),
          const SizedBox(width: 10),
          Text(
            'Asiento $seatNumber disponible',
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
