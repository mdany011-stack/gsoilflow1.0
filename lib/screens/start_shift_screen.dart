import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/camera_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class StartShiftScreen extends StatefulWidget {
  const StartShiftScreen({super.key});
  @override
  State<StartShiftScreen> createState() => _StartShiftScreenState();
}

class _StartShiftScreenState extends State<StartShiftScreen> {
  final _ctrCtrl = TextEditingController();
  String? _photoPath;
  bool _loading = false;

  @override
  void dispose() { _ctrCtrl.dispose(); super.dispose(); }

  Future<void> _takePhoto() async {
    final path = await CameraService.takePhoto(prefix: 'start');
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _start() async {
    if (_ctrCtrl.text.trim().isEmpty) {
      _snack(lang.t('fill_all'), error: true); return;
    }
    final counter = double.tryParse(_ctrCtrl.text.trim());
    if (counter == null) { _snack('Index invalide', error: true); return; }

    setState(() => _loading = true);
    final sid = await DatabaseService().startShift(
        appState.currentUser!, counter, _photoPath ?? '');
    appState.currentShiftId = sid;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
  }

  void _snack(String msg, {bool error = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg),
          backgroundColor: error ? AppTheme.danger : AppTheme.success));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BackHeader(title: lang.t('start_shift')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Center(child: Text('⏱️', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 16),
        Center(child: Text(
            'Relevez l\'index du compteur général\navant de commencer le shift',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted))),
        const SizedBox(height: 28),

        Text(lang.t('counter_index'),
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
            prefixIcon: Icon(Icons.speed_rounded, color: AppTheme.accent),
          ),
        ),
        const SizedBox(height: 20),

        Text(lang.t('take_photo'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        PhotoButton(photoPath: _photoPath, onTap: _takePhoto,
            label: lang.t('take_photo')),

        const SizedBox(height: 32),
        AppButton(label: '🚀  ${lang.t("start_shift")}',
            onPressed: _start, loading: _loading),
      ]),
    ),
  );
}
