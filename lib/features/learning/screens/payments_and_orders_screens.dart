import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/learning/repositories/learning_repository.dart';

class InvoicePdfHelper {
  static Future<void> generateAndPrintInvoice({
    required String type,
    required dynamic data,
  }) async {
    final pdf = pw.Document();

    final ByteData logoData = await rootBundle.load('assets/logo.png');
    final pw.MemoryImage logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final rawId = (data?['id'] ?? '').toString();
    final suffix = rawId.length > 6 ? rawId.substring(rawId.length - 6) : rawId;
    final invoiceNo = type == 'PROGRAM'
        ? 'INF-PRG-${suffix.toUpperCase()}'
        : 'INF-BOK-${suffix.toUpperCase()}';

    final invoiceDate = DateFormat('d MMMM, yyyy').format(
      DateTime.tryParse(data?['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
    );

    final buyerName = type == 'PROGRAM'
        ? (data?['guestName'] ?? data?['user']?['profile']?['displayName'] ?? data?['user']?['username'] ?? 'Customer')
        : (data?['guestName'] ?? 'Customer');

    final buyerPhone = type == 'PROGRAM'
        ? (data?['user']?['phone'] ?? 'N/A')
        : (data?['guestPhone'] ?? 'N/A');

    final buyerEmail = type == 'PROGRAM'
        ? (data?['guestEmail'] ?? data?['user']?['parentEmail'] ?? 'N/A')
        : (data?['guestEmail'] ?? 'N/A');

    final billingAddress = type == 'BOOK'
        ? '${data?['shippingAddress'] ?? ''}, ${data?['city'] ?? ''}, ${data?['state'] ?? ''} - ${data?['pincode'] ?? ''}'
        : 'Online Mentoring Service';

    final paymentMethod = type == 'PROGRAM'
        ? 'Razorpay (ONLINE)'
        : (data?['paymentMethod'] ?? 'ONLINE');

    // GST logic
    double subtotal = 0;
    double cgstTotal = 0;
    double sgstTotal = 0;
    double grandTotal = 0;

    List<Map<String, dynamic>> itemsList = [];

    if (type == 'PROGRAM') {
      final pricePaid = double.tryParse((data?['pricePaid'] ?? data?['price'] ?? 0).toString()) ?? 0.0;
      final taxableVal = pricePaid / 1.18;
      final gstAmt = pricePaid - taxableVal;
      final cgstAmt = gstAmt / 2;
      final sgstAmt = gstAmt / 2;

      itemsList.add({
        'name': '${data?['program']?['title'] ?? 'Infano Mentoring'} Program Enrollment',
        'hsn': '999299',
        'qty': 1,
        'rate': taxableVal,
        'taxableVal': taxableVal,
        'cgstRate': 9.0,
        'cgstAmt': cgstAmt,
        'sgstRate': 9.0,
        'sgstAmt': sgstAmt,
        'total': pricePaid,
      });

      subtotal = taxableVal;
      cgstTotal = cgstAmt;
      sgstTotal = sgstAmt;
      grandTotal = pricePaid;
    } else {
      final discountAmt = double.tryParse((data?['discountAmount'] ?? 0).toString()) ?? 0.0;
      final orderSubtotal = double.tryParse((data?['subtotal'] ?? 0).toString()) ?? 0.0;
      final rawItems = data?['items'] as List<dynamic>? ?? [];

      for (var item in rawItems) {
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final itemTotal = price * qty;
        final itemDiscount = orderSubtotal > 0 ? (itemTotal / orderSubtotal) * discountAmt : 0.0;
        final finalItemTotal = itemTotal - itemDiscount;

        // Is program
        final book = item['book'] ?? {};
        final bookId = (item['bookId'] ?? '').toString().toLowerCase();
        final bookTitle = (book['title'] ?? item['bookTitle'] ?? '').toString().toLowerCase();
        final isProg = book['curriculum'] != null ||
            bookId.contains('program') ||
            bookTitle.contains('program') ||
            bookTitle.contains('mentoring');

        final taxRate = isProg ? 0.18 : 0.05;
        final gstPercent = isProg ? 18.0 : 5.0;

        final taxableVal = finalItemTotal / (1 + taxRate);
        final gstAmt = finalItemTotal - taxableVal;
        final cgstAmt = gstAmt / 2;
        final sgstAmt = gstAmt / 2;

        itemsList.add({
          'name': book['title'] ?? item['bookTitle'] ?? item['name'] ?? 'Product',
          'hsn': isProg ? '999299' : '4901',
          'qty': qty,
          'rate': price / (1 + taxRate),
          'taxableVal': taxableVal,
          'cgstRate': gstPercent / 2,
          'cgstAmt': cgstAmt,
          'sgstRate': gstPercent / 2,
          'sgstAmt': sgstAmt,
          'total': finalItemTotal,
        });

        subtotal += taxableVal;
        cgstTotal += cgstAmt;
        sgstTotal += sgstAmt;
        grandTotal += finalItemTotal;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header matching Web styling
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 32,
                        child: pw.Image(logoImage),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('infano.care', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1C1917))),
                      pw.SizedBox(height: 2),
                      pw.Text('Empowering adolescent girls, one family at a time.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 6),
                      pw.Text('GSTIN: 29AAFCI8765A1Z2', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text('Bengaluru, Karnataka, India • connect@infano.care', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFECFDF5),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text('TAX INVOICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromInt(0xFF047857))),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Invoice Number', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoiceNo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, font: pw.Font.courier())),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice Date', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoiceDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 24, color: PdfColors.grey300),
              
              // Billing & Shipping
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey500)),
                        pw.SizedBox(height: 4),
                        pw.Text(buyerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text('Phone: $buyerPhone', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Email: $buyerEmail', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIPPING & BILLING ADDRESS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey500)),
                        pw.SizedBox(height: 4),
                        pw.Text(billingAddress, style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 6),
                        pw.Text('Payment Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey500)),
                        pw.Text(paymentMethod.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Items Table matching Web
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
                  top: pw.BorderSide(color: PdfColors.grey400, width: 1),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(0.5),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(1),
                  7: const pw.FlexColumnWidth(1.2),
                  8: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('HSN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Taxable Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('CGST %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('CGST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SGST %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SGST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...itemsList.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['hsn'], style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['qty'].toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs ${item['rate'].toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item['cgstRate']}%', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs ${item['cgstAmt'].toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item['sgstRate']}%', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs ${item['sgstAmt'].toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs ${item['total'].toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              // Totals Card Block matching Web
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Taxable Value:', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Rs ${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('CGST Total:', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Rs ${cgstTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('SGST Total:', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Rs ${sgstTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8)),
                          ],
                        ),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey300, height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text('Rs ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromInt(0xFF4A1E7F))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 0.5, color: PdfColor.fromInt(0xFFD1D5DB)),
              pw.SizedBox(height: 12),

              // Declaration and Signatory Block
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DECLARATION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.grey600)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'We declare that this invoice shows the actual price of the goods or services described and that all particulars are true and correct. This is a computer-generated tax invoice and does not require a physical signature.',
                          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 48),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Authorized Signatory for', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text('infano.care', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 16),
                      pw.Text('Computer Generated Invoice', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice-$invoiceNo.pdf',
    );
  }
}

class MyPaymentsScreen extends StatefulWidget {
  const MyPaymentsScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> {
  late final LearningRepository _repository;
  late Future<List<dynamic>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _repository = LearningRepository(ApiService.instance.dio);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _paymentsFuture = Future.wait([
        _repository.getMyProgramEnrollments(),
        _repository.getMyBookOrders(),
      ]);
    });
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMM, yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        title: const Text(
          'Payment Details',
          style: TextStyle(
            color: AppColors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.purple),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await _paymentsFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: _paymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return _ErrorState(
                errorMessage: snapshot.hasError
                    ? 'Failed to load payment data.\n${snapshot.error}'
                    : 'No payment data found.',
                onRetry: _loadData,
              );
            }

            final dataList = snapshot.data!;
            final enrollments = (dataList.isNotEmpty ? dataList[0] : []) as List<dynamic>? ?? [];
            final orders = (dataList.length > 1 ? dataList[1] : []) as List<dynamic>? ?? [];

            if (enrollments.isEmpty && orders.isEmpty) {
              return const _EmptyState(
                icon: Icons.credit_card,
                title: 'No Transactions Found',
                subtitle: 'You haven\'t made any purchases yet.',
              );
            }

            return ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              children: [
                // 1. Program Enrollments
                if (enrollments.isNotEmpty) ...[
                  const Text(
                    'Program Enrollments',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  ...enrollments.map((enr) {
                    final prog = enr['program'] ?? {};
                    final pricePaid = enr['pricePaid'] ?? enr['price'] ?? 0;
                    final registrationId = enr['id'] ?? '';
                    final datePaid = enr['createdAt'] ?? '';
                    final status = enr['status'] ?? 'ACTIVE';

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Web-styled Purple Border
                          Container(height: 4, color: AppColors.purple),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '1:1 Private Mentoring',
                                        style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(datePaid),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${prog['title'] ?? 'Program'} Program',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹$pricePaid',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const Text(
                                          'Paid successfully',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, thickness: 0.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'REGISTRATION ID',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          registrationId.toString().length > 12 
                                              ? '${registrationId.toString().substring(0, 12)}...' 
                                              : registrationId.toString(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ENROLLMENT STATUS',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified, size: 12, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text(
                                              status.toString().toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => InvoicePdfHelper.generateAndPrintInvoice(type: 'PROGRAM', data: enr),
                                      icon: const Icon(Icons.file_present, size: 12, color: AppColors.textDark),
                                      label: const Text('Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.textDark,
                                        elevation: 0,
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        minimumSize: const Size(0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // 2. Book Purchases
                if (orders.isNotEmpty) ...[
                  const Text(
                    'Book Purchases',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  ...orders.map((order) {
                    final orderId = order['id'] ?? '';
                    final totalAmount = order['totalAmount'] ?? 0;
                    final orderDate = order['createdAt'] ?? '';
                    final paymentStatus = order['paymentStatus'] ?? 'PENDING';
                    final orderStatus = order['orderStatus'] ?? 'PROCESSING';
                    final items = order['items'] as List<dynamic>? ?? [];

                    final itemsText = items.map((it) {
                      final book = it['book'] ?? {};
                      final title = book['title'] ?? it['bookTitle'] ?? it['name'] ?? 'Book';
                      return '$title (x${it['quantity']})';
                    }).join(', ');

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Web-styled Purple Border
                          Container(height: 4, color: AppColors.purple),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Gigi Book Order',
                                        style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(orderDate),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        itemsText.isEmpty ? 'Gigi Survival Book Order' : itemsText,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹$totalAmount',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          paymentStatus == 'COMPLETED' ? 'Paid successfully' : paymentStatus,
                                          style: TextStyle(
                                            color: paymentStatus == 'COMPLETED' ? Colors.green : Colors.amber[800],
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, thickness: 0.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ORDER ID',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          orderId.toString().length > 12 
                                              ? '${orderId.toString().substring(0, 12)}...' 
                                              : orderId.toString(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ORDER STATUS',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.purple),
                                            const SizedBox(width: 4),
                                            Text(
                                              orderStatus,
                                              style: const TextStyle(
                                                color: AppColors.textDark,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => InvoicePdfHelper.generateAndPrintInvoice(type: 'BOOK', data: order),
                                      icon: const Icon(Icons.file_present, size: 12, color: AppColors.textDark),
                                      label: const Text('Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.textDark,
                                        elevation: 0,
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        minimumSize: const Size(0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final LearningRepository _repository;
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _repository = LearningRepository(ApiService.instance.dio);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _ordersFuture = _repository.getMyBookOrders();
    });
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMM, yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  bool _isProgramItem(dynamic item) {
    final book = item['book'] ?? {};
    final bookId = (item['bookId'] ?? '').toString().toLowerCase();
    final bookTitle = (book['title'] ?? item['bookTitle'] ?? '').toString().toLowerCase();
    if (book['curriculum'] != null || book['classRange'] != null || book['duration'] != null) return true;
    if (bookId.contains('program') || bookId.contains('private') || bookId.contains('group') || bookId.contains('cohort')) return true;
    if (bookTitle.contains('program') || bookTitle.contains('mentoring') || bookTitle.contains('cohort')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: AppColors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.purple),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await _ordersFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }
            if (snapshot.hasError) {
              return _ErrorState(
                errorMessage: 'Failed to load orders.\n${snapshot.error}',
                onRetry: _loadData,
              );
            }

            final orders = snapshot.data ?? [];
            final productOrders = orders.where((o) {
              final items = o['items'] as List<dynamic>? ?? [];
              return items.any((it) => !_isProgramItem(it));
            }).toList();

            if (productOrders.isEmpty) {
              return const _EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'No Product Orders Found',
                subtitle: 'You haven\'t ordered any books or products yet.',
              );
            }

            return ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              children: [
                ...productOrders.map((order) {
                  final orderId = order['id'] ?? '';
                  final orderDate = order['createdAt'] ?? '';
                  final totalAmount = order['totalAmount'] ?? 0;
                  final paymentStatus = order['paymentStatus'] ?? 'PENDING';
                  final orderStatus = order['orderStatus'] ?? 'PROCESSING';
                  final items = order['items'] as List<dynamic>? ?? [];

                  final productItems = items.where((it) => !_isProgramItem(it)).toList();
                  final firstItem = productItems.isNotEmpty ? productItems[0] : null;
                  final book = firstItem != null ? firstItem['book'] ?? {} : {};
                  final imageUrl = book['imageUrl'] ?? firstItem?['bookTitle'] ?? '';

                  final orderTitle = productItems.map((it) {
                    final b = it['book'] ?? {};
                    final title = b['title'] ?? it['bookTitle'] ?? it['name'] ?? 'Product';
                    return '$title (x${it['quantity']})';
                  }).join(', ');

                  return GestureDetector(
                    onTap: () {
                      context.push('/order/$orderId');
                    },
                    child: Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Web-styled Purple Border
                          Container(height: 4, color: AppColors.purple),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Gigi Book Order',
                                        style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(orderDate),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Container(
                                       width: 50,
                                       height: 60,
                                       margin: const EdgeInsets.only(right: 12),
                                       decoration: BoxDecoration(
                                         color: Colors.grey[100],
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: Colors.grey[200] ?? const Color(0xFFEEEEEE)),
                                       ),
                                       child: imageUrl.toString().startsWith('http')
                                           ? ClipRRect(
                                               borderRadius: BorderRadius.circular(8),
                                               child: Image.network(
                                                 imageUrl.toString(),
                                                 fit: BoxFit.cover,
                                                 errorBuilder: (_, _, _) => const Icon(Icons.book, color: AppColors.textLight),
                                               ),
                                             )
                                           : const Icon(Icons.book, color: AppColors.textLight),
                                     ),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                             orderTitle.isEmpty ? 'Product Order' : orderTitle,
                                             style: const TextStyle(
                                               fontSize: 15,
                                               fontWeight: FontWeight.bold,
                                               color: AppColors.textDark,
                                             ),
                                           ),
                                           const SizedBox(height: 4),
                                           Row(
                                             children: [
                                               const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                                               const SizedBox(width: 2),
                                               Text(
                                                 order['city'] ?? 'N/A',
                                                 style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                               ),
                                             ],
                                           ),
                                         ],
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.end,
                                       children: [
                                         Text(
                                           '₹$totalAmount',
                                           style: const TextStyle(
                                             fontSize: 16,
                                             fontWeight: FontWeight.bold,
                                             color: AppColors.textDark,
                                           ),
                                         ),
                                         const SizedBox(height: 2),
                                         Text(
                                           paymentStatus == 'COMPLETED' ? 'Paid successfully' : paymentStatus,
                                           style: TextStyle(
                                             color: paymentStatus == 'COMPLETED' ? Colors.green : Colors.amber[800],
                                             fontSize: 9,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),
                                const Divider(height: 24, thickness: 0.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ORDER ID',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          orderId.toString().length > 12 
                                              ? '${orderId.toString().substring(0, 12)}...' 
                                              : orderId.toString(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ORDER STATUS',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.purple),
                                            const SizedBox(width: 4),
                                            Text(
                                              orderStatus,
                                              style: const TextStyle(
                                                color: AppColors.textDark,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Track Order',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, size: 12, color: AppColors.purple),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
