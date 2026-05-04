import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptPage({super.key, required this.receipt});

  DateTime _parseReceiptDate(dynamic rawDate) {
    if (rawDate is DateTime) return rawDate;
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is Map<String, dynamic>) {
      final seconds = rawDate['_seconds'] ?? rawDate['seconds'];
      final nanoseconds = rawDate['_nanoseconds'] ?? rawDate['nanoseconds'] ?? rawDate['nanos'];
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

    return Scaffold(
      appBar: AppBar(title: const Text("Receipt")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.receipt_long, size: 50),
            const SizedBox(height: 10),
            const Text(
              "SALES RECEIPT",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text("Receipt ID: ${receipt['id']}"),
            const SizedBox(height: 5),
            Text(DateFormat('dd MMM yyyy').format(date)),
            const Divider(height: 30),

            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text("Qty: ${item['qty']}"),
                    trailing: Text("₵${item['subtotal']}"),
                  );
                },
              ),
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "₵${receipt['total'].toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
