import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/app_top_bar.dart';

class UiPreviewScreen extends StatelessWidget {
  const UiPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                stops: [0, 0.8],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Preview UI',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Navega libremente por pantallas sin pasar validaciones del flujo.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _PreviewAction(
                  label: 'Sembrar estado demo',
                  icon: Icons.auto_fix_high,
                  onTap: () {
                    context.read<GameProvider>().seedDemoDataForPreview();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estado demo cargado')),
                    );
                  },
                ),
                _PreviewAction(
                  label: 'Sembrar error recuperable',
                  icon: Icons.wifi_off,
                  onTap: () {
                    context.read<GameProvider>().seedRecoverableErrorPreview();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Estado de error recuperable cargado'),
                      ),
                    );
                  },
                ),
                _PreviewAction(
                  label: 'Sembrar desconexion critica',
                  icon: Icons.portable_wifi_off,
                  onTap: () {
                    context
                        .read<GameProvider>()
                        .seedCriticalDisconnectPreview();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Estado de desconexion critica cargado'),
                      ),
                    );
                  },
                ),
                _PreviewAction(
                  label: 'Simular abandono temporal',
                  icon: Icons.person_off,
                  onTap: () {
                    context.read<GameProvider>().pauseRound(
                      'Luis abandono temporalmente la sala. Ronda en pausa.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Escenario de pausa aplicado'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _PreviewAction(
                  label: 'Home',
                  icon: Icons.home,
                  onTap: () => context.go('/home'),
                ),
                _PreviewAction(
                  label: 'Lobby',
                  icon: Icons.hub,
                  onTap: () => context.go('/lobby'),
                ),
                _PreviewAction(
                  label: 'Ayuda',
                  icon: Icons.menu_book,
                  onTap: () => context.go('/help'),
                ),
                _PreviewAction(
                  label: 'Sala host',
                  icon: Icons.group,
                  onTap: () => context.go('/room-host'),
                ),
                _PreviewAction(
                  label: 'Sala invitado',
                  icon: Icons.people,
                  onTap: () => context.go('/room-guest'),
                ),
                _PreviewAction(
                  label: 'Mesa de juego',
                  icon: Icons.casino,
                  onTap: () => context.go('/game-table'),
                ),
                _PreviewAction(
                  label: 'Seleccion de dados',
                  icon: Icons.touch_app,
                  onTap: () => context.go('/play/select-dice'),
                ),
                _PreviewAction(
                  label: 'Prediccion',
                  icon: Icons.style,
                  onTap: () =>
                      context.go('/play/prediction?combination=Escalera'),
                ),
                _PreviewAction(
                  label: 'Resultados ronda',
                  icon: Icons.table_chart,
                  onTap: () => context.go('/round-results'),
                ),
                _PreviewAction(
                  label: 'Resultados finales',
                  icon: Icons.emoji_events,
                  onTap: () => context.go('/final-results'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PreviewAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }
}
