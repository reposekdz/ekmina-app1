import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/formatters.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'] ?? 'UNKNOWN';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final status = transaction['status'] ?? 'PENDING';
    final description = transaction['description'] ?? type;
    final timestamp = transaction['createdAt'] ?? transaction['timestamp'];
    final provider = transaction['provider'];
    final fraudScore = transaction['fraudScore'];
    final fraudRisk = transaction['fraudRisk'];
    
    final isCredit = ['DEPOSIT', 'LOAN_DISBURSEMENT', 'TRANSFER_IN', 'REFUND'].contains(type);
    final isDebit = ['WITHDRAWAL', 'TRANSFER_OUT', 'LOAN_PAYMENT', 'FEE'].contains(type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: fraudRisk == 'HIGH' || fraudRisk == 'CRITICAL' ? 4 : 1,
      color: fraudRisk == 'HIGH' || fraudRisk == 'CRITICAL' ? Colors.red[50] : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(type, isCredit, isDebit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? '+' : isDebit ? '-' : ''}${Formatters.formatCurrency(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isCredit ? Colors.green : isDebit ? Colors.red : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(status),
                    ],
                  ),
                ],
              ),
              if (provider != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildProviderLogo(provider),
                    const SizedBox(width: 8),
                    Text(
                      _getProviderName(provider),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (fraudRisk != null && fraudRisk != 'LOW') ...[
                const SizedBox(height: 12),
                _buildFraudWarning(fraudRisk, fraudScore),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String type, bool isCredit, bool isDebit) {
    IconData icon;
    Color color;

    switch (type) {
      case 'DEPOSIT':
        icon = Icons.arrow_downward;
        color = Colors.green;
        break;
      case 'WITHDRAWAL':
        icon = Icons.arrow_upward;
        color = Colors.red;
        break;
      case 'TRANSFER_OUT':
      case 'TRANSFER_IN':
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case 'LOAN_DISBURSEMENT':
        icon = Icons.account_balance;
        color = Colors.green;
        break;
      case 'LOAN_PAYMENT':
        icon = Icons.payment;
        color = Colors.orange;
        break;
      case 'FEE':
        icon = Icons.receipt;
        color = Colors.grey;
        break;
      default:
        icon = Icons.monetization_on;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'COMPLETED':
      case 'SUCCESS':
        color = Colors.green;
        label = 'Byatsinze';
        break;
      case 'PENDING':
        color = Colors.orange;
        label = 'Bitegereje';
        break;
      case 'FAILED':
        color = Colors.red;
        label = 'Byanze';
        break;
      case 'BLOCKED':
        color = Colors.red;
        label = 'Byahagaritswe';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProviderLogo(String provider) {
    IconData icon;
    Color color;

    switch (provider.toUpperCase()) {
      case 'MTN_MOMO':
      case 'MTN':
        icon = Icons.phone_android;
        color = Colors.yellow[700]!;
        break;
      case 'AIRTEL_MONEY':
      case 'AIRTEL':
        icon = Icons.phone_android;
        color = Colors.red;
        break;
      case 'WALLET':
        icon = Icons.account_balance_wallet;
        color = const Color(0xFF00A86B);
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  String _getProviderName(String provider) {
    switch (provider.toUpperCase()) {
      case 'MTN_MOMO':
      case 'MTN':
        return 'MTN Mobile Money';
      case 'AIRTEL_MONEY':
      case 'AIRTEL':
        return 'Airtel Money';
      case 'WALLET':
        return 'E-Kimina Wallet';
      default:
        return provider;
    }
  }

  Widget _buildFraudWarning(String risk, dynamic score) {
    Color color;
    IconData icon;
    String message;

    switch (risk) {
      case 'CRITICAL':
        color = Colors.red;
        icon = Icons.dangerous;
        message = 'Igikorwa gikekwa cyane';
        break;
      case 'HIGH':
        color = Colors.orange;
        icon = Icons.warning;
        message = 'Igikorwa gikekwa';
        break;
      case 'MEDIUM':
        color = Colors.yellow[700]!;
        icon = Icons.info;
        message = 'Reba igikorwa';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (score != null)
            Text(
              'Score: ${score.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Ubu';
      if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return timestamp.toString();
    }
  }
}
