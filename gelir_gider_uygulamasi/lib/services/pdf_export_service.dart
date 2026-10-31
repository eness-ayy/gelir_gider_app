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
  /// PDF Raporunu kurumsal, modern ve eksiksiz bir finansal ekstre olarak oluşturur,
  /// geçici dizine kaydeder ve yerel paylaşım/yazdırma ekranını açar.
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
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: 'TL',
      decimalDigits: 2,
    );

    // 3. Finansal Hesaplamalar ve İstatistikler
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    int incomeCount = 0;
    int expenseCount = 0;
    int transferCount = 0;

    // Kategori bazlı harcama dağılımı (Giderler)
    final Map<String, double> categoryExpenseMap = {};
    // Ödeme yöntemi bazlı dağılım (Tüm işlemler)
    final Map<String, double> paymentMethodMap = {};

    for (final t in transactions) {
      final rawDesc = (t.description ?? t.title).trim();
      final isTransfer = rawDesc.startsWith('[TRANSFER:') ||
          t.category.toLowerCase() == 'transfer';

      if (isTransfer) {
        transferCount++;
        continue;
      }

      final isIncome = t.type.toLowerCase() == 'gelir' ||
          t.type.toLowerCase() == 'income';

      if (isIncome) {
        totalIncome += t.amount;
        incomeCount++;
      } else {
        totalExpense += t.amount;
        expenseCount++;

        // Kategori toplamı
        final catName = t.category.isNotEmpty ? t.category : 'Diğer';
        categoryExpenseMap[catName] =
            (categoryExpenseMap[catName] ?? 0.0) + t.amount;

        // Ödeme yöntemi toplamı (Giderler için)
        final pMethod = (t.paymentMethod != null && t.paymentMethod!.isNotEmpty)
            ? t.paymentMethod!
            : 'Nakit';
        paymentMethodMap[pMethod] =
            (paymentMethodMap[pMethod] ?? 0.0) + t.amount;
      }
    }

    final double netBalance = totalIncome - totalExpense;
    final double savingsRate = totalIncome > 0
        ? ((netBalance / totalIncome) * 100).clamp(-100.0, 100.0)
        : 0.0;

    // En çok harcama yapılan ilk 4 kategori
    final sortedCategories = categoryExpenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(4).toList();

    // Renk Paleti (Modern Fintech Stili)
    const brandColor = PdfColor.fromInt(0xFF0F172A); // Koyu Lacivert / Slate 900
    const primaryColor = PdfColor.fromInt(0xFF2563EB); // Royal Blue
    const primaryBg = PdfColor.fromInt(0xFFEFF6FF);

    const incomeColor = PdfColor.fromInt(0xFF059669); // Zümrüt Yeşili
    const incomeBgColor = PdfColor.fromInt(0xFFECFDF5);
    const incomeBorderColor = PdfColor.fromInt(0xFFA7F3D0);

    const expenseColor = PdfColor.fromInt(0xFFDC2626); // Kırmızı
    const expenseBgColor = PdfColor.fromInt(0xFFFEF2F2);
    const expenseBorderColor = PdfColor.fromInt(0xFFFECACA);

    final netColor = netBalance >= 0 ? incomeColor : expenseColor;
    final netBgColor = netBalance >= 0 ? incomeBgColor : expenseBgColor;
    final netBorderColor =
        netBalance >= 0 ? incomeBorderColor : expenseBorderColor;

    const rateColor = PdfColor.fromInt(0xFF7C3AED); // Mor / Tasarruf
    const rateBgColor = PdfColor.fromInt(0xFFF5F3FF);
    const rateBorderColor = PdfColor.fromInt(0xFFDDD6FE);

    final reportRefId =
        "HSP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

    // 4. PDF Sayfa Düzeni (MultiPage)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: [regularFont, boldFont],
        ),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Sol: Logo & Marka Başlığı
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 38,
                          height: 38,
                          decoration: pw.BoxDecoration(
                            color: brandColor,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'H',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 22,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text(
                                  'HESAPLY',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 18,
                                    color: brandColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                pw.SizedBox(width: 6),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: primaryBg,
                                    borderRadius: pw.BorderRadius.circular(4),
                                    border: pw.Border.all(
                                      color: primaryColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: pw.Text(
                                    'RESMİ RAPOR',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7.5,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Finansal Hesap Özeti & İşlem Dökümü',
                              style: pw.TextStyle(
                                font: mediumFont,
                                fontSize: 9.5,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Sağ: Rapor Meta Bilgileri
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Rapor No: $reportRefId',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8.5,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Tarih: ${dateTimeFormat.format(DateTime.now())}',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Kullanıcı: ${userEmail.isNotEmpty ? userEmail : "Belirtilmedi"}',
                          style: pw.TextStyle(
                            font: mediumFont,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(
                              color: PdfColors.grey300,
                              width: 0.5,
                            ),
                          ),
                          child: pw.Text(
                            'Dönem: ${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8,
                              color: brandColor,
                            ),
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
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Hesaply Kişisel Finans Asistanı • Bu belge kişisel mali veriler içermektedir.',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // =================================================================
            // 1. FİNANSAL KPI ÖZET KARTLARI (4 KUTU)
            // =================================================================
            pw.Row(
              children: [
                // Toplam Gelir
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(9),
                    decoration: pw.BoxDecoration(
                      color: incomeBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: incomeBorderColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOPLAM GELİR',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: incomeColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          currencyFormat.format(totalIncome),
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12.5,
                            color: incomeColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '$incomeCount adet gelir işlemi',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 7.5,
                            color: incomeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Toplam Gider
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(9),
                    decoration: pw.BoxDecoration(
                      color: expenseBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border:
                          pw.Border.all(color: expenseBorderColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOPLAM GİDER',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: expenseColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          currencyFormat.format(totalExpense),
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12.5,
                            color: expenseColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '$expenseCount adet gider işlemi',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 7.5,
                            color: expenseColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Net Bakiye
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(9),
                    decoration: pw.BoxDecoration(
                      color: netBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: netBorderColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NET DURUM',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: netColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${netBalance >= 0 ? "+" : ""}${currencyFormat.format(netBalance)}',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12.5,
                            color: netColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          netBalance >= 0 ? 'Bütçe Fazlası' : 'Bütçe Açığı',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 7.5,
                            color: netColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Tasarruf Oranı / Bütçe Verimliliği
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(9),
                    decoration: pw.BoxDecoration(
                      color: rateBgColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: rateBorderColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TASARRUF ORANI',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: rateColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          totalIncome > 0
                              ? '%${savingsRate.toStringAsFixed(1)}'
                              : '-',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12.5,
                            color: rateColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          totalIncome > 0
                              ? (savingsRate >= 0 ? 'Gelir Tasarrufu' : 'Aşım Var')
                              : 'Gelir Kaydı Yok',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 7.5,
                            color: rateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // =================================================================
            // 2. KATEGORİ VE ÖDEME YÖNTEMİ DAĞILIMI (GÖRSEL ÖZET)
            // =================================================================
            if (topCategories.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 14),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Sol: En Çok Harcama Yapılan Kategoriler
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'EN ÇOK HARCAMA YAPILAN KATEGORİLER',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8.5,
                              color: brandColor,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...topCategories.map((entry) {
                            final percent = totalExpense > 0
                                ? (entry.value / totalExpense)
                                : 0.0;
                            final percentStr =
                                (percent * 100).toStringAsFixed(1);
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        entry.key,
                                        style: pw.TextStyle(
                                          font: mediumFont,
                                          fontSize: 8,
                                          color: PdfColors.grey800,
                                        ),
                                      ),
                                      pw.Text(
                                        '${currencyFormat.format(entry.value)} (%$percentStr)',
                                        style: pw.TextStyle(
                                          font: boldFont,
                                          fontSize: 8,
                                          color: expenseColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 2),
                                  // İlerleme Çubuğu
                                  pw.Stack(
                                    children: [
                                      pw.Container(
                                        height: 4,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey200,
                                          borderRadius:
                                              pw.BorderRadius.circular(2),
                                        ),
                                      ),
                                      pw.Container(
                                        height: 4,
                                        width: 250 * percent.clamp(0.01, 1.0),
                                        decoration: pw.BoxDecoration(
                                          color: expenseColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),

                    // Dikey Ayraç
                    pw.Container(
                      width: 0.5,
                      height: 80,
                      color: PdfColors.grey300,
                    ),
                    pw.SizedBox(width: 16),

                    // Sağ: Ödeme Yöntemleri Dağılımı
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ÖDEME YÖNTEMLERİ DAĞILIMI',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8.5,
                              color: brandColor,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...paymentMethodMap.entries.map((entry) {
                            final percent = totalExpense > 0
                                ? (entry.value / totalExpense * 100)
                                : 0.0;
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    entry.key,
                                    style: pw.TextStyle(
                                      font: regularFont,
                                      fontSize: 8,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                  pw.Text(
                                    '${currencyFormat.format(entry.value)} (%${percent.toStringAsFixed(0)})',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 8,
                                      color: brandColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (transferCount > 0) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '+ $transferCount adet hesap transferi yapıldı',
                              style: pw.TextStyle(
                                font: regularFont,
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // =================================================================
            // 3. İŞLEM LİSTESİ TABLOSU
            // =================================================================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DETAYLI İŞLEM GEÇMİŞİ',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: brandColor,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  'Toplam ${transactions.length} işlem kaydı bulundu',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 30),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Seçilen tarih aralığında herhangi bir işlem kaydı bulunamadı.',
                  style: pw.TextStyle(
                    font: mediumFont,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: const pw.TableBorder(
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                ),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: brandColor,
                ),
                headerPadding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 6,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 6,
                ),
                cellStyle: pw.TextStyle(
                  font: regularFont,
                  fontSize: 7.8,
                  color: PdfColors.grey900,
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC), // Slate 50 zebra rengi
                ),
                headers: <String>[
                  'Tarih',
                  'Tür',
                  'Kategori',
                  'Ödeme Yöntemi',
                  'Açıklama',
                  'Tutar',
                ],
                columnWidths: const {
                  0: pw.FixedColumnWidth(54), // Tarih
                  1: pw.FixedColumnWidth(44), // Tür
                  2: pw.FixedColumnWidth(76), // Kategori
                  3: pw.FixedColumnWidth(66), // Ödeme Yöntemi
                  4: pw.FlexColumnWidth(1), // Açıklama
                  5: pw.FixedColumnWidth(74), // Tutar
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                },
                data: transactions.map((item) {
                  final rawText = (item.description != null &&
                          item.description!.isNotEmpty)
                      ? item.description!.trim()
                      : (item.title.isNotEmpty ? item.title.trim() : '-');
                  final transferMatch =
                      RegExp(r'^\[TRANSFER:(.*?):(.*?)\]\s*(.*)$')
                          .firstMatch(rawText);
                  final isTransfer = transferMatch != null ||
                      item.category.toLowerCase() == 'transfer';

                  String cleanDesc = rawText
                      .replaceAll(RegExp(r'\s*\[(GRP_STL|SHR_STL):.*?\]'), '')
                      .trim();
                  if (isTransfer && transferMatch != null) {
                    final tDesc = transferMatch.group(3)?.trim() ?? '';
                    cleanDesc =
                        tDesc.isNotEmpty ? tDesc : 'Hesaplar Arası Transfer';
                  } else if (!isTransfer) {
                    final grpMatch =
                        RegExp(r'^\[(.*?)\]\s*(.*)$').firstMatch(cleanDesc);
                    if (grpMatch != null) {
                      final headerParts =
                          (grpMatch.group(1) ?? '').split('|');
                      final grpName = headerParts.first.trim();
                      final expTitle = grpMatch.group(2)?.trim() ?? '';
                      cleanDesc = grpName.isNotEmpty
                          ? '[$grpName] $expTitle'
                          : expTitle;
                    }
                  }

                  final isIncome = item.type.toLowerCase() == 'gelir' ||
                      item.type.toLowerCase() == 'income';
                  final sign = isTransfer ? '' : (isIncome ? '+ ' : '- ');
                  final formattedAmount =
                      '$sign${currencyFormat.format(item.amount)}';

                  return <String>[
                    dateFormat.format(item.date),
                    isTransfer ? 'Transfer' : (isIncome ? 'Gelir' : 'Gider'),
                    isTransfer
                        ? 'Transfer'
                        : (item.category.isNotEmpty ? item.category : 'Diğer'),
                    (item.paymentMethod != null &&
                            item.paymentMethod!.isNotEmpty)
                        ? item.paymentMethod!
                        : 'Nakit',
                    cleanDesc.isNotEmpty ? cleanDesc : '-',
                    formattedAmount,
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
    final fileName = 'hesaply_mali_rapor_$timeStr.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // 6. Cihazın yerel paylaşım / yazdırma penceresini aç
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      debugPrint(
          "[PDF EXPORT] Printing.sharePdf hatası, Share.shareXFiles deneniyor: $e");
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
