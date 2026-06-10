import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Map<String, dynamic> _stats = {'nb_ops': 0, 'total_qty': 0.0};
  Map<String, dynamic>? _shift;
  List<Map<String, dynamic>> _lastOps = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DatabaseService();
    if (appState.currentShiftId != null) {
      _shift   = await db.getShift(appState.currentShiftId!);
      _stats   = await db.getShiftStats(appState.currentShiftId!);
      final ops = await db.getShiftOperations(appState.currentShiftId!);
      _lastOps = ops.reversed.take(5).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasShift = appState.currentShiftId != null;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${lang.t("welcome")},', style: const TextStyle(
                      fontSize: 14, color: AppTheme.textMuted)),
                  Text(appState.currentUser ?? '—', style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                ])),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings).then((_) => _load()),
                  icon: const Icon(Icons.settings_outlined, color: AppTheme.textMuted)),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted, size: 20)),
              ]),
              const SizedBox(height: 20),

              // Carte stats shift
              SectionCard(child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: hasShift ? AppTheme.success : AppTheme.textMuted,
                            shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(hasShift ? lang.t('shift_running') : lang.t('no_shift'),
                            style: TextStyle(fontSize: 12,
                                color: hasShift ? AppTheme.success : AppTheme.textMuted)),
                      ]),
                      if (hasShift) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          StatCard(icon: '⛽', value: '${(_stats['total_qty'] as num).toStringAsFixed(0)} L',
                              label: lang.t('total_volume')),
                          const SizedBox(width: 10),
                          StatCard(icon: '🔢', value: '${_stats['nb_ops']}',
                              label: lang.t('operations')),
                          const SizedBox(width: 10),
                          StatCard(icon: '🕐',
                              value: _shift?['start_time'] != null
                                  ? (_shift!['start_time'] as String).substring(11, 16)
                                  : '—',
                              label: 'Début'),
                        ]),
                      ],
                    ]),
              ),
              const SizedBox(height: 16),

              // Actions
              if (!hasShift)
                AppButton(label: '🚀  ${lang.t("start_shift")}', onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.startShift).then((_) => _load()))
              else ...[
                AppButton(label: '⛽  Ravitailler une machine', onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.chooseFamily)),
                const SizedBox(height: 10),
                AppButton(label: '🏁  ${lang.t("end_shift")}',
                    color: AppTheme.danger, onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.endShift).then((_) => _load())),
              ],
              const SizedBox(height: 20),

              // Dernières opérations
              if (hasShift && _lastOps.isNotEmpty) ...[
                Text('Dernières opérations',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted)),
                const SizedBox(height: 10),
                ..._lastOps.map((op) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.card2, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Text('🔧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                        (op['machine_name'] as String? ?? '—'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis)),
                    Text('${(op['quantity'] as num).toStringAsFixed(0)} L',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppTheme.accent)),
                  ]),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await DatabaseService().logoutUser(appState.currentUser ?? '');
    appState.reset();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}
