import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/sales_controller.dart';
import 'package:shop_management/core/models/sale_model.dart';
import 'package:shop_management/core/utils/formatters.dart';
import 'package:shop_management/ui/pages/reciept/reciept_page.dart';

class ReportsBody extends StatefulWidget {
  const ReportsBody({super.key});

  @override
  State<ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends State<ReportsBody> {
  String _filterMethod = 'all';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<Sale>>(
        stream: context.read<SalesController>().salesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No sales yet"));
          }

          final allSales = snapshot.data!;

          final sales = _filterMethod == 'all'
              ? allSales
              : allSales
                    .where((s) => s.paymentMethod == _filterMethod)
                    .toList();

          // ── totals ──
          final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.total);

          // ── payment method breakdown ──
          final cashSales = allSales
              .where((s) => s.paymentMethod == 'cash')
              .fold(0.0, (sum, s) => sum + s.total);
          final mobileSales = allSales
              .where((s) => s.paymentMethod == 'mobile_money')
              .fold(0.0, (sum, s) => sum + s.total);
          final cardSales = allSales
              .where((s) => s.paymentMethod == 'bank_card')
              .fold(0.0, (sum, s) => sum + s.total);
          final unpaidSales = allSales
              .where((s) => s.paymentMethod == null || s.paymentMethod!.isEmpty)
              .fold(0.0, (sum, s) => sum + s.total);

          final cashCount = allSales
              .where((s) => s.paymentMethod == 'cash')
              .length;
          final mobileCount = allSales
              .where((s) => s.paymentMethod == 'mobile_money')
              .length;
          final cardCount = allSales
              .where((s) => s.paymentMethod == 'bank_card')
              .length;
          final unpaidCount = allSales
              .where((s) => s.paymentMethod == null || s.paymentMethod!.isEmpty)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary cards ──
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: "Total Revenue",
                      value: formatMoney(totalRevenue),
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      title: "Transactions",
                      value: "${sales.length}",
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Payment method breakdown ──
              const Text(
                "Payment Breakdown",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // ✅ 4 payment method cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _paymentCard(
                      label: "Cash",
                      icon: Icons.payments_outlined,
                      color: Colors.green,
                      amount: cashSales,
                      count: cashCount,
                      isSelected: _filterMethod == 'cash',
                      onTap: () => setState(
                        () => _filterMethod = _filterMethod == 'cash'
                            ? 'all'
                            : 'cash',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _paymentCard(
                      label: "Mobile Money",
                      icon: Icons.phone_android,
                      color: Colors.yellow[700]!,
                      amount: mobileSales,
                      count: mobileCount,
                      isSelected: _filterMethod == 'mobile_money',
                      onTap: () => setState(
                        () => _filterMethod = _filterMethod == 'mobile_money'
                            ? 'all'
                            : 'mobile_money',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _paymentCard(
                      label: "Bank Card",
                      icon: Icons.credit_card,
                      color: Colors.blue,
                      amount: cardSales,
                      count: cardCount,
                      isSelected: _filterMethod == 'bank_card',
                      onTap: () => setState(
                        () => _filterMethod = _filterMethod == 'bank_card'
                            ? 'all'
                            : 'bank_card',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _paymentCard(
                      label: "Pending",
                      icon: Icons.hourglass_empty,
                      color: Colors.grey,
                      amount: unpaidSales,
                      count: unpaidCount,
                      isSelected: _filterMethod == 'pending',
                      onTap: () => setState(
                        () => _filterMethod = _filterMethod == 'pending'
                            ? 'all'
                            : 'pending',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Filter label ──
              if (_filterMethod != 'all')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Filtered: ${_methodLabel(_filterMethod)}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _filterMethod = 'all'),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // ── Sales list ──
              Expanded(
                child: sales.isEmpty
                    ? Center(
                        child: Text(
                          "No ${_methodLabel(_filterMethod)} sales found",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return _saleCard(context, sale);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _saleCard(BuildContext context, Sale sale) {
    final methodColor =
        {
          'cash': Colors.green,
          'mobile_money': Colors.yellow[700],
          'bank_card': Colors.blue,
        }[sale.paymentMethod] ??
        Colors.grey;

    final methodIcon =
        {
          'cash': Icons.payments_outlined,
          'mobile_money': Icons.phone_android,
          'bank_card': Icons.credit_card,
        }[sale.paymentMethod] ??
        Icons.hourglass_empty;

    final formatted =
        "${sale.date.day}/${sale.date.month}/${sale.date.year} "
        "${sale.date.hour.toString().padLeft(2, '0')}:"
        "${sale.date.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: methodColor.withValues(alpha: 0.15),
          child: Icon(methodIcon, color: methodColor, size: 20),
        ),
        title: Text(
          formatMoney(sale.total),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatted),
            if (sale.paymentMethod != null)
              Text(
                _methodLabel(sale.paymentMethod!),
                style: TextStyle(
                  color: methodColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text(
                "Payment pending",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showReceiptDialog(context, {
            'id': sale.id,
            'total': sale.total,
            'date': sale.date,
            'items': sale.items,
            'paymentMethod': sale.paymentMethod,
          }, isReadOnly: true);
        },
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard({
    required String label,
    required IconData icon,
    required Color color,
    required double amount,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              "$count transaction${count != 1 ? 's' : ''}",
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      case 'bank_card':
        return 'Bank Card';
      case 'pending':
        return 'Pending';
      default:
        return method;
    }
  }
}
