import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_model.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';

class PdfExportService {
  /// PDF Raporunu oluşturur, geçici dizine kaydeder ve yerel paylaşım ekranını açar.
  static Future<File> exportAndSharePdf({
    required List<TransactionModel> transactions,
    required DateTimeRange dateRange,
    required String userEmail,
  }) async {
    final pdf = pw.Document();

    // 1. Türkçe karakter desteği için Google Fonts Roboto fontlarını yükle
    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final mediumFont = await PdfGoogleFonts.robotoMedium();

    // 2. Formatlayıcılar
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);

    // 3. Hesaplamalar
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final t in transactions) {
      final isIncome = t.type.toLowerCase() == 'gelir' || t.type.toLowerCase() == 'income';
      if (isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    final double netBalance = totalIncome - totalExpense;

    // Renk Tanımlamaları
    const primaryColor = PdfColor.fromInt(0xFF1976D2);
    const primaryLightColor = PdfColor.fromInt(0xFFE3F2FD);
    const incomeColor = PdfColor.fromInt(0xFF2E7D32);
    const incomeBgColor = PdfColor.fromInt(0xFFE8F5E9);
    const expenseColor = PdfColor.fromInt(0xFFC62828);
    const expenseBgColor = PdfColor.fromInt(0xFFFFEBEE);
    final netColor = netBalance >= 0 ? incomeColor : expenseColor;
    final netBgColor = netBalance >= 0 ? incomeBgColor : expenseBgColor;

    // 4. PDF Sayfa Düzeni
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: [regularFont, boldFont],
        ),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GELİR & GİDER TAKİP',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 20,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Finansal Hesap Özeti & İşlem Raporu',
                          style: pw.TextStyle(
                            font: mediumFont,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Rapor Tarihi: ${dateTimeFormat.format(DateTime.now())}',
                          style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Kullanıcı: ${userEmail.isNotEmpty ? userEmail : "Belirtilmedi"}',
                          style: pw.TextStyle(font: mediumFont, fontSize: 9, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: primaryLightColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'Aralık: ${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
                            style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Gelir-Gider Takip Uygulaması © ${DateTime.now().year} - Yerel PDF Raporu',
                  style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(font: mediumFont, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ÖZET KARTLARI
            pw.Row(
              children: [
                // Toplam Gelir Kutusu
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: incomeBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: incomeColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOPLAM GELİR',
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: incomeColor),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          currencyFormat.format(totalIncome),
                          style: pw.TextStyle(font: boldFont, fontSize: 13, color: incomeColor),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Toplam Gider Kutusu
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: expenseBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: expenseColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOPLAM GİDER',
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: expenseColor),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          currencyFormat.format(totalExpense),
                          style: pw.TextStyle(font: boldFont, fontSize: 13, color: expenseColor),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Net Bakiye Kutusu
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: netBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: netColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NET BAKİYE',
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: netColor),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${netBalance >= 0 ? "+" : ""}${currencyFormat.format(netBalance)}',
                          style: pw.TextStyle(font: boldFont, fontSize: 13, color: netColor),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // İşlem Adedi Kutusu
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'İŞLEM SAYISI',
                        style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${transactions.length}',
                        style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.grey900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // TABLO BAŞLIĞI
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'İŞLEM LİSTESİ',
                  style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Toplam ${transactions.length} kayıt listelendi',
                  style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // İŞLEM TABLOSU
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: primaryColor,
              ),
              headerPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              cellStyle: pw.TextStyle(
                font: regularFont,
                fontSize: 8,
                color: PdfColors.grey900,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9FAFB),
              ),
              headers: <String>[
                'Tarih',
                'Tür',
                'Kategori',
                'Ödeme Yöntemi',
                'Tutar',
                'Açıklama',
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(55), // Tarih
                1: pw.FixedColumnWidth(40), // Tür
                2: pw.FixedColumnWidth(75), // Kategori
                3: pw.FixedColumnWidth(65), // Ödeme Yöntemi
                4: pw.FixedColumnWidth(70), // Tutar
                5: pw.FlexColumnWidth(1),   // Açıklama
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerLeft,
              },
              data: transactions.map((item) {
                final isIncome = item.type.toLowerCase() == 'gelir' || item.type.toLowerCase() == 'income';
                final sign = isIncome ? '+ ' : '- ';
                final formattedAmount = '$sign${currencyFormat.format(item.amount)}';

                return <String>[
                  dateFormat.format(item.date),
                  isIncome ? 'Gelir' : 'Gider',
                  item.category.isNotEmpty ? item.category : 'Diğer',
                  (item.paymentMethod != null && item.paymentMethod!.isNotEmpty)
                      ? item.paymentMethod!
                      : 'Nakit',
                  formattedAmount,
                  (item.description != null && item.description!.isNotEmpty)
                      ? item.description!
                      : (item.title.isNotEmpty ? item.title : '-'),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // 5. PDF baytlarını oluştur ve geçici dosyaya yaz
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final timeStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'gelir_gider_raporu_$timeStr.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // 6. Cihazın yerel paylaşım / yazdırma penceresini aç
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      debugPrint("[PDF EXPORT] Printing.sharePdf hatası, Share.shareXFiles deneniyor: $e");
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: fileName,
          ),
        );
      } catch (shareErr) {
        debugPrint("[PDF EXPORT] Share.shareXFiles hatası: $shareErr");
        rethrow;
      }
    }

    return file;
  }

  /// AppTransaction listesini TransactionModel listesine dönüştürüp PDF üretir.
  static Future<File> exportAndShareFromAppTransactions({
    required List<AppTransaction> appTransactions,
    required DateTimeRange dateRange,
    required String userEmail,
  }) async {
    final transactions = appTransactions
        .map((at) => TransactionModel.fromAppTransaction(at))
        .toList();

    return exportAndSharePdf(
      transactions: transactions,
      dateRange: dateRange,
      userEmail: userEmail,
    );
  }
}
