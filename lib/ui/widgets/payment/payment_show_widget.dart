import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_management/core/utils/formatters.dart';

// ── Payment steps enum ──
enum PaymentStep {
  selectMethod,
  // Mobile Money steps
  selectNetwork,
  enterPhone,
  waitingApproval,
  // Cash steps
  enterCashReceived,
  // Bank Card steps
  selectCardType,
  tapCard,
  // Shared
  success,
}

// ── Show the dialog ──
void showPaymentFlowDialog(
  BuildContext context, {
  required double totalAmount,
  required Function(String paymentMethod) onPaymentComplete,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PaymentFlowDialog(
      totalAmount: totalAmount,
      onPaymentComplete: onPaymentComplete,
    ),
  );
}

class PaymentFlowDialog extends StatefulWidget {
  final double totalAmount;
  final Function(String paymentMethod) onPaymentComplete;

  const PaymentFlowDialog({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentFlowDialog> createState() => _PaymentFlowDialogState();
}

class _PaymentFlowDialogState extends State<PaymentFlowDialog> {
  // ── Step history stack for back navigation ──
  final List<PaymentStep> _history = [PaymentStep.selectMethod];
  PaymentStep get _currentStep => _history.last;

  // ── Selected values ──
  String _selectedMethod = '';
  String _selectedNetwork = '';
  String _selectedCardType = '';
  String _phoneNumber = '';
  double _cashReceived = 0;

  // ── Controllers ──
  final _phoneCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();

  // ── Transition direction ──
  bool _goingForward = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  void _goTo(PaymentStep step) {
    setState(() {
      _goingForward = true;
      _history.add(step);
    });
  }

  void _goBack() {
    if (_history.length <= 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _goingForward = false;
      _history.removeLast();
    });
  }

  double get _change => _cashReceived > widget.totalAmount
      ? _cashReceived - widget.totalAmount
      : 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            _buildHeader(),

            // ── Animated step content ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final offset = _goingForward
                    ? const Offset(1, 0)
                    : const Offset(-1, 0);
                return SlideTransition(
                  position: Tween<Offset>(begin: offset, end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    final isSuccess = _currentStep == PaymentStep.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green : Colors.blue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // back button — hidden on success
          if (!isSuccess && _currentStep != PaymentStep.selectMethod)
            GestureDetector(
              onTap: _goBack,
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            )
          else if (!isSuccess)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headerTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Amount: ${formatMoney(widget.totalAmount)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _headerTitle() {
    switch (_currentStep) {
      case PaymentStep.selectMethod:
        return "Select Payment Method";
      case PaymentStep.selectNetwork:
        return "Mobile Money";
      case PaymentStep.enterPhone:
        return "Enter Phone Number";
      case PaymentStep.waitingApproval:
        return "Waiting for Approval";
      case PaymentStep.enterCashReceived:
        return "Cash Payment";
      case PaymentStep.selectCardType:
        return "Bank Card";
      case PaymentStep.tapCard:
        return "Card Payment";
      case PaymentStep.success:
        return "Payment Successful";
    }
  }

  // ── Step builder ──
  Widget _buildStep() {
    switch (_currentStep) {
      case PaymentStep.selectMethod:
        return _stepSelectMethod();
      case PaymentStep.selectNetwork:
        return _stepSelectNetwork();
      case PaymentStep.enterPhone:
        return _stepEnterPhone();
      case PaymentStep.waitingApproval:
        return _stepWaitingApproval();
      case PaymentStep.enterCashReceived:
        return _stepCashReceived();
      case PaymentStep.selectCardType:
        return _stepSelectCardType();
      case PaymentStep.tapCard:
        return _stepTapCard();
      case PaymentStep.success:
        return _stepSuccess();
    }
  }

  // ────────────────────────────────────────
  // STEP 1 — Select payment method
  // ────────────────────────────────────────
  Widget _stepSelectMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "How would the customer like to pay?",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        _methodOption(
          icon: Icons.phone_android,
          color: Colors.yellow[700]!,
          label: "Mobile Money",
          description: "MTN, Vodafone, AirtelTigo",
          onTap: () {
            _selectedMethod = 'mobile_money';
            _goTo(PaymentStep.selectNetwork);
          },
        ),
        const SizedBox(height: 12),

        _methodOption(
          icon: Icons.payments_outlined,
          color: Colors.green,
          label: "Cash",
          description: "Pay with physical cash",
          onTap: () {
            _selectedMethod = 'cash';
            _goTo(PaymentStep.enterCashReceived);
          },
        ),
        const SizedBox(height: 12),

        _methodOption(
          icon: Icons.credit_card,
          color: Colors.blue,
          label: "Bank Card",
          description: "Visa, Mastercard, GhIPSS",
          onTap: () {
            _selectedMethod = 'bank_card';
            _goTo(PaymentStep.selectCardType);
          },
        ),
      ],
    );
  }


  Widget _stepSelectNetwork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Select the customer's network:",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        _selectableCard(
          label: "MTN Mobile Money",
          sublabel: "MTN MoMo",
          color: Colors.yellow[700]!,
          isSelected: _selectedNetwork == 'MTN',
          onTap: () => setState(() => _selectedNetwork = 'MTN'),
        ),
        const SizedBox(height: 10),

        _selectableCard(
          label: "Vodafone Cash",
          sublabel: "Vodafone",
          color: Colors.red,
          isSelected: _selectedNetwork == 'Vodafone',
          onTap: () => setState(() => _selectedNetwork = 'Vodafone'),
        ),
        const SizedBox(height: 10),

        _selectableCard(
          label: "AirtelTigo Money",
          sublabel: "AirtelTigo",
          color: Colors.blue[800]!,
          isSelected: _selectedNetwork == 'AirtelTigo',
          onTap: () => setState(() => _selectedNetwork = 'AirtelTigo'),
        ),

        const SizedBox(height: 20),

        _primaryButton(
          label: "Continue",
          enabled: _selectedNetwork.isNotEmpty,
          onPressed: () => _goTo(PaymentStep.enterPhone),
        ),
      ],
    );
  }

  Widget _stepEnterPhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Enter customer's $_selectedNetwork number:",
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: "Phone Number",
            hintText: "0XX XXX XXXX",
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (val) => setState(() => _phoneNumber = val),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Amount to charge:"),
              Text(
                formatMoney(widget.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _primaryButton(
          label: "Send Payment Prompt",
          enabled: _phoneNumber.length == 10,
          onPressed: () => _goTo(PaymentStep.waitingApproval),
        ),
      ],
    );
  }

  Widget _stepWaitingApproval() {
    return Column(
      children: [
        const SizedBox(height: 24),

        const CircularProgressIndicator(),
        const SizedBox(height: 20),

        Text(
          "Prompt sent to $_phoneNumber",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          "Ask customer to approve the payment\nprompt on their phone",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.yellow[700]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android, color: Colors.yellow[700], size: 20),
              const SizedBox(width: 8),
              Text(
                "${formatMoney(widget.totalAmount)} via $_selectedNetwork",
                style: TextStyle(
                  color: Colors.yellow[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _primaryButton(
          label: "Confirm Payment Received",
          onPressed: () => _goTo(PaymentStep.success),
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: _goBack,
          child: const Text("Wrong number? Go back"),
        ),
      ],
    );
  }

  Widget _stepCashReceived() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              const Text("Amount Due", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                formatMoney(widget.totalAmount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        //cash received 
        TextField(
          controller: _cashCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: "Cash Received (₵)",
            prefixIcon: const Icon(Icons.payments_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (val) {
            setState(() {
              _cashReceived = double.tryParse(val) ?? 0;
            });
          },
        ),

        const SizedBox(height: 12),

        //change 
        if (_cashReceived > 0)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cashReceived >= widget.totalAmount
                  ? Colors.blue[50]
                  : Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _cashReceived >= widget.totalAmount
                    ? Colors.blue[200]!
                    : Colors.red[200]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _cashReceived >= widget.totalAmount
                      ? "Change to give:"
                      : "Amount short:",
                  style: TextStyle(
                    color: _cashReceived >= widget.totalAmount
                        ? Colors.blue
                        : Colors.red,
                  ),
                ),
                Text(
                  _cashReceived >= widget.totalAmount
                      ? formatMoney(_change)
                      : formatMoney(widget.totalAmount - _cashReceived),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _cashReceived >= widget.totalAmount
                        ? Colors.blue
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        _primaryButton(
          label: "Complete Sale",
          enabled: _cashReceived >= widget.totalAmount,
          onPressed: () => _goTo(PaymentStep.success),
        ),
      ],
    );
  }

  Widget _stepSelectCardType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Select the customer's card type:",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        _selectableCard(
          label: "Visa",
          sublabel: "Visa debit or credit",
          color: Colors.blue[800]!,
          isSelected: _selectedCardType == 'Visa',
          onTap: () => setState(() => _selectedCardType = 'Visa'),
        ),
        const SizedBox(height: 10),

        _selectableCard(
          label: "Mastercard",
          sublabel: "Mastercard debit or credit",
          color: Colors.red[700]!,
          isSelected: _selectedCardType == 'Mastercard',
          onTap: () => setState(() => _selectedCardType = 'Mastercard'),
        ),
        const SizedBox(height: 10),

        _selectableCard(
          label: "GhIPSS",
          sublabel: "Ghana Interbank Payment",
          color: Colors.green[700]!,
          isSelected: _selectedCardType == 'GhIPSS',
          onTap: () => setState(() => _selectedCardType = 'GhIPSS'),
        ),

        const SizedBox(height: 20),

        _primaryButton(
          label: "Continue",
          enabled: _selectedCardType.isNotEmpty,
          onPressed: () => _goTo(PaymentStep.tapCard),
        ),
      ],
    );
  }
  Widget _stepTapCard() {
    return Column(
      children: [
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.credit_card, size: 60, color: Colors.blue[700]),
        ),

        const SizedBox(height: 16),

        Text(
          "Ask customer to tap or swipe\ntheir $_selectedCardType card on the terminal",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_money, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                "Charge: ${formatMoney(widget.totalAmount)}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _primaryButton(
          label: "Confirm Payment Received",
          onPressed: () => _goTo(PaymentStep.success),
        ),
      ],
    );
  }
  Widget _stepSuccess() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // ✅ animated checkmark
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Payment Successful!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          formatMoney(widget.totalAmount),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(
          "Paid via ${_paymentSummary()}",
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 24),

        _primaryButton(
          label: "Done",
          color: Colors.green,
          onPressed: () {
            Navigator.pop(context);
            widget.onPaymentComplete(_selectedMethod);
          },
        ),
      ],
    );
  }
  Widget _methodOption({
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _selectableCard({
    required String label,
    required String sublabel,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
    bool enabled = true,
    Color color = Colors.blue,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey[300],
          foregroundColor: enabled ? Colors.white : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _paymentSummary() {
    switch (_selectedMethod) {
      case 'mobile_money':
        return "$_selectedNetwork — $_phoneNumber";
      case 'cash':
        return "Cash (Change: ${formatMoney(_change)})";
      case 'bank_card':
        return "$_selectedCardType Card";
      default:
        return _selectedMethod;
    }
  }
}
