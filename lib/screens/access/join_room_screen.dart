import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../state/game_provider.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  String get _code => _ctrl.text.toUpperCase();
  bool get _complete => _code.length == 6;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().addListener(_onPhaseChange);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_onPhaseChange);
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPhaseChange() {
    if (!mounted) return;
    final gp = context.read<GameProvider>();
    if (gp.phase == RoomPhase.guestWaiting) {
      context.go('/room-guest');
    }
  }

  void _onJoin() {
    if (!_complete) return;
    final gp = context.read<GameProvider>();
    gp.joinRoom(gp.playerName, _code);
  }

  void _onJoinSpectator() {
  if (!_complete) return;
  final gp = context.read<GameProvider>();
  gp.joinAsSpectator(gp.playerName, _code);
}

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final hasError = gp.errorMessage != null;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [AppColors.primaryContainer, AppColors.surface],
              ),
            ),
          ),
          // Foco invisible para capturar input
          Offstage(
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
            ),
          ),
          // Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Panel glass
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Ícono
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.casino,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Código de Invitación',
                              style: GoogleFonts.newsreader(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Introduce los dígitos para unirte a la partida privada.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.outline,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // 6 slots OTP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (i) {
                                final char = i < _code.length ? _code[i] : null;
                                final isActive = i == _code.length;
                                final isError = hasError;

                                return Container(
                                  width: 44,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isError
                                          ? AppColors.error.withValues(
                                              alpha: 0.4,
                                            )
                                          : isActive
                                          ? AppColors.primary
                                          : AppColors.outlineVariant.withValues(
                                              alpha: 0.2,
                                            ),
                                      width: isActive ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: char != null
                                        ? Text(
                                            char,
                                            style: GoogleFonts.newsreader(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          )
                                        : isActive
                                        ? _BlinkingCursor()
                                        : Text(
                                            '0',
                                            style: GoogleFonts.newsreader(
                                              fontSize: 22,
                                              color: AppColors.outline
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                  ),
                                );
                              }),
                            ),
                            // Error
                            if (hasError) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      gp.errorMessage!,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((gp.supportErrorCode ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Codigo soporte: ${gp.supportErrorCode}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      color: AppColors.outline,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ] else
                              const SizedBox(height: 12),
                            const SizedBox(height: 16),
                            // Botón
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _complete ? _onJoinSpectator : null,
                                icon: const Icon(Icons.login, size: 18),
                                label: Text(
                                  'ENTRAR EN MODO ESPECTADOR',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  disabledBackgroundColor: AppColors
                                      .primaryContainer
                                      .withValues(alpha: 0.4),
                                  foregroundColor: _complete
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Botón
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _complete ? _onJoin : null,
                                icon: const Icon(Icons.login, size: 18),
                                label: Text(
                                  'ENTRAR A LA MESA',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  disabledBackgroundColor: AppColors
                                      .primaryContainer
                                      .withValues(alpha: 0.4),
                                  foregroundColor: _complete
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Divider(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/home'),
                              child: Text(
                                '¿No tienes un código? Ver mesas públicas',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Badge(
                          icon: null,
                          dotColor: AppColors.primary,
                          label: 'Servidor Activo',
                        ),
                        const SizedBox(width: 12),
                        _Badge(icon: Icons.lock_outline, label: 'Encriptado'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final Color? dotColor;
  final String label;

  const _Badge({this.icon, this.dotColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor!.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            )
          else
            Icon(icon, color: AppColors.outline, size: 12),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.outline,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
