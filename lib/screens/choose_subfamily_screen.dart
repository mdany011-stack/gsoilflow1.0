import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class ChooseSubfamilyScreen extends StatefulWidget {
  const ChooseSubfamilyScreen({super.key});
  @override
  State<ChooseSubfamilyScreen> createState() => _ChooseSubfamilyScreenState();
}

class _ChooseSubfamilyScreenState extends State<ChooseSubfamilyScreen> {
  List<Map<String, dynamic>> _subs = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final code = appState.selectedFamilyCode ?? '';
    final s = await DatabaseService().getSubfamilies(code);
    if (mounted) setState(() => _subs = s);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BackHeader(title: appState.selectedFamilyName ?? lang.t('choose_subfamily')),
    body: _subs.isEmpty
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _subs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final sf = _subs[i];
              return GestureDetector(
                onTap: () {
                  appState.selectedSubfamilyCode = sf['code'] as String;
                  appState.selectedSubfamilyName = sf['name'] as String;
                  Navigator.pushNamed(context, AppRoutes.chooseMachine);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.card, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border, width: 0.5)),
                  child: Row(children: [
                    Text(sf['icon'] as String? ?? '🔧',
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(sf['name'] as String? ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary))),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.accent, size: 22),
                  ]),
                ),
              );
            },
          ),
  );
}
