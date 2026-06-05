import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_management/core/utils/formatters.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _filterStatus = 'all';
  late final Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                    'all',
                    'pending',
                    'confirmed',
                    'processing',
                    'ready',
                    'delivered',
                    'cancelled',
                  ].map((status) {
                    final isSelected = _filterStatus == status;
                    return GestureDetector(
                      onTap: () => setState(() => _filterStatus = status),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status == 'all'
                              ? 'All Orders'
                              : status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              var orders = snapshot.data?.docs ?? [];

              if (_filterStatus != 'all') {
                orders = orders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'pending') == _filterStatus;
                }).toList();
              }

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filterStatus == 'all'
                            ? 'No orders yet'
                            : 'No $_filterStatus orders',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _orderCard(context, doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _orderCard(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) {
    final status = data['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final items = List<Map<String, dynamic>>.from(
      data['items'] ?? data['cartItems'] ?? [],
    );
    final total = (data['total'] ?? data['totalAmount'] ?? 0).toDouble();
    final deliveryMethod = data['deliveryMethod'] ?? 'pickup';
    final createdAt = data['createdAt'];

    String dateStr = 'Just now';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      dateStr =
          '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                _statusBadge(status),
              ],
            ),

            const Divider(height: 20),

            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  data['customerName'] ??
                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  data['phone'] ?? 'N/A',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  deliveryMethod == 'delivery'
                      ? Icons.local_shipping_outlined
                      : Icons.store_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  deliveryMethod == 'delivery'
                      ? 'Home Delivery — ${data['address'] ?? ''}'
                      : 'Store Pickup',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['name']} × ${item['qty']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      formatMoney(
                        ((item['price'] as num).toDouble()) *
                            ((item['qty'] as num).toDouble()),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${formatMoney(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                _statusActions(context, orderId, status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusActions(BuildContext context, String orderId, String status) {
    final nextStatus = _getNextStatus(status);
    if (nextStatus == null) return const SizedBox.shrink();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _statusColor(nextStatus),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _updateOrderStatus(context, orderId, nextStatus),
      child: Text(
        _getStatusActionLabel(nextStatus),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    String orderId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${newStatus.toUpperCase()}'),
            backgroundColor: _statusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String? _getNextStatus(String current) {
    const flow = {
      'pending': 'confirmed',
      'confirmed': 'processing',
      'processing': 'ready',
      'ready': 'delivered',
    };
    return flow[current];
  }

  String _getStatusActionLabel(String status) {
    switch (status) {
      case 'confirmed':
        return '✓ Confirm';
      case 'processing':
        return '⚙️ Process';
      case 'ready':
        return '📦 Mark Ready';
      case 'delivered':
        return '✅ Delivered';
      default:
        return 'Update';
    }
  }
}
