import 'package:intl/intl.dart';

String formatMoney(double amount) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return '₵${formatter.format(amount)}';
}
