import "dart:io";
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── AppButton ─────────────────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool loading;

  const AppButton({super.key, required this.label, this.onPressed,
      this.color, this.icon, this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
    ),
  );
}

// ── AppTextField ──────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const AppTextField({super.key, required this.hint, required this.controller,
      this.obscure = false, this.keyboardType = TextInputType.text,
      this.prefixIcon, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: const TextStyle(color: AppTheme.textPrimary),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textMuted, size: 20) : null,
    ),
  );
}

// ── StatCard ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String icon, value, label;
  final Color? valueColor;

  const StatCard({super.key, required this.icon, required this.value,
      required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.card2, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: valueColor ?? AppTheme.accent)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ]),
    ),
  );
}

// ── SectionCard ───────────────────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.card, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border, width: 0.5)),
    child: child,
  );
}

// ── PhotoButton ───────────────────────────────────────────────────────────
class PhotoButton extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onTap;
  final String label;

  const PhotoButton({super.key, this.photoPath, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: photoPath != null ? 140 : 64,
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: photoPath != null ? AppTheme.success : AppTheme.border, width: 1.5),
      ),
      child: photoPath != null
          ? Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(File(photoPath!), fit: BoxFit.cover)),
              Positioned(bottom: 8, right: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('✓ Photo prise', style: TextStyle(color: Colors.white, fontSize: 11)),
              )),
            ])
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_rounded, color: AppTheme.accent, size: 22),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ]),
    ),
  );
}

// ── BackHeader ────────────────────────────────────────────────────────────
class BackHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const BackHeader({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    actions: actions,
  );
}

// ── Import manquant File ──────────────────────────────────────────────────
