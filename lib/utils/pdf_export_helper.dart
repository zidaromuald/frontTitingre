import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gestauth_clean/services/partenariat/transaction_partenariat_service.dart';

/// Helper pour générer et partager/télécharger un reçu PDF de transaction
class PdfExportHelper {
  static const PdfColor _bleuTitingre = PdfColor.fromInt(0xFF1E4A8C);
  static const PdfColor _bleuFonce = PdfColor.fromInt(0xFF0B2340);
  static const PdfColor _vert = PdfColor.fromInt(0xFF28A745);
  static const PdfColor _orange = PdfColor.fromInt(0xFFFFA500);
  static const PdfColor _rouge = PdfColor.fromInt(0xFFDC3545);
  static const PdfColor _grisClair = PdfColor.fromInt(0xFFF4F4F4);
  static const PdfColor _grisTexte = PdfColor.fromInt(0xFF8D8D8D);

  /// Génère et partage le PDF d'une seule transaction
  static Future<void> exportSingleTransaction({
    required TransactionPartenaritModel transaction,
    required String partenaireName,
  }) async {
    final bytes = await _buildSingleTransactionPdf(transaction, partenaireName);
    final safeName = transaction.produit.replaceAll(RegExp(r'[^\w]'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recu_transaction_$safeName.pdf',
    );
  }

  /// Génère et partage le PDF de toutes les transactions d'un partenaire
  static Future<void> exportAllTransactions({
    required List<TransactionPartenaritModel> transactions,
    required String partenaireName,
  }) async {
    final bytes = await _buildAllTransactionsPdf(transactions, partenaireName);
    final safeName = partenaireName.replaceAll(RegExp(r'[^\w]'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'transactions_$safeName.pdf',
    );
  }

  // ─────────────────────────────────────────────
  // Construction du PDF — transaction unique
  // ─────────────────────────────────────────────
  static Future<Uint8List> _buildSingleTransactionPdf(
    TransactionPartenaritModel t,
    String partenaireName,
  ) async {
    final doc = pw.Document();
    final statusColor = _getStatusColor(t.statut);
    final now = DateTime.now();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── EN-TÊTE ─────────────────────────────────
              _buildHeader(),
              pw.SizedBox(height: 20),

              // ── TITRE REÇU ──────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const pw.BoxDecoration(
                  color: _bleuTitingre,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'REÇU DE TRANSACTION',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Text(
                        t.getStatusLabel().toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── PARTENAIRE ──────────────────────────────
              _buildSectionTitle('Informations Partenaire'),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildInfoBox(
                      label: 'Société',
                      value: t.societeNom ?? partenaireName,
                      icon: '▣',
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildInfoBox(
                      label: 'Utilisateur',
                      value: t.userNom != null
                          ? '${t.userNom} ${t.userPrenom ?? ''}'.trim()
                          : 'Non renseigné',
                      icon: '●',
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── DÉTAILS TRANSACTION ─────────────────────
              _buildSectionTitle('Détails de la Transaction'),
              pw.SizedBox(height: 8),
              _buildDetailTable(t),
              pw.SizedBox(height: 16),

              // ── TOTAUX ──────────────────────────────────
              _buildTotauxBox(t),
              pw.SizedBox(height: 16),

              // ── STATUT / VALIDATION ─────────────────────
              if (t.isValidee()) ...[
                _buildStatusBanner(
                  icon: '✓',
                  text: 'Transaction validée${t.dateValidation != null ? ' le ${_formatDate(t.dateValidation!)}' : ''}',
                  color: _vert,
                ),
                pw.SizedBox(height: 12),
              ],
              if (t.isRejetee()) ...[
                _buildStatusBanner(
                  icon: '✗',
                  text: 'Transaction rejetée${t.commentaire != null ? ' — Raison : ${t.commentaire}' : ''}',
                  color: _rouge,
                ),
                pw.SizedBox(height: 12),
              ],

              pw.Spacer(),

              // ── PIED DE PAGE ────────────────────────────
              _buildFooter(now),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ─────────────────────────────────────────────
  // Construction du PDF — toutes les transactions
  // ─────────────────────────────────────────────
  static Future<Uint8List> _buildAllTransactionsPdf(
    List<TransactionPartenaritModel> transactions,
    String partenaireName,
  ) async {
    final doc = pw.Document();
    final now = DateTime.now();

    final validees = transactions.where((t) => t.isValidee()).length;
    final enAttente = transactions.where((t) => t.isEnAttente()).length;
    final rejetees = transactions.where((t) => t.isRejetee()).length;
    final totalValeur = transactions
        .where((t) => t.isValidee())
        .fold(0.0, (sum, t) => sum + t.prixTotal);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(now),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),

            // ── TITRE ───────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: _bleuTitingre,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RELEVÉ DES TRANSACTIONS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Partenaire : $partenaireName',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                  ),
                  pw.Text(
                    'Généré le : ${_formatDate(now)}',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── RÉSUMÉ ──────────────────────────────────
            _buildSectionTitle('Résumé'),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildStatCard('Total', '${transactions.length}', _bleuTitingre),
                pw.SizedBox(width: 8),
                _buildStatCard('Validées', '$validees', _vert),
                pw.SizedBox(width: 8),
                _buildStatCard('En attente', '$enAttente', _orange),
                pw.SizedBox(width: 8),
                _buildStatCard('Rejetées', '$rejetees', _rouge),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _vert.shade(0.1),
                border: pw.Border.all(color: _vert),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Valeur totale validée : ${_formatMontant(totalValeur)} CFA',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _vert,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── TABLEAU DES TRANSACTIONS ─────────────────
            _buildSectionTitle('Détail des Transactions'),
            pw.SizedBox(height: 8),
            _buildTransactionsTable(transactions),
          ];
        },
      ),
    );

    return doc.save();
  }

  // ─────────────────────────────────────────────
  // Widgets réutilisables
  // ─────────────────────────────────────────────

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _bleuTitingre, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TITINGRE',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _bleuTitingre,
                ),
              ),
              pw.Text(
                'Réseau Social Professionnel B2B',
                style: const pw.TextStyle(fontSize: 9, color: _grisTexte),
              ),
            ],
          ),
          pw.Text(
            'www.titingre.com',
            style: const pw.TextStyle(fontSize: 9, color: _grisTexte),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _grisClair, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Document généré par Titingre le ${_formatDate(now)}',
            style: const pw.TextStyle(fontSize: 8, color: _grisTexte),
          ),
          pw.Text(
            'www.titingre.com',
            style: const pw.TextStyle(fontSize: 8, color: _grisTexte),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 16, color: _bleuTitingre),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _bleuFonce,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoBox({
    required String label,
    required String value,
    required String icon,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _grisClair,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _bleuTitingre.shade(0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$icon  $label',
            style: const pw.TextStyle(fontSize: 9, color: _grisTexte),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _bleuFonce,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailTable(TransactionPartenaritModel t) {
    final rows = [
      ['Produit / Service', t.produit],
      ['Période', t.periodeFormatee],
      ['Catégorie', t.categorie ?? '—'],
      ['Quantité', t.quantiteFormatee],
      ['Prix unitaire', t.prixUnitaireFormate],
      ['Date de création', _formatDate(t.createdAt)],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _grisClair),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row[0],
                style: const pw.TextStyle(fontSize: 10, color: _grisTexte),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _bleuFonce,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTotauxBox(TransactionPartenaritModel t) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _bleuTitingre.shade(0.08),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _bleuTitingre),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem('Quantité', t.quantiteFormatee),
          _buildTotalItem('Prix Unitaire', t.prixUnitaireFormate),
          _buildTotalItem('PRIX TOTAL', t.prixTotalFormate, highlight: true),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalItem(String label, String value, {bool highlight = false}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: highlight ? 10 : 9,
            color: highlight ? _bleuTitingre : _grisTexte,
            fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: highlight ? 14 : 12,
            fontWeight: pw.FontWeight.bold,
            color: highlight ? _bleuTitingre : _bleuFonce,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusBanner({
    required String icon,
    required String text,
    required PdfColor color,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: color),
      ),
      child: pw.Text(
        '$icon  $text',
        style: pw.TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color.shade(0.1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: _grisTexte),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTransactionsTable(List<TransactionPartenaritModel> transactions) {
    const headers = ['Produit', 'Période', 'Qté', 'Prix Unit.', 'Total CFA', 'Statut'];

    return pw.Table(
      border: pw.TableBorder.all(color: _grisClair),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _bleuTitingre),
          children: headers.map((h) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            );
          }).toList(),
        ),
        // Lignes
        ...transactions.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final bgColor = i.isEven ? PdfColors.white : _grisClair;
          final statusColor = _getStatusColor(t.statut);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              _tableCell(t.produit),
              _tableCell(t.periodeFormatee),
              _tableCell(t.quantiteFormatee),
              _tableCell(t.prixUnitaireFormate),
              _tableCell(
                t.prixTotalFormate,
                bold: true,
                color: _bleuFonce,
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: statusColor.shade(0.15),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    t.getStatusLabel(),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _bleuFonce,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Utilitaires
  // ─────────────────────────────────────────────

  static PdfColor _getStatusColor(String statut) {
    switch (statut) {
      case 'validee':
        return _vert;
      case 'rejetee':
        return _rouge;
      default:
        return _orange;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}
