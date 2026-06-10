import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/camera_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class OperationScreen extends StatefulWidget {
  const OperationScreen({super.key});
  @override
  State<OperationScreen> createState() => _OperationScreenState();
}

class _OperationScreenState extends State<OperationScreen> {
  final _qtyCtrl = TextEditingController();
  final _volCtrl = TextEditingController();
  String? _photoPath;
  bool _loading = false;

  @override
  void dispose() { _qtyCtrl.dispose(); _volCtrl.dispose(); super.dispose(); }

  Future<void> _takePhoto() async {
    final path = await CameraService.takePhoto(prefix: 'op');
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _validate() async {
    if (_qtyCtrl.text.trim().isEmpty || _volCtrl.text.trim().isEmpty) {
      _snack(lang.t('fill_all'), error: true); return;
    }
    final qty = double.tryParse(_qtyCtrl.text.trim());
    final vol = double.tryParse(_volCtrl.text.trim());
    if (qty == null || vol == null) { _snack('Valeurs invalides', error: true); return; }
    if (qty <= 0) { _snack('La quantité doit être > 0', error: true); return; }

    setState(() => _loading = true);
    await DatabaseService().addOperation(
      shiftId:       appState.currentShiftId!,
      familyName:    appState.selectedFamilyName    ?? '',
      subfamilyName: appState.selectedSubfamilyName ?? '',
      machineId:     appState.selectedMachineId     ?? 0,
      machineName:   appState.selectedMachineName   ?? '',
      quantity:      qty,
      compteurVol:   vol,
      photoPath:     _photoPath ?? '',
    );
    appState.lastOpQty     = qty;
    appState.lastOpMachine = appState.selectedMachineName;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.postOp);
  }

  void _snack(String msg, {bool error = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg),
          backgroundColor: error ? AppTheme.danger : AppTheme.success));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BackHeader(title: lang.t('operation')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Machine sélectionnée
        SectionCard(child: Row(children: [
          const Text('🔧', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Machine sélectionnée',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            Text(appState.selectedMachineName ?? '—',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppTheme.accent),
                overflow: TextOverflow.ellipsis),
          ])),
        ])),
        const SizedBox(height: 22),

        // Quantité
        Text(lang.t('quantity'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _qtyCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: '0.0',
            prefixIcon: Icon(Icons.local_gas_station_rounded, color: AppTheme.accent),
            suffixText: 'L',
            suffixStyle: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),

        // Volucompteur
        Text(lang.t('flow_counter'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _volCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: '0.0',
            prefixIcon: Icon(Icons.speed_rounded, color: AppTheme.accent)),
        ),
        const SizedBox(height: 20),

        // Photo
        Text(lang.t('take_photo'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        PhotoButton(photoPath: _photoPath, onTap: _takePhoto,
            label: 'Photo du volucompteur'),
        const SizedBox(height: 32),

        AppButton(label: '✅  ${lang.t("validate")}',
            color: AppTheme.success, onPressed: _validate, loading: _loading),
      ]),
    ),
  );
}
