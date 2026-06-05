import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_management/core/utils/formatters.dart';
import 'package:shop_management/ui/widgets/payment/payment_show_widget.dart';

void showReceiptDialog(
  BuildContext context,
  Map<String, dynamic> receipt, {
  VoidCallback? onPaymentConfirmed,
  bool isReadOnly = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => ReceiptDialog(
      receipt: receipt,
      onPaymentConfirmed: onPaymentConfirmed,
      isReadOnly: isReadOnly,
    ),
  );
}

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final VoidCallback? onPaymentConfirmed;
  final bool isReadOnly;

  const ReceiptDialog({
    super.key,
    required this.receipt,
    this.onPaymentConfirmed,
    this.isReadOnly = false,
  });

  DateTime _parseReceiptDate(dynamic rawDate) {
    if (rawDate is DateTime) return rawDate;
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is Map<String, dynamic>) {
      final seconds = rawDate['_seconds'] ?? rawDate['seconds'];
      final nanoseconds =
          rawDate['_nanoseconds'] ?? rawDate['nanoseconds'] ?? rawDate['nanos'];
      if (seconds is int && nanoseconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanoseconds ~/ 1000000,
        );
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final items = receipt['items'] as List;
    final date = _parseReceiptDate(receipt['date']);
    final total = (receipt['total'] as num).toDouble();
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    "SALES RECEIPT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: ${receipt['id']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy  hh:mm a').format(date),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "Qty: ${item['qty']}  ×  ${formatMoney((item['price'] as num).toDouble())}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatMoney(
                                    (item['subtotal'] as num).toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatMoney(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  if (!isReadOnly)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showPaymentFlowDialog(
                            context,
                            totalAmount: total,
                            onPaymentComplete: (paymentMethod) async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('sales')
                                    .doc(receipt['id'])
                                    .update({'paymentMethod': paymentMethod});
                                onPaymentConfirmed?.call();
                                debugPrint(
                                  '✅ Payment complete: $paymentMethod',
                                );
                              } catch (e) {
                                debugPrint('Failed to save payment method: $e');
                              }
                            },
                          );
                        },
                        label: const Text("Confirm Payment"),
                      ),
                    ),
                  if (!isReadOnly) const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        "Close",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
