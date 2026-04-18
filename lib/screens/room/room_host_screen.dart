import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/player_model.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class RoomHostScreen extends StatefulWidget {
  const RoomHostScreen({super.key});

  @override
  State<RoomHostScreen> createState() => _RoomHostScreenState();
}

class _RoomHostScreenState extends State<RoomHostScreen> {
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
      _gp.addListener(_onPhaseChange);
      _listenerAttached = true;
    });
  }

  @override
  void dispose() {
    if (_listenerAttached) {
      _gp.removeListener(_onPhaseChange);
    }
    super.dispose();
  }

  void _onPhaseChange() {
    if (!mounted) return;
    if (_gp.phase == RoomPhase.playing) {
      context.go('/game-table');
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Código copiado',
          style: GoogleFonts.manrope(fontSize: 13),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final canStart = gp.allPlayersReady && gp.players.length >= 2;
    final spectators = gp.spectators;

    final notReadyPlayer = gp.players.firstWhere(
      (p) => !p.isReady,
      orElse: () => const PlayerModel(id: '', name: ''),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _AppBar(roomCode: gp.roomCode),
      bottomNavigationBar: const AppBottomNavBar(active: NavTab.games),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [AppColors.primaryContainer, AppColors.surface],
                stops: [0.0, 0.8],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Text(
                    'PRIVATE TABLE',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gp.roomCode.isEmpty ? '----' : gp.roomCode,
                        style: GoogleFonts.newsreader(
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CopyButton(onTap: () => _copyCode(gp.roomCode)),
                    ],
                  ),
                  Text(
                    'Comparte este código con tus jugadores',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Lista de jugadores
                  ...gp.players.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PlayerRow(
                        player: p,
                        isMe: p.id == gp.playerId,
                        onKick: null,
                      ),
                    ),
                  ),

                  // Slot vacío si hay menos de 4 jugadores
                  if (gp.players.length < 4)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.15,
                            ),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add_outlined,
                                color: AppColors.outline,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Esperando jugador...',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: AppColors.outline,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Lista de espectadores
                  if (spectators.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ESPECTADORES',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.outline,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      child: Column(
                        children: spectators
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == spectators.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: _SpectatorRow(name: entry.value),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Controles del host
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canStart
                          ? () {
                              gp.startGame();
                              context.go('/game-table');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryContainer,
                        disabledBackgroundColor: AppColors.secondaryContainer
                            .withValues(alpha: 0.4),
                        foregroundColor: AppColors.onSecondaryContainer,
                        disabledForegroundColor: AppColors.onSecondaryContainer
                            .withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        'START GAME',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),

                  if (!canStart && notReadyPlayer.id.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.outline,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Wait for ${notReadyPlayer.name} to get ready',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.outline,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      gp.cancelRoom();
                      context.go('/home');
                    },
                    child: Text(
                      'Cancel Room',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.outline,
                        letterSpacing: 1.5,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.outline.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String roomCode;
  const _AppBar({required this.roomCode});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Dado Triple',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.signal_cellular_alt,
            color: AppColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CopyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.content_copy,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;
  final VoidCallback? onKick;

  const _PlayerRow({required this.player, this.isMe = false, this.onKick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceContainerHighest,
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: GoogleFonts.newsreader(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (player.isHost)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 10,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMe ? 'You' : player.name,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'CROUPIER',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryContainer,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  player.isHost ? 'Table Host' : 'Connected',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          if (player.isReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'READY',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NOT READY',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          if (onKick != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onKick,
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpectatorRow extends StatelessWidget {
  final String name;

  const _SpectatorRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'WATCHING',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}