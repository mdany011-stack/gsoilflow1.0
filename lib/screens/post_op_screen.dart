import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class PostOpScreen extends StatefulWidget {
  const PostOpScreen({super.key});
  @override
  State<PostOpScreen> createState() => _PostOpScreenState();
}

class _PostOpScreenState extends State<PostOpScreen> {
  Map<String, dynamic> _stats = {'nb_ops': 0, 'total_qty': 0.0};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (appState.currentShiftId != null) {
      final s = await DatabaseService().getShiftStats(appState.currentShiftId!);
      if (mounted) setState(() => _stats = s);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(children: [
          // Icône succès
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 46)),
          ),
          const SizedBox(height: 16),
          const Text('Opération enregistrée !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppTheme.success)),
          const SizedBox(height: 28),

          // Détail dernière op
          SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Machine ravitaillée',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(appState.lastOpMachine ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.local_gas_station_rounded,
                    color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text('${appState.lastOpQty?.toStringAsFixed(1) ?? "0"} litres distribués',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppTheme.accent)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Stats shift
          Row(children: [
            StatCard(
              icon: '🔢',
              value: '${_stats['nb_ops']}',
              label: lang.t('operations'),
            ),
            const SizedBox(width: 10),
            StatCard(
              icon: '⛽',
              value: '${(_stats['total_qty'] as num).toStringAsFixed(0)} L',
              label: 'Total shift',
            ),
          ]),

          const Spacer(),

          // Actions
          AppButton(
            label: '⛽  ${lang.t("another_machine")}',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.chooseFamily,
                ModalRoute.withName(AppRoutes.welcome)),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: '🏁  ${lang.t("end_shift_btn")}',
            color: AppTheme.card2,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.endShift,
                ModalRoute.withName(AppRoutes.welcome)),
          ),
        ]),
      ),
    ),
  );
}
