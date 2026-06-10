import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _importing = false;

  static const _langs = [
    {'code': 'fr', 'flag': '🇫🇷', 'label': 'Français'},
    {'code': 'en', 'flag': '🇬🇧', 'label': 'English'},
    {'code': 'tr', 'flag': '🇹🇷', 'label': 'Türkçe'},
    {'code': 'ar', 'flag': '🇸🇦', 'label': 'العربية'},
  ];

  Future<void> _importExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _importing = true);
      final path = result.files.first.path!;
      final bytes = await File(path).readAsBytes();
      final xl = excel.Excel.decodeBytes(bytes);

      final Map<String, Map<String, List<String>>> data = {};

      for (final sheetName in xl.tables.keys) {
        final sheet = xl.tables[sheetName]!;
        if (sheet.rows.isEmpty) continue;
        final familyName = sheetName.trim();
        data[familyName] = {};

        final headers = sheet.rows.first
            .map((c) => c?.value?.toString().trim() ?? '')
            .toList();

        for (int ci = 0; ci < headers.length; ci++) {
          final sfName = headers[ci];
          if (sfName.isEmpty) continue;
          data[familyName]![sfName] = [];
          for (int ri = 1; ri < sheet.rows.length; ri++) {
            final row = sheet.rows[ri];
            if (ci >= row.length) continue;
            final cell = row[ci]?.value?.toString().trim() ?? '';
            if (cell.isNotEmpty) data[familyName]![sfName]!.add(cell);
          }
        }
      }

      final count = await DatabaseService().importFromExcel(data);
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $count machines importées'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _importing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BackHeader(title: lang.t('settings')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('👤  Compte'),
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.accent,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connecté en tant que',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          appState.currentUser ?? '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('🌐  ${lang.t("language")}'),
            const SizedBox(height: 8),
            ..._langs.map((l) {
              final isActive = lang.current == l['code'];
              return GestureDetector(
                onTap: () async {
                  await lang.setLanguage(l['code']!);
                  if (mounted) setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accent.withOpacity(0.12)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? AppTheme.accent : AppTheme.border,
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l['label']!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive
                                ? AppTheme.accent
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isActive)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            _sectionTitle('📥  ${lang.t("import_excel")}'),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format attendu :\n'
                    '• Nom de la feuille = Famille\n'
                    '• Ligne 1 = Sous-familles\n'
                    '• Cellules = Noms des machines',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: _importing
                        ? 'Importation...'
                        : '📂  Sélectionner un fichier .xlsx',
                    loading: _importing,
                    color: AppTheme.primary,
                    icon: Icons.upload_file_rounded,
                    onPressed: _importExcel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('ℹ️  À propos'),
            SectionCard(
              child: Column(
                children: [
                  const Text('⛽', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text(
                    'GsoilFlow v1.0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestion de ravitaillement en gasoil\npour engins de chantier industriel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: lang.t('logout'),
              color: AppTheme.danger,
              icon: Icons.logout_rounded,
              onPressed: () async {
                await DatabaseService().logoutUser(appState.currentUser ?? '');
                appState.reset();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
      );
}
