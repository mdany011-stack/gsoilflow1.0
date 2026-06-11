import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl  = TextEditingController();
  final _pwd1Ctrl  = TextEditingController();
  final _pwd2Ctrl  = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() {
    _userCtrl.dispose(); _pwd1Ctrl.dispose(); _pwd2Ctrl.dispose(); super.dispose();
  }

  Future<void> _register() async {
    final u  = _userCtrl.text.trim();
    final p1 = _pwd1Ctrl.text.trim();
    final p2 = _pwd2Ctrl.text.trim();
    if (u.isEmpty || p1.isEmpty || p2.isEmpty) {
      _snack(lang.t('fill_all'), error: true); return;
    }
    if (p1 != p2) { _snack(lang.t('passwords_no_match'), error: true); return; }
    if (p1.length < 4) { _snack('Mot de passe trop court (min 4)', error: true); return; }

    setState(() => _loading = true);
    final ok = await DatabaseService().registerUser(u, p1);
    setState(() => _loading = false);
    if (!mounted) return;
    if (!ok) { _snack(lang.t('user_exists'), error: true); return; }
    _snack('Compte créé avec succès !');
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _snack(String msg, {bool error = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg),
          backgroundColor: error ? AppTheme.danger : AppTheme.success));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(children: [
          const SizedBox(height: 10),
          const Text('➕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(lang.t('register'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                  color: AppTheme.accent)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 0.5)),
            child: Column(children: [
              AppTextField(hint: lang.t('username'), controller: _userCtrl,
                  prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 14),
              AppTextField(hint: lang.t('password'), controller: _pwd1Ctrl,
                  obscure: true, prefixIcon: Icons.lock_outline_rounded),
              const SizedBox(height: 14),
              AppTextField(hint: lang.t('confirm_password'), controller: _pwd2Ctrl,
                  obscure: true, prefixIcon: Icons.lock_outline_rounded),
              const SizedBox(height: 20),
              AppButton(label: lang.t('register'), onPressed: _register,
                  color: AppTheme.success, icon: Icons.check_circle_outline, loading: _loading),
            ]),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('← ${lang.t("back")}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
        ]),
      ),
    ),
  );
}
