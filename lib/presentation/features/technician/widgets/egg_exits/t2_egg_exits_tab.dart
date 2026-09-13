import 'package:flutter/material.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

class T2EggExitsTab extends StatelessWidget {
  final List<Map<String, dynamic>> eggExits;
  final bool isLoading;

  const T2EggExitsTab({
    super.key,
    required this.eggExits,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eggExits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Aucune sortie d’œufs enregistrée.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        const Text('SORTIES D’ŒUFS ENREGISTRÉES', style: AppTypography.labelSmall),
        const SizedBox(height: 10),
        ...eggExits.map((exit) {
          final totalQty = exit['quantity']?.toString() ?? '0';
          final dateStr = exit['date']?.toString().split('T').first ?? '';
          final responsible = exit['responsible']?.toString() ?? 'Responsable inconnu';
          final plusGros = exit['plusGros'] ?? 0;
          final gros = exit['gros'] ?? 0;
          final moyen = exit['moyen'] ?? 0;
          final petit = exit['petit'] ?? 0;
          final status = exit['status']?.toString() ?? 'pending';

          final details = '$plusGros plus gros · $gros gros · $moyen moyens · $petit petits';

          return TaskCard(
            icon: Icons.egg,
            title: '$totalQty œufs',
            meta: '$dateStr · $responsible\n$details',
            status: status == 'validated' ? TaskStatus.done : TaskStatus.todo,
            onTap: () {},
          );
        }),
      ],
    );
  }
}
