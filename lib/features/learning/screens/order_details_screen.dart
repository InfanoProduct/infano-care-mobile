import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/learning/repositories/learning_repository.dart';
import 'package:infano_care_mobile/features/learning/screens/payments_and_orders_screens.dart';

class MyOrderDetailsScreen extends StatefulWidget {
  const MyOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.storage,
  });

  final String orderId;
  final LocalStorageService storage;

  @override
  State<MyOrderDetailsScreen> createState() => _MyOrderDetailsScreenState();
}

class _MyOrderDetailsScreenState extends State<MyOrderDetailsScreen> {
  late final LearningRepository _repository;
  late Future<dynamic> _orderFuture;

  @override
  void initState() {
    super.initState();
    _repository = LearningRepository(ApiService.instance.dio);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _orderFuture = _repository.getMyBookOrders().then((orders) {
        return orders.firstWhere(
          (o) => o != null && o['id'].toString() == widget.orderId,
          orElse: () => null,
        );
      });
    });
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMMM, yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  bool _isProgramItem(dynamic item) {
    if (item == null) return false;
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
          'Order Details',
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
      body: FutureBuilder<dynamic>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.purple));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.hasError ? 'Failed to load order details.' : 'Order not found.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
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

          final order = snapshot.data;
          final orderIdStr = (order['id'] ?? '').toString();
          final orderDisplayId = orderIdStr.length > 8 ? orderIdStr.substring(0, 8) : orderIdStr;
          final orderDate = order['createdAt'] ?? '';
          final orderStatus = (order['orderStatus'] ?? 'PLACED').toString().toUpperCase();
          final paymentStatus = (order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
          final totalAmount = order['totalAmount'] ?? 0;
          final subtotal = order['subtotal'] ?? 0;
          final discountAmount = order['discountAmount'] ?? 0;
          final taxableAmount = order['taxableAmount'] ?? 0;
          final gstAmount = order['gstAmount'] ?? 0;
          final items = order['items'] as List<dynamic>? ?? [];

          final productItems = items.where((it) => !_isProgramItem(it)).toList();

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _orderFuture;
            },
            child: ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              children: [
                // 1. Order Status Header
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #$orderDisplayId',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => InvoicePdfHelper.generateAndPrintInvoice(type: 'BOOK', data: order),
                              icon: const Icon(Icons.download, size: 14, color: AppColors.purple),
                              label: const Text('Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5F3FF),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                minimumSize: const Size(0, 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(orderDate),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Summary of Items
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                        child: Text(
                          'Order Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                      ),
                      const Divider(height: 24),
                      ...productItems.map((it) {
                        final book = it['book'] ?? {};
                        final title = book['title'] ?? it['bookTitle'] ?? it['name'] ?? 'Book Product';
                        final desc = book['description'] ?? '';
                        final imageUrl = book['imageUrl'] ?? '';
                        final price = it['price'] ?? 0;
                        final qty = it['quantity'] ?? 1;

                        return Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 75,
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        desc,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Qty: $qty',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                        ),
                                        Text(
                                          '₹$price',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                  ),
                ),

                // 3. Horizontal Delivery Progress Tracker
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 24),
                        // Bounded and Layout-safe Tracker
                        _buildProgressTracker(orderStatus),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            orderStatus == 'PLACED'
                                ? "Your items are securely confirmed."
                                : orderStatus == 'PROCESSING'
                                    ? "We're packing your order carefully."
                                    : orderStatus == 'SHIPPED'
                                        ? "Your package is on its way!"
                                        : orderStatus == 'DELIVERED'
                                            ? "Enjoy your purchase!"
                                            : "Your items are being processed securely.",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Payment Details Table
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment Summary',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Subtotal', '₹$subtotal'),
                        if (discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow('Discount', '-₹$discountAmount', isDiscount: true),
                        ],
                        const SizedBox(height: 8),
                        _buildSummaryRow('Taxable Value', '₹$taxableAmount'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('GST (5%)', '₹$gstAmount'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                            Text(
                              '₹$totalAmount',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.purple),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: paymentStatus == 'COMPLETED' ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                paymentStatus,
                                style: TextStyle(
                                  color: paymentStatus == 'COMPLETED' ? Colors.green : Colors.amber[800],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Shipping Coordinates
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            const Text(
                              'Shipping Coordinates',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${order['guestName'] ?? 'Customer'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order['shippingAddress'] ?? ''}\n${order['city'] ?? ''}, ${order['state'] ?? ''} - ${order['pincode'] ?? ''}',
                          style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${order['guestPhone'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker(String status) {
    final steps = ['PLACED', 'PROCESSING', 'SHIPPED', 'DELIVERED'];
    int currentIndex = steps.indexOf(status);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final stepCount = steps.length;
          final segmentWidth = (totalWidth - 32) / (stepCount - 1);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Line Background
              Positioned(
                left: 16,
                right: 16,
                top: 14,
                child: Container(
                  height: 3,
                  color: Colors.grey[200] ?? const Color(0xFFEEEEEE),
                ),
              ),
              // Line Active Progress
              Positioned(
                left: 16,
                top: 14,
                child: Container(
                  width: segmentWidth * currentIndex,
                  height: 3,
                  color: Colors.green,
                ),
              ),
              // Nodes
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(stepCount, (idx) {
                    final step = steps[idx];
                    final isCompleted = idx <= currentIndex;
                    final isActive = idx == currentIndex;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted ? Colors.green : (Colors.grey[300] ?? const Color(0xFFE0E0E0)),
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300] ?? const Color(0xFFE0E0E0),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : (isCompleted ? AppColors.textDark : AppColors.textLight),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
