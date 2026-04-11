import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../state/game_provider.dart';

class RealtimeStatusOverlay extends StatefulWidget {
  final VoidCallback? onExitSession;

  const RealtimeStatusOverlay({super.key, this.onExitSession});

  @override
  State<RealtimeStatusOverlay> createState() => _RealtimeStatusOverlayState();
}

class _RealtimeStatusOverlayState extends State<RealtimeStatusOverlay> {
  String? _lastToast;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider?>();
    if (gp == null) {
      return const SizedBox.shrink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<GameProvider?>();
      final info = provider?.consumeInfoMessage();
      if (info == null || info.isEmpty || info == _lastToast) {
        return;
      }

      _lastToast = info;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(info, style: GoogleFonts.manrope(fontSize: 12)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceContainerHigh,
          duration: const Duration(seconds: 2),
        ),
      );
    });

    return Stack(
      children: [
        if (gp.showConnectionBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        gp.connectionBannerText,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: gp.retryConnection,
                      child: Text(
                        'Reintentar',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.secondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (gp.connectionStatus == ConnectionStatus.disconnected)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: true,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: AppColors.onErrorContainer,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conexion inestable. Usa Reintentar para recuperar sincronizacion.',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (gp.showCriticalDisconnectModal)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desconexion critica',
                      style: GoogleFonts.newsreader(
                        fontSize: 28,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gp.errorMessage ??
                          'La sesion se interrumpio. Puedes reintentar o salir de forma segura.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: gp.retryConnection,
                            child: const Text('Reintentar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                widget.onExitSession ??
                                gp.dismissCriticalDisconnect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorContainer,
                              foregroundColor: AppColors.onErrorContainer,
                            ),
                            child: const Text('Salir'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
