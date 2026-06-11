import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class ChooseFamilyScreen extends StatefulWidget {
  const ChooseFamilyScreen({super.key});
  @override
  State<ChooseFamilyScreen> createState() => _ChooseFamilyScreenState();
}

class _ChooseFamilyScreenState extends State<ChooseFamilyScreen> {
  List<Map<String, dynamic>> _families = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final f = await DatabaseService().getFamilies();
    if (mounted) setState(() => _families = f);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BackHeader(title: lang.t('choose_family')),
    body: _families.isEmpty
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 1.2),
            itemCount: _families.length,
            itemBuilder: (_, i) => _FamilyCard(
              family: _families[i],
              onTap: () {
                appState.selectedFamilyCode = _families[i]['code'] as String;
                appState.selectedFamilyName = _families[i]['name'] as String;
                Navigator.pushNamed(context, AppRoutes.chooseSubfamily);
              },
            ),
          ),
  );
}

class _FamilyCard extends StatelessWidget {
  final Map<String, dynamic> family;
  final VoidCallback onTap;

  const _FamilyCard({required this.family, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppTheme.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.card, AppTheme.card2]),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(family['icon'] as String? ?? '⚙️',
            style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(family['name'] as String? ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
      ]),
    ),
  );
}
