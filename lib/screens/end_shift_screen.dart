import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/camera_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class EndShiftScreen extends StatefulWidget {
  const EndShiftScreen({super.key});
  @override
  State<EndShiftScreen> createState() => _EndShiftScreenState();
}

class _EndShiftScreenState extends State<EndShiftScreen> {
  final _ctrCtrl = TextEditingController();
  String? _photoPath;
  bool _loading = false;
  Map<String, dynamic> _stats = {'nb_ops': 0, 'total_qty': 0.0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() { _ctrCtrl.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    if (appState.currentShiftId != null) {
      final s = await DatabaseService().getShiftStats(appState.currentShiftId!);
      if (mounted) setState(() => _stats = s);
    }
  }

  Future<void> _takePhoto() async {
    final path = await CameraService.takePhoto(prefix: 'end');
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _end() async {
    if (_ctrCtrl.text.trim().isEmpty) {
      _snack('Veuillez saisir l\'index final', error: true); return;
    }
    final counter = double.tryParse(_ctrCtrl.text.trim());
    if (counter == null) { _snack('Index invalide', error: true); return; }

    setState(() => _loading = true);
    await DatabaseService().endShift(
        appState.currentShiftId!, counter, _photoPath ?? '');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.report);
  }

  void _snack(String msg, {bool error = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg),
          backgroundColor: error ? AppTheme.danger : AppTheme.success));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BackHeader(title: lang.t('end_shift')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Center(child: Text('🏁', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 16),

        // Résumé
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
            label: lang.t('total_volume'),
          ),
        ]),
        const SizedBox(height: 24),

        Text('Index compteur final',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ctrCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: '12345.6',
            prefixIcon: Icon(Icons.speed_rounded, color: AppTheme.accent)),
        ),
        const SizedBox(height: 20),

        Text(lang.t('take_photo'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        PhotoButton(photoPath: _photoPath, onTap: _takePhoto,
            label: 'Photo du compteur final'),
        const SizedBox(height: 32),

        AppButton(
          label: '🏁  Clôturer & Générer Rapport',
          color: AppTheme.danger,
          onPressed: _end,
          loading: _loading,
        ),
      ]),
    ),
  );
}
