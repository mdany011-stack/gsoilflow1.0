import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/app_routes.dart';
import '../utils/language_manager.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _pwdCtrl  = TextEditingController();
  bool _loading   = false;
  bool _showPwd   = false;

  @override
  void dispose() {
    _userCtrl.dispose(); _pwdCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _pwdCtrl.text.trim().isEmpty) {
      _snack(lang.t('fill_all'), error: true); return;
    }
    setState(() => _loading = true);
    final user = await DatabaseService().loginUser(
        _userCtrl.text.trim(), _pwdCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (user == null) { _snack(lang.t('wrong_password'), error: true); return; }

    appState.currentUser = _userCtrl.text.trim();
    final shift = await DatabaseService().getOpenShift(appState.currentUser!);
    if (shift != null) appState.currentShiftId = shift['id'] as int;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
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
          const SizedBox(height: 20),
          // Logo
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('⛽', style: TextStyle(fontSize: 38))),
          ),
          const SizedBox(height: 16),
          const Text('GsoilFlow',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                  color: AppTheme.accent, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Gestion Ravitaillement Gasoil',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 40),

          // Carte formulaire
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 0.5)),
            child: Column(children: [
              AppTextField(
                  hint: lang.t('username'), controller: _userCtrl,
                  prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pwdCtrl, obscureText: !_showPwd,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: lang.t('password'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.textMuted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textMuted, size: 20),
                    onPressed: () => setState(() => _showPwd = !_showPwd),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(label: lang.t('sign_in'), onPressed: _login,
                  icon: Icons.login_rounded, loading: _loading),
            ]),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
            child: Text("Pas de compte ?  ${lang.t('register')}",
                style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
        ]),
      ),
    ),
  );
}
