import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, dynamic>? _shift;
  List<Map<String, dynamic>> _ops = [];
  String? _pdfPath;
  bool _loadingData = true;
  bool _loadingPdf  = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db  = DatabaseService();
    final sid = appState.currentShiftId;
    if (sid != null) {
      _shift = await db.getShift(sid);
      _ops   = await db.getShiftOperations(sid);
    }
    if (mounted) {
      setState(() => _loadingData = false);
      _generatePdf(); // auto-génération
    }
  }

  Future<void> _generatePdf() async {
    if (_shift == null) return;
    setState(() => _loadingPdf = true);
    final path = await PdfService.generateReport(
        shift: _shift!, operations: _ops);
    if (mounted) setState(() { _pdfPath = path; _loadingPdf = false; });
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ PDF généré'), backgroundColor: AppTheme.success));
    }
  }

  Future<void> _share() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Génération PDF en cours...'),
          backgroundColor: AppTheme.accent));
      return;
    }
    await PdfService.shareFile(_pdfPath!,
        message: 'Rapport GsoilFlow — ${_shift?["username"] ?? ""}');
  }

  @override
  Widget build(BuildContext context) {
    final nbOps   = _ops.length;
    final total   = _ops.fold<double>(0, (s, o) => s + ((o['quantity'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('report'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined, size: 22)),
        ],
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Stats card
                SectionCard(child: Column(children: [
                  Row(children: [
                    const Text('📊', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(lang.t('shift_summary'),
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    StatCard(icon: '⛽', value: '${total.toStringAsFixed(0)} L',
                        label: lang.t('total_volume')),
                    const SizedBox(width: 10),
                    StatCard(icon: '🔢', value: '$nbOps',
                        label: lang.t('operations')),
                    const SizedBox(width: 10),
                    StatCard(
                      icon: '👤',
                      value: (_shift?['username'] as String? ?? '—')
                          .substring(0, (_shift?['username'] as String? ?? '—').length.clamp(0, 8)),
                      label: lang.t('operator'),
                    ),
                  ]),
                ])),
                const SizedBox(height: 16),

                // Boutons PDF / WhatsApp
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadingPdf ? null : _generatePdf,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size.fromHeight(50)),
                      icon: _loadingPdf
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(_pdfPath != null ? 'PDF ✓' : lang.t('export_pdf'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _share,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          minimumSize: const Size.fromHeight(50)),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(lang.t('share_whatsapp'),
                          style: const TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Liste opérations
                Text('${lang.t("operations")} (${_ops.length})',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                const SizedBox(height: 10),
                ..._ops.asMap().entries.map((e) {
                  final i  = e.key;
                  final op = e.value;
                  final ts = op['timestamp'] as String? ?? '';
                  final h  = ts.length > 15 ? ts.substring(11, 16) : '—';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border, width: 0.5)),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          shape: BoxShape.circle),
                        child: Center(child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w800, color: AppTheme.accent))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(op['machine_name'] as String? ?? '—',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        Text('${op['family_name']} · $h',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ])),
                      Text('${(op['quantity'] as num?)?.toStringAsFixed(1) ?? "0"} L',
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w800, color: AppTheme.accent)),
                    ]),
                  );
                }),
                const SizedBox(height: 20),

                AppButton(
                  label: '➕  ${lang.t("new_shift")}',
                  onPressed: () {
                    appState.currentShiftId = null;
                    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                  },
                ),
              ],
            ),
    );
  }
}
