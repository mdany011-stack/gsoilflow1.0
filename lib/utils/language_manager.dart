import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const _langFile = 'gsoil_lang.txt';

const Map<String, Map<String, String>> _t = {
  'fr': {
    'app_name': 'GsoilFlow', 'login': 'Connexion', 'logout': 'Déconnexion',
    'username': 'Identifiant', 'password': 'Mot de passe',
    'confirm_password': 'Confirmer le mot de passe',
    'register': 'Créer un compte', 'sign_in': 'Se connecter',
    'welcome': 'Bienvenue', 'shift': 'Shift',
    'operations': 'Opérations', 'total_volume': 'Volume total',
    'start_shift': 'Démarrer le shift', 'end_shift': 'Terminer le shift',
    'counter_index': 'Index compteur', 'take_photo': 'Prendre une photo',
    'choose_family': 'Famille', 'choose_subfamily': 'Sous-famille',
    'choose_machine': 'Machine', 'search': 'Rechercher...',
    'quantity': 'Quantité (litres)', 'flow_counter': 'Index volucompteur',
    'validate': 'Valider', 'cancel': 'Annuler',
    'another_machine': 'Autre machine', 'end_shift_btn': 'Terminer le shift',
    'report': 'Rapport', 'export_pdf': 'Exporter PDF',
    'share_whatsapp': 'Partager WhatsApp', 'settings': 'Paramètres',
    'language': 'Langue', 'import_excel': 'Importer Excel',
    'fill_all': 'Veuillez remplir tous les champs',
    'wrong_password': 'Identifiant ou mot de passe incorrect',
    'user_exists': 'Cet identifiant existe déjà',
    'passwords_no_match': 'Les mots de passe ne correspondent pas',
    'op_count': 'Opérations effectuées', 'total_fuel': 'Gasoil distribué',
    'machine': 'Machine', 'family': 'Famille', 'subfamily': 'Sous-famille',
    'date': 'Date', 'time': 'Heure', 'operator': 'Opérateur',
    'daily_report': 'RAPPORT JOURNALIER - RAVITAILLEMENT GASOIL',
    'error': 'Erreur', 'success': 'Succès', 'ok': 'OK',
    'no_shift': 'Aucun shift actif', 'shift_running': 'Shift en cours',
    'new_shift': 'Nouveau shift', 'close': 'Fermer',
    'confirm': 'Confirmer', 'back': 'Retour',
    'photo_taken': 'Photo prise ✓', 'photo_optional': 'Photo (optionnelle)',
    'liters': 'L', 'start_counter': 'Compteur début',
    'end_counter': 'Compteur fin', 'shift_summary': 'Résumé du shift',
    'generating_pdf': 'Génération du PDF...', 'pdf_ready': 'PDF prêt',
    'select_language': 'Choisir la langue',
  },
  'en': {
    'app_name': 'GsoilFlow', 'login': 'Login', 'logout': 'Logout',
    'username': 'Username', 'password': 'Password',
    'confirm_password': 'Confirm password',
    'register': 'Create account', 'sign_in': 'Sign In',
    'welcome': 'Welcome', 'shift': 'Shift',
    'operations': 'Operations', 'total_volume': 'Total volume',
    'start_shift': 'Start shift', 'end_shift': 'End shift',
    'counter_index': 'Counter index', 'take_photo': 'Take a photo',
    'choose_family': 'Family', 'choose_subfamily': 'Subfamily',
    'choose_machine': 'Machine', 'search': 'Search...',
    'quantity': 'Quantity (liters)', 'flow_counter': 'Flow meter index',
    'validate': 'Validate', 'cancel': 'Cancel',
    'another_machine': 'Another machine', 'end_shift_btn': 'End shift',
    'report': 'Report', 'export_pdf': 'Export PDF',
    'share_whatsapp': 'Share WhatsApp', 'settings': 'Settings',
    'language': 'Language', 'import_excel': 'Import Excel',
    'fill_all': 'Please fill all fields',
    'wrong_password': 'Wrong username or password',
    'user_exists': 'Username already exists',
    'passwords_no_match': 'Passwords do not match',
    'op_count': 'Operations done', 'total_fuel': 'Fuel distributed',
    'machine': 'Machine', 'family': 'Family', 'subfamily': 'Subfamily',
    'date': 'Date', 'time': 'Time', 'operator': 'Operator',
    'daily_report': 'DAILY REPORT - FUEL SUPPLY',
    'error': 'Error', 'success': 'Success', 'ok': 'OK',
    'no_shift': 'No active shift', 'shift_running': 'Shift running',
    'new_shift': 'New shift', 'close': 'Close',
    'confirm': 'Confirm', 'back': 'Back',
    'photo_taken': 'Photo taken ✓', 'photo_optional': 'Photo (optional)',
    'liters': 'L', 'start_counter': 'Start counter',
    'end_counter': 'End counter', 'shift_summary': 'Shift summary',
    'generating_pdf': 'Generating PDF...', 'pdf_ready': 'PDF ready',
    'select_language': 'Select language',
  },
  'tr': {
    'app_name': 'GsoilFlow', 'login': 'Giriş', 'logout': 'Çıkış',
    'username': 'Kullanıcı adı', 'password': 'Şifre',
    'confirm_password': 'Şifreyi onayla',
    'register': 'Hesap oluştur', 'sign_in': 'Giriş Yap',
    'welcome': 'Hoş Geldiniz', 'shift': 'Vardiya',
    'operations': 'İşlemler', 'total_volume': 'Toplam hacim',
    'start_shift': 'Vardiyayı başlat', 'end_shift': 'Vardiyayı bitir',
    'counter_index': 'Sayaç endeksi', 'take_photo': 'Fotoğraf çek',
    'choose_family': 'Aile', 'choose_subfamily': 'Alt aile',
    'choose_machine': 'Makine', 'search': 'Ara...',
    'quantity': 'Miktar (litre)', 'flow_counter': 'Akış sayacı endeksi',
    'validate': 'Onayla', 'cancel': 'İptal',
    'another_machine': 'Başka makine', 'end_shift_btn': 'Vardiyayı bitir',
    'report': 'Rapor', 'export_pdf': 'PDF Dışa Aktar',
    'share_whatsapp': 'WhatsApp Paylaş', 'settings': 'Ayarlar',
    'language': 'Dil', 'import_excel': 'Excel İçe Aktar',
    'fill_all': 'Lütfen tüm alanları doldurun',
    'wrong_password': 'Yanlış kullanıcı adı veya şifre',
    'user_exists': 'Kullanıcı adı zaten mevcut',
    'passwords_no_match': 'Şifreler eşleşmiyor',
    'op_count': 'Yapılan işlemler', 'total_fuel': 'Dağıtılan yakıt',
    'machine': 'Makine', 'family': 'Aile', 'subfamily': 'Alt aile',
    'date': 'Tarih', 'time': 'Saat', 'operator': 'Operatör',
    'daily_report': 'GÜNLÜK RAPOR - YAKIT İKMALİ',
    'error': 'Hata', 'success': 'Başarı', 'ok': 'Tamam',
    'no_shift': 'Aktif vardiya yok', 'shift_running': 'Vardiya devam ediyor',
    'new_shift': 'Yeni vardiya', 'close': 'Kapat',
    'confirm': 'Onayla', 'back': 'Geri',
    'photo_taken': 'Fotoğraf çekildi ✓', 'photo_optional': 'Fotoğraf (isteğe bağlı)',
    'liters': 'L', 'start_counter': 'Başlangıç sayacı',
    'end_counter': 'Bitiş sayacı', 'shift_summary': 'Vardiya özeti',
    'generating_pdf': 'PDF oluşturuluyor...', 'pdf_ready': 'PDF hazır',
    'select_language': 'Dil seçin',
  },
  'ar': {
    'app_name': 'GsoilFlow', 'login': 'تسجيل الدخول', 'logout': 'تسجيل الخروج',
    'username': 'اسم المستخدم', 'password': 'كلمة المرور',
    'confirm_password': 'تأكيد كلمة المرور',
    'register': 'إنشاء حساب', 'sign_in': 'دخول',
    'welcome': 'مرحباً', 'shift': 'وردية',
    'operations': 'العمليات', 'total_volume': 'الحجم الكلي',
    'start_shift': 'بدء الوردية', 'end_shift': 'إنهاء الوردية',
    'counter_index': 'رقم العداد', 'take_photo': 'التقاط صورة',
    'choose_family': 'العائلة', 'choose_subfamily': 'الفئة الفرعية',
    'choose_machine': 'الآلة', 'search': 'بحث...',
    'quantity': 'الكمية (لتر)', 'flow_counter': 'رقم عداد التدفق',
    'validate': 'تأكيد', 'cancel': 'إلغاء',
    'another_machine': 'آلة أخرى', 'end_shift_btn': 'إنهاء الوردية',
    'report': 'التقرير', 'export_pdf': 'تصدير PDF',
    'share_whatsapp': 'مشاركة واتساب', 'settings': 'الإعدادات',
    'language': 'اللغة', 'import_excel': 'استيراد Excel',
    'fill_all': 'يرجى ملء جميع الحقول',
    'wrong_password': 'اسم مستخدم أو كلمة مرور خاطئة',
    'user_exists': 'اسم المستخدم موجود مسبقاً',
    'passwords_no_match': 'كلمات المرور غير متطابقة',
    'op_count': 'العمليات المنجزة', 'total_fuel': 'الوقود الموزع',
    'machine': 'الآلة', 'family': 'العائلة', 'subfamily': 'الفئة الفرعية',
    'date': 'التاريخ', 'time': 'الوقت', 'operator': 'المشغّل',
    'daily_report': 'التقرير اليومي - إمداد الوقود',
    'error': 'خطأ', 'success': 'نجاح', 'ok': 'حسناً',
    'no_shift': 'لا توجد وردية نشطة', 'shift_running': 'الوردية جارية',
    'new_shift': 'وردية جديدة', 'close': 'إغلاق',
    'confirm': 'تأكيد', 'back': 'رجوع',
    'photo_taken': 'تم التقاط الصورة ✓', 'photo_optional': 'صورة (اختياري)',
    'liters': 'ل', 'start_counter': 'عداد البداية',
    'end_counter': 'عداد النهاية', 'shift_summary': 'ملخص الوردية',
    'generating_pdf': 'جارٍ إنشاء PDF...', 'pdf_ready': 'PDF جاهز',
    'select_language': 'اختر اللغة',
  },
};

class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._();
  factory LanguageManager() => _instance;
  LanguageManager._();

  String _lang = 'fr';
  String get current => _lang;

  Future<void> init() async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_langFile');
      if (await file.exists()) {
        final l = await file.readAsString();
        if (_t.containsKey(l.trim())) _lang = l.trim();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    if (!_t.containsKey(lang)) return;
    _lang = lang;
    notifyListeners();
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_langFile');
      await file.writeAsString(lang);
    } catch (_) {}
  }

  String t(String key) => _t[_lang]?[key] ?? _t['fr']?[key] ?? key;
}

final lang = LanguageManager();
