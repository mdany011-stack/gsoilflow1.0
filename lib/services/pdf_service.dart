import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {

  static Future<String?> generateReport({
    required Map<String, dynamic> shift,
    required List<Map<String, dynamic>> operations,
  }) async {
    final pdf = pw.Document();

    // Couleurs
    final cPrimary = PdfColor.fromHex('0D1F3C');
    final cAccent  = PdfColor.fromHex('FA8C12');
    final cSuccess = PdfColor.fromHex('21B35E');
    final cLight   = PdfColor.fromHex('F5F7FA');
    final cMuted   = PdfColor.fromHex('6B7A99');
    final cWhite   = PdfColors.white;

    final nbOps   = operations.length;
    final totalQty= operations.fold<double>(0, (s, o) => s + ((o['quantity'] as num?)?.toDouble() ?? 0));
    final avgQty  = nbOps > 0 ? totalQty / nbOps : 0.0;

    // Charger les images
    Future<pw.ImageProvider?> loadImg(String? path) async {
      if (path == null || path.isEmpty) return null;
      try {
        final f = File(path);
        if (!await f.exists() || await f.length() == 0) return null;
        final bytes = await f.readAsBytes();
        return pw.MemoryImage(bytes);
      } catch (_) { return null; }
    }

    final startImg = await loadImg(shift['start_photo'] as String?);
    final endImg   = await loadImg(shift['end_photo']   as String?);

    // Charger images opérations
    final opImages = <int, pw.ImageProvider>{};
    for (int i = 0; i < operations.length; i++) {
      final img = await loadImg(operations[i]['photo_path'] as String?);
      if (img != null) opImages[i] = img;
    }

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    String fmtDt(String? s) {
      if (s == null || s.isEmpty) return '—';
      try {
        final dt = DateTime.parse(s);
        return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
               '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) { return s; }
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(15 * PdfPageFormat.mm),
      build: (ctx) => [

        // ── BANDEAU TITRE ─────────────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            color: cPrimary,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: pw.Row(children: [
            pw.Text('⛽', style: pw.TextStyle(fontSize: 28, color: cWhite)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('GsoilFlow', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: cAccent)),
              pw.Text('RAPPORT JOURNALIER — RAVITAILLEMENT GASOIL',
                  style: pw.TextStyle(fontSize: 10, color: cWhite)),
            ])),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(dateStr, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: cWhite)),
              pw.Text(timeStr, style: pw.TextStyle(fontSize: 10, color: cMuted)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 16),

        // ── INFOS SHIFT ───────────────────────────────────────────────────
        _sectionTitle('📋  Informations du Shift', cPrimary),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('C5D0E0'), width: 0.5),
          children: [
            _tableHeaderRow(['Opérateur', 'Début', 'Fin'], cPrimary),
            _tableRow([
              shift['username'] ?? '—',
              fmtDt(shift['start_time'] as String?),
              fmtDt(shift['end_time']   as String?),
            ], cLight),
            _tableHeaderRow(['Index Début', 'Index Fin', 'Consommation Compteur'], cPrimary),
            _tableRow([
              '${shift['start_counter'] ?? 0}',
              '${shift['end_counter']   ?? "—"}',
              () {
                final s = (shift['start_counter'] as num?)?.toDouble() ?? 0;
                final e = (shift['end_counter']   as num?)?.toDouble();
                return e != null ? '${(e - s).toStringAsFixed(1)} L' : '—';
              }(),
            ], cLight),
          ],
        ),
        pw.SizedBox(height: 16),

        // ── STATS ─────────────────────────────────────────────────────────
        _sectionTitle('📊  Résumé du Shift', cPrimary),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          _statCard('Opérations', '$nbOps', cPrimary, cAccent),
          pw.SizedBox(width: 8),
          _statCard('Volume Total', '${totalQty.toStringAsFixed(1)} L', cPrimary, cAccent),
          pw.SizedBox(width: 8),
          _statCard('Moyenne / Op.', '${avgQty.toStringAsFixed(1)} L', cPrimary, cAccent),
        ]),
        pw.SizedBox(height: 16),

        // ── TABLEAU OPÉRATIONS ────────────────────────────────────────────
        _sectionTitle('📝  Détail des Opérations', cPrimary),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: {
            0: const pw.FixedColumnWidth(20),
            1: const pw.FixedColumnWidth(42),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(4),
            4: const pw.FixedColumnWidth(32),
            5: const pw.FixedColumnWidth(40),
          },
          border: pw.TableBorder.all(color: PdfColor.fromHex('C5D0E0'), width: 0.3),
          children: [
            _tableHeaderRow(['#', 'Heure', 'Famille', 'Machine', 'Qté (L)', 'Volucomp.'], cPrimary),
            ...operations.asMap().entries.map((e) {
              final i  = e.key;
              final op = e.value;
              final ts = op['timestamp'] as String? ?? '';
              final h  = ts.length > 15 ? ts.substring(11, 16) : '—';
              return _tableRow([
                '${i + 1}',
                h,
                (op['family_name'] as String? ?? '—'),
                (op['machine_name'] as String? ?? '—'),
                '${(op['quantity'] as num?)?.toStringAsFixed(1) ?? "0"}',
                '${(op['compteur_vol'] as num?)?.toStringAsFixed(1) ?? "0"}',
              ], i.isEven ? cLight : PdfColors.white, fontSize: 7.5),
            }),
          ],
        ),
        pw.SizedBox(height: 16),

        // ── PHOTOS COMPTEURS ──────────────────────────────────────────────
        if (startImg != null || endImg != null) ...[
          _sectionTitle('📷  Photos Compteurs', cPrimary),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            if (startImg != null) ...[
              pw.Column(children: [
                pw.Image(startImg, width: 85 * PdfPageFormat.mm, height: 60 * PdfPageFormat.mm, fit: pw.BoxFit.cover),
                pw.SizedBox(height: 3),
                pw.Text('Compteur Début', style: pw.TextStyle(fontSize: 8, color: cMuted)),
              ]),
              pw.SizedBox(width: 8),
            ],
            if (endImg != null)
              pw.Column(children: [
                pw.Image(endImg, width: 85 * PdfPageFormat.mm, height: 60 * PdfPageFormat.mm, fit: pw.BoxFit.cover),
                pw.SizedBox(height: 3),
                pw.Text('Compteur Fin', style: pw.TextStyle(fontSize: 8, color: cMuted)),
              ]),
          ]),
          pw.SizedBox(height: 16),
        ],

        // ── PHOTOS OPÉRATIONS ─────────────────────────────────────────────
        if (opImages.isNotEmpty) ...[
          _sectionTitle('📷  Photos Volucompteurs', cPrimary),
          pw.SizedBox(height: 6),
          pw.Wrap(spacing: 6, runSpacing: 6, children: [
            ...opImages.entries.map((e) => pw.Column(children: [
              pw.Image(e.value, width: 55 * PdfPageFormat.mm, height: 40 * PdfPageFormat.mm, fit: pw.BoxFit.cover),
              pw.SizedBox(height: 2),
              pw.Text(
                (operations[e.key]['machine_name'] as String? ?? '').length > 22
                    ? (operations[e.key]['machine_name'] as String).substring(0, 22) + '…'
                    : (operations[e.key]['machine_name'] as String? ?? ''),
                style: pw.TextStyle(fontSize: 7, color: cMuted),
              ),
            ])),
          ]),
        ],

        // ── PIED DE PAGE ──────────────────────────────────────────────────
        pw.Divider(color: PdfColor.fromHex('243050')),
        pw.Text('Rapport généré par GsoilFlow • $dateStr à $timeStr',
            style: pw.TextStyle(fontSize: 7, color: cMuted),
            textAlign: pw.TextAlign.center),
      ],
    ));

    // Sauvegarder
    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'reports',
        'rapport_${now.millisecondsSinceEpoch}.pdf');
    await Directory(p.dirname(path)).create(recursive: true);
    final bytes = await pdf.save();
    await File(path).writeAsBytes(bytes);
    return path;
  }

  // ── Share via WhatsApp / système ─────────────────────────────────────────
  static Future<void> shareFile(String path, {String? message}) async {
    final file = XFile(path, mimeType: 'application/pdf');
    await Share.shareXFiles(
      [file],
      text: message ?? 'Rapport GsoilFlow',
      subject: 'Rapport Ravitaillement Gasoil',
    );
  }

  // ── Print ──────────────────────────────────────────────────────────────
  static Future<void> printFile(String path) async {
    final bytes = await File(path).readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ── Widgets helper ───────────────────────────────────────────────────────
  static pw.Widget _sectionTitle(String text, PdfColor color) =>
      pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color));

  static pw.TableRow _tableHeaderRow(List<String> cells, PdfColor bg) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: cells.map((c) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(c, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        )).toList(),
      );

  static pw.TableRow _tableRow(List<String> cells, PdfColor bg, {double fontSize = 9}) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: cells.map((c) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(c, style: pw.TextStyle(fontSize: fontSize)),
        )).toList(),
      );

  static pw.Widget _statCard(String label, String value, PdfColor bg, PdfColor accent) =>
      pw.Expanded(child: pw.Container(
        decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(8)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
        ]),
      ));
}
