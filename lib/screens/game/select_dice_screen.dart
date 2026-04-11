import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../state/game_provider.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../widgets/game/dice_widget.dart';

class SelectDiceScreen extends StatefulWidget {
  const SelectDiceScreen({super.key});

  @override
  State<SelectDiceScreen> createState() => _SelectDiceScreenState();
}

class _SelectDiceScreenState extends State<SelectDiceScreen> {
  final List<int> _selectedIndexes = [];
  String? _error;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final pool = gp.dicePoolForSelection;
    final selectedValues = _selectedIndexes.map((i) => pool[i]).toList();

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
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Seleccion de dados',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige 3 dados para presentar tu combinacion.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.onErrorContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(pool.length, (i) {
                    final selected = _selectedIndexes.contains(i);
                    return GestureDetector(
                      onTap: () => _toggleSelection(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryContainer.withValues(
                                  alpha: 0.5,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                        child: DiceWidget(value: pool[i], size: 62),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Container(
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
                        'Vista previa',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.outline,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedIndexes.length == 3
                            ? _detectCombination(selectedValues)
                            : 'Selecciona 3 dados para detectar combinacion',
                        style: GoogleFonts.newsreader(
                          fontSize: 28,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIndexes.length == 3
                        ? () => _confirmPlay(gp, pool)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      disabledBackgroundColor: AppColors.secondaryContainer
                          .withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Confirmar jugada',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
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

  void _toggleSelection(int index) {
    setState(() {
      _error = null;
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
        return;
      }
      if (_selectedIndexes.length >= 3) {
        _error = 'Solo puedes seleccionar 3 dados.';
        return;
      }
      _selectedIndexes.add(index);
    });
  }

  Future<void> _confirmPlay(GameProvider gp, List<int> pool) async {
    if (_selectedIndexes.length != 3) {
      setState(() => _error = 'Selecciona exactamente 3 dados para continuar.');
      return;
    }

    final selected = _selectedIndexes.map((index) => pool[index]).toList();
    final combination = _detectCombination(selected);

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Confirmar jugada',
          style: GoogleFonts.newsreader(color: AppColors.onSurface),
        ),
        content: Text(
          'Vas a presentar $combination con los dados ${selected.join('-')}.',
          style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: AppColors.onSecondaryContainer,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (!mounted || accepted != true) {
      return;
    }

    gp.submitHand(selected, combination);
    context.push('/play/prediction?combination=$combination');
  }

  String _detectCombination(List<int> values) {
    if (values.length != 3) {
      return 'Incompleta';
    }

    final sorted = [...values]..sort();
    final uniqueCount = sorted.toSet().length;

    if (uniqueCount == 1) {
      return 'Triple';
    }

    final isStraight = sorted[1] == sorted[0] + 1 && sorted[2] == sorted[1] + 1;
    if (isStraight) {
      return 'Escalera';
    }

    if (uniqueCount == 2) {
      return 'Doble';
    }

    return 'Sencillo';
  }
}
