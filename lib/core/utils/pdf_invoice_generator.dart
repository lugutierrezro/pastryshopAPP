import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pastryshop/domain/entities/entities.dart';

class PdfInvoiceGenerator {
  static Future<void> generateAndShow(OrderEntity order) async {
    final pdf = pw.Document();

    final isFactura = order.tipoComprobante.toLowerCase() == 'factura';
    final docTitle = isFactura ? 'FACTURA ELECTRÓNICA' : 'BOLETA ELECTRÓNICA';
    final docNum = '001-${order.id.toString().padLeft(6, '0')}';
    
    // Configuración de formatos
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currency = NumberFormat.currency(symbol: 'S/ ');

    // Construcción del documento
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('La Pastelería', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                  pw.SizedBox(height: 4),
                  pw.Text('Av. Principal 123, Lima, Perú', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('RUC: 20123456789', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Tel: +51 987 654 321', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.deepPurple, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('RUC: 20123456789', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text(docTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 8),
                    pw.Text('N° $docNum', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Customer Info
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Cliente:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(order.cliente ?? 'Cliente Final', style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 4),
                    pw.Text(isFactura ? 'RUC: ${order.documentoCliente}' : 'DNI: ${order.documentoCliente.isNotEmpty ? order.documentoCliente : "No especificado"}', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text('Tipo Entrega: ${order.tipoEntrega.toUpperCase()}', style: const pw.TextStyle(fontSize: 12)),
                    if (order.tipoEntrega == 'domicilio')
                      pw.Text('Dirección: ${order.direccionEntrega}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Fecha de Emisión:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(order.createdAt, style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 4),
                    pw.Text('Estado del Pedido:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(order.estado.toUpperCase(), style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Items Table
          pw.Table.fromTextArray(
            headers: ['Cant.', 'Descripción', 'P. Unitario', 'Subtotal'],
            data: order.items.map((item) => [
              item.cantidad.toString(),
              item.producto,
              currency.format(item.precioUnit),
              currency.format(item.subtotal),
            ]).toList(),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildTotalRow('OP. GRAVADAS:', currency.format(order.total / 1.18)),
                    _buildTotalRow('IGV (18%):', currency.format(order.total - (order.total / 1.18))),
                    pw.Divider(),
                    _buildTotalRow('TOTAL A PAGAR:', currency.format(order.total), isBold: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // QR Code
          pw.Center(
            child: pw.Column(
              children: [
                pw.SizedBox(
                  height: 100,
                  width: 100,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: '20123456789|${isFactura ? '01' : '03'}|$docNum|${order.total - (order.total / 1.18)}|${order.total}|${order.createdAt.split(' ').first}|${isFactura ? '6' : '1'}|${order.documentoCliente}',
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Representación impresa de la $docTitle', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Puede verificar la validez de este documento en el portal de SUNAT.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Comprobante_$docNum',
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
