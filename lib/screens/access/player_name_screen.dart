import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../state/game_provider.dart';

class PlayerNameScreen extends StatefulWidget {
  final String action; // 'create' | 'join'
  const PlayerNameScreen({super.key, required this.action});

  @override
  State<PlayerNameScreen> createState() => _PlayerNameScreenState();
}

class _PlayerNameScreenState extends State<PlayerNameScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _valid = false;
  late final GameProvider _gp;
  bool _listenerAttached = false;

  bool get _isCreate => widget.action == 'create';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _valid = _ctrl.text.trim().length >= 2);
    });

    // Escucha cambios de fase para navegar
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
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onPhaseChange() {
    if (!mounted) return;
    if (_gp.phase == RoomPhase.hostWaiting) {
      context.go('/room-host');
    } else if (_gp.phase == RoomPhase.guestWaiting) {
      context.go('/room-guest');
    }
  }

  void _onContinue() {
    final name = _ctrl.text.trim();
    if (!_valid) return;
    final gp = context.read<GameProvider>();
    if (_isCreate) {
      gp.createRoom(name);
    } else {
      // Guarda el nombre y navega al ingreso de código
      gp.playerName = name;
      context.push('/join-room');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo radial
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [AppColors.primaryContainer, AppColors.surface],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Símbolo casino
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Transform.rotate(
                        angle: 0.785,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Transform.rotate(
                            angle: -0.785,
                            child: const Icon(
                              Icons.casino,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 1,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Identifícate',
                    style: GoogleFonts.newsreader(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ENTRADA AL SALÓN PRIVADO',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Glass panel
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TU ALIAS DE JUEGO',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.outline,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Input underline style
                        TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontStyle: FontStyle.italic,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu nombre...',
                            hintStyle: GoogleFonts.newsreader(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              color: AppColors.outline.withValues(alpha: 0.4),
                            ),
                            filled: false,
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _valid ? _onContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryContainer,
                              disabledBackgroundColor: AppColors
                                  .secondaryContainer
                                  .withValues(alpha: 0.3),
                              foregroundColor: AppColors.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'CONTINUAR',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: _valid
                                    ? AppColors.onSecondaryContainer
                                    : AppColors.onSecondaryContainer.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'El nombre que elijas será visible para otros jugadores en las mesas y rankings globales.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Dados decorativos
                  Opacity(
                    opacity: 0.4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _decorDie(Icons.filter_3, -12),
                        const SizedBox(width: 16),
                        _decorDie(Icons.filter_1, 12),
                        const SizedBox(width: 16),
                        _decorDie(Icons.filter_6, -6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top bar (no interactivo)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 64,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Dado Triple',
                        style: GoogleFonts.newsreader(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
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

  Widget _decorDie(IconData icon, double rotation) {
    return Transform.rotate(
      angle: rotation * (3.14159 / 180),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 28),
      ),
    );
  }
}
