import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/app_colors.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNavBar(active: NavTab.home),
      body: Stack(
        children: [
          // Fondo radial verde → negro
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
          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Hero
                  Text(
                    'Bienvenido al Salón',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.newsreader(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onPrimaryContainer,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TOMA TU ASIENTO EN LA MESA DE HONOR',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.outline,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Card Crear Sala
                  _ActionCard(
                    title: 'Crear Sala',
                    description:
                        'Inicia un nuevo juego y conviértete en el Croupier de la noche.',
                    cta: 'CONFIGURAR MESA',
                    icon: Icons.workspace_premium,
                    bgDecorIcon: Icons.casino,
                    bgColor: AppColors.surfaceContainerLow,
                    titleColor: AppColors.primary,
                    ctaColor: AppColors.secondaryContainer,
                    onTap: () => context.push('/player-name?action=create'),
                  ),
                  const SizedBox(height: 16),
                  // Card Unirse a Sala
                  _ActionCard(
                    title: 'Unirse a Sala',
                    description:
                        'Ingresa un código de acceso y entra en una partida activa.',
                    cta: 'ENTRAR AHORA',
                    icon: Icons.group,
                    bgDecorIcon: Icons.key,
                    bgColor: AppColors.surfaceContainerHighest,
                    titleColor: AppColors.onSurface,
                    ctaColor: AppColors.primary,
                    onTap: () => context.push('/player-name?action=join'),
                  ),
                  const SizedBox(height: 40),
                  _ActionCard(
                    title: 'Lobby',
                    description:
                        'Explora mesas disponibles, tu perfil y acceso rapido a partidas.',
                    cta: 'VER LOBBY',
                    icon: Icons.hub,
                    bgDecorIcon: Icons.grid_view,
                    bgColor: AppColors.surfaceContainer,
                    titleColor: AppColors.onSurface,
                    ctaColor: AppColors.primary,
                    onTap: () => context.push('/lobby'),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    title: 'Ayuda y reglas',
                    description:
                        'Consulta combinaciones, desempates y cartas de prediccion.',
                    cta: 'ABRIR MANUAL',
                    icon: Icons.menu_book,
                    bgDecorIcon: Icons.help_outline,
                    bgColor: AppColors.surfaceContainerLow,
                    titleColor: AppColors.onSurface,
                    ctaColor: AppColors.secondaryContainer,
                    onTap: () => context.push('/help'),
                  ),
                  const SizedBox(height: 40),
                  // Separador
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'AMBIENTE PRIVADO',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.outlineVariant,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"Donde la estrategia se encuentra con la fortuna bajo el verde de la mesa."',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.newsreader(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final String cta;
  final IconData icon;
  final IconData bgDecorIcon;
  final Color bgColor;
  final Color titleColor;
  final Color ctaColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.cta,
    required this.icon,
    required this.bgDecorIcon,
    required this.bgColor,
    required this.titleColor,
    required this.ctaColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Stack(
            children: [
              // Ícono decorativo de fondo
              Positioned(
                top: -8,
                right: -8,
                child: Icon(
                  bgDecorIcon,
                  size: 80,
                  color: AppColors.onSurface.withValues(alpha: 0.06),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono principal
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        cta,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ctaColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward, color: ctaColor, size: 14),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
