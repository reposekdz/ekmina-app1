import 'package:flutter/material.dart';

enum PaymentMethod {
  mtnMomo,
  airtelMoney,
  wallet,
}

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;
  final bool showWallet;
  final double? walletBalance;
  final List<PaymentMethod>? enabledMethods;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showWallet = true,
    this.walletBalance,
    this.enabledMethods,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  bool _isMethodEnabled(PaymentMethod method) {
    if (widget.enabledMethods == null) return true;
    return widget.enabledMethods!.contains(method);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hitamo uburyo bwo kwishyura',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMethodCard(
          method: PaymentMethod.mtnMomo,
          title: 'MTN Mobile Money',
          subtitle: 'Kwishyura ukoresheje MTN MoMo',
          icon: Icons.phone_android,
          color: Colors.yellow[700]!,
          enabled: _isMethodEnabled(PaymentMethod.mtnMomo),
        ),
        const SizedBox(height: 12),
        _buildMethodCard(
          method: PaymentMethod.airtelMoney,
          title: 'Airtel Money',
          subtitle: 'Kwishyura ukoresheje Airtel Money',
          icon: Icons.phone_android,
          color: Colors.red,
          enabled: _isMethodEnabled(PaymentMethod.airtelMoney),
        ),
        if (widget.showWallet) ...[
          const SizedBox(height: 12),
          _buildMethodCard(
            method: PaymentMethod.wallet,
            title: 'E-Kimina Wallet',
            subtitle: widget.walletBalance != null
                ? 'Urabona: ${_formatCurrency(widget.walletBalance!)}'
                : 'Koresha amafaranga yawe',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF00A86B),
            enabled: _isMethodEnabled(PaymentMethod.wallet),
          ),
        ],
      ],
    );
  }

  Widget _buildMethodCard({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
  }) {
    final isSelected = _selectedMethod == method;
    
    return InkWell(
      onTap: enabled
          ? () {
              setState(() => _selectedMethod = method);
              widget.onMethodSelected(method);
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected ? color.withOpacity(0.1) : Colors.grey[50])
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled ? color.withOpacity(0.1) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: enabled ? color : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: enabled ? Colors.grey[600] : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else if (!enabled)
              Icon(Icons.lock, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} RWF';
  }
}

// Compact version for inline selection
class CompactPaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final Function(PaymentMethod) onMethodSelected;
  final bool showWallet;

  const CompactPaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    this.showWallet = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactMethod(
            method: PaymentMethod.mtnMomo,
            label: 'MTN',
            icon: Icons.phone_android,
            color: Colors.yellow[700]!,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactMethod(
            method: PaymentMethod.airtelMoney,
            label: 'Airtel',
            icon: Icons.phone_android,
            color: Colors.red,
          ),
        ),
        if (showWallet) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactMethod(
              method: PaymentMethod.wallet,
              label: 'Wallet',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF00A86B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactMethod({
    required PaymentMethod method,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMethod == method;
    
    return InkWell(
      onTap: () => onMethodSelected(method),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to convert enum to string
extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.mtnMomo:
        return 'MTN_MOMO';
      case PaymentMethod.airtelMoney:
        return 'AIRTEL_MONEY';
      case PaymentMethod.wallet:
        return 'WALLET';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.mtnMomo:
        return 'MTN Mobile Money';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.wallet:
        return 'E-Kimina Wallet';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.mtnMomo:
      case PaymentMethod.airtelMoney:
        return Icons.phone_android;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.mtnMomo:
        return Colors.yellow[700]!;
      case PaymentMethod.airtelMoney:
        return Colors.red;
      case PaymentMethod.wallet:
        return const Color(0xFF00A86B);
    }
  }
}

// Helper to convert string to enum
PaymentMethod? paymentMethodFromString(String? value) {
  if (value == null) return null;
  switch (value.toUpperCase()) {
    case 'MTN_MOMO':
    case 'MTN':
      return PaymentMethod.mtnMomo;
    case 'AIRTEL_MONEY':
    case 'AIRTEL':
      return PaymentMethod.airtelMoney;
    case 'WALLET':
      return PaymentMethod.wallet;
    default:
      return null;
  }
}
