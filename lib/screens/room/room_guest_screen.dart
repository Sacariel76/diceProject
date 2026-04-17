import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/player_model.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class RoomGuestScreen extends StatefulWidget {
  const RoomGuestScreen({super.key});

  @override
  State<RoomGuestScreen> createState() => _RoomGuestScreenState();
}

class _RoomGuestScreenState extends State<RoomGuestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().addListener(_onPhaseChange);
    });
  }

  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_onPhaseChange);
    super.dispose();
  }

  void _onPhaseChange() {
    if (!mounted) return;
    if (context.read<GameProvider>().phase == RoomPhase.playing) {
      context.go('/game-table');
    }
  }

  void _toggleReady() {
    final gp = context.read<GameProvider>();
    final me = gp.players.where((p) => p.id == gp.playerId);
    final alreadyReady = me.isNotEmpty && me.first.isReady;
    if (!alreadyReady) {
      gp.setReady();
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
    final spectators = gp.spectators;
    final me = gp.players.where((p) => p.id == gp.playerId);
    final isReady = me.isNotEmpty && me.first.isReady;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _AppBar(),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Código de sala
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ROOM CODE',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.outline,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                gp.roomCode.isEmpty ? '----' : gp.roomCode,
                                style: GoogleFonts.newsreader(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _copyCode(gp.roomCode),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.content_copy,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título lista
                  Text(
                    'The Table',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de jugadores
                  ...gp.players.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GuestPlayerRow(
                        player: p,
                        isMe: p.id == gp.playerId,
                        myReady: isReady,
                      ),
                    ),
                  ),

                  if (gp.players.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Conectando con la sala...',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Lista de espectadores
                  if (spectators.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Spectators',
                      style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(16),
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
                                child: _GuestSpectatorRow(name: entry.value),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botón Ready
                  GestureDetector(
                    onTap: isReady ? null : _toggleReady,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isReady
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isReady
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isReady
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isReady ? 'LISTO' : 'READY',
                            style: GoogleFonts.newsreader(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Indicador de espera
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for Croupier to start...',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
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

class _GuestPlayerRow extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;
  final bool myReady;

  const _GuestPlayerRow({
    required this.player,
    this.isMe = false,
    this.myReady = false,
  });

  @override
  Widget build(BuildContext context) {
    final showReconnecting = !player.isConnected;
    final effectiveReady = isMe ? myReady : player.isReady;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showReconnecting ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(
              alpha: showReconnecting ? 0.05 : 0.1,
            ),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  child: ColorFiltered(
                    colorFilter: showReconnecting
                        ? const ColorFilter.matrix([
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.color,
                          ),
                    child: Text(
                      player.name.isNotEmpty
                          ? player.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: player.isHost
                            ? AppColors.secondaryContainer
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (player.isHost)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CROUPIER',
                        style: GoogleFonts.manrope(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSecondaryContainer,
                          letterSpacing: 0.5,
                        ),
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
                        isMe ? '${player.name} (Tú)' : player.name,
                        style: GoogleFonts.newsreader(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: showReconnecting
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.manrope(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    showReconnecting
                        ? 'Signal lost'
                        : player.isHost
                            ? 'Hosting'
                            : 'Waiting...',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: showReconnecting
                          ? AppColors.error.withValues(alpha: 0.6)
                          : AppColors.outline,
                      fontStyle: showReconnecting
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (showReconnecting)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'RECONNECTING',
                      style: GoogleFonts.manrope(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryContainer,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (effectiveReady)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ACTIVE',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NOT READY',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuestSpectatorRow extends StatelessWidget {
  final String name;

  const _GuestSpectatorRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
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
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}