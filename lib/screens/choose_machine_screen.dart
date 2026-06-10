import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class ChooseMachineScreen extends StatefulWidget {
  const ChooseMachineScreen({super.key});
  @override
  State<ChooseMachineScreen> createState() => _ChooseMachineScreenState();
}

class _ChooseMachineScreenState extends State<ChooseMachineScreen> {
  List<Map<String, dynamic>> _all      = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final code = appState.selectedSubfamilyCode ?? '';
    final m    = await DatabaseService().getMachines(code);
    if (mounted) setState(() { _all = m; _filtered = m; });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() => _filtered = q.isEmpty
        ? _all
        : _all.where((m) => (m['name'] as String).toLowerCase().contains(q)).toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BackHeader(title: appState.selectedSubfamilyName ?? lang.t('choose_machine')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: lang.t('search'),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                    onPressed: () { _searchCtrl.clear(); _filter(); })
                : null,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Align(alignment: Alignment.centerLeft,
          child: Text('${_filtered.length} machine${_filtered.length != 1 ? "s" : ""}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
      ),
      Expanded(
        child: _all.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : _filtered.isEmpty
                ? const Center(child: Text('Aucun résultat',
                    style: TextStyle(color: AppTheme.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      return GestureDetector(
                        onTap: () {
                          appState.selectedMachineId   = m['id'] as int;
                          appState.selectedMachineName = m['name'] as String;
                          Navigator.pushNamed(context, AppRoutes.operation);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppTheme.card, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border, width: 0.5)),
                          child: Row(children: [
                            const Icon(Icons.settings_outlined, color: AppTheme.accent, size: 18),
                            const SizedBox(width: 12),
                            Expanded(child: Text(m['name'] as String,
                                style: const TextStyle(fontSize: 13,
                                    color: AppTheme.textPrimary),
                                overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textMuted, size: 20),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    ]),
  );
}
