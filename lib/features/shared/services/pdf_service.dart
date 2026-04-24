import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../order/models/order.dart';

class PdfService {
  static final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

  static Future<void> generateAndOpenInvoice(OrderModel order) async {
    final pdf = pw.Document();

    final invoiceId = order.orderId;
    final txnDigits = order.orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final shortTxn = txnDigits.length >= 4 ? txnDigits.substring(txnDigits.length - 4) : (txnDigits.isNotEmpty ? txnDigits : '0000');
    final transactionId = 'TXN-$shortTxn';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.Text(invoiceId, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PT Kinarya Agung Prima', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Official Store', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Info Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Diterbitkan Untuk:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(order.fullName, style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text('Alamat Pengiriman:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(order.shippingAddress, style: const pw.TextStyle(fontSize: 10), maxLines: 3),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Detail Pesanan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Row(
                          children: [
                            pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Spacer(),
                            pw.Text(order.createdAt != null ? dateFormat.format(order.createdAt!) : '-', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Text('Metode Pembayaran:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Spacer(),
                            pw.Text(order.paymentMethod, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Text('Status:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Spacer(),
                            pw.Text(order.status, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: order.status == 'Paid' || order.status == 'Delivered' ? PdfColors.green : PdfColors.orange)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text('ID Transaksi:', style: const pw.TextStyle(fontSize: 9)),
                            pw.Spacer(),
                            pw.Text(transactionId, style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Nama Produk', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Harga Satuan', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Subtotal', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ],
                  ),
                  // Table Items
                  ...order.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.title, style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.quantity.toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(item.price), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(item.price * item.quantity), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                children: [
                  pw.Spacer(flex: 2),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        _buildTotalRow('Subtotal', currencyFormat.format(order.subtotal)),
                        _buildTotalRow('Pajak (11%)', currencyFormat.format(order.tax)),
                        _buildTotalRow('Biaya Pengiriman', order.shippingCost == 0 ? 'Gratis' : currencyFormat.format(order.shippingCost)),
                        pw.Divider(color: PdfColors.grey300),
                        _buildTotalRow('Total Belanja', currencyFormat.format(order.total), isBold: true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Terima kasih telah berbelanja di PT Kinarya Agung Prima.\nSimpan invoice ini sebagai bukti transaksi yang sah.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save and Open
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_${order.orderId}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
