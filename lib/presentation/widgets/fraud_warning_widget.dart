import 'package:flutter/material.dart';

class FraudWarningWidget extends StatelessWidget {
  final String riskLevel;
  final String? message;
  final List<String>? reasons;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const FraudWarningWidget({
    super.key,
    required this.riskLevel,
    this.message,
    this.reasons,
    this.onDismiss,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getRiskConfig(riskLevel);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: config.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: config.color,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        message!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  color: config.color,
                ),
            ],
          ),
          if (reasons != null && reasons!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Impamvu:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...reasons!.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: config.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (onViewDetails != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.info_outline),
                label: const Text('Reba ibisobanuro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: config.color,
                  side: BorderSide(color: config.color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _RiskConfig _getRiskConfig(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return _RiskConfig(
          color: Colors.red[700]!,
          icon: Icons.dangerous,
          title: 'Akaga Gakomeye',
        );
      case 'HIGH':
        return _RiskConfig(
          color: Colors.red,
          icon: Icons.warning,
          title: 'Akaga Kanini',
        );
      case 'MEDIUM':
        return _RiskConfig(
          color: Colors.orange,
          icon: Icons.error_outline,
          title: 'Akaga Gato',
        );
      case 'LOW':
        return _RiskConfig(
          color: Colors.yellow[700]!,
          icon: Icons.info,
          title: 'Reba',
        );
      default:
        return _RiskConfig(
          color: Colors.grey,
          icon: Icons.help_outline,
          title: 'Akaga',
        );
    }
  }
}

class _RiskConfig {
  final Color color;
  final IconData icon;
  final String title;

  _RiskConfig({
    required this.color,
    required this.icon,
    required this.title,
  });
}

// Compact version for inline display
class CompactFraudWarning extends StatelessWidget {
  final String riskLevel;
  final VoidCallback? onTap;

  const CompactFraudWarning({
    super.key,
    required this.riskLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getRiskConfig(riskLevel);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 14, color: config.color),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: config.color,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: config.color),
            ],
          ],
        ),
      ),
    );
  }

  _CompactRiskConfig _getRiskConfig(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return _CompactRiskConfig(
          color: Colors.red[700]!,
          icon: Icons.dangerous,
          label: 'Akaga gakomeye',
        );
      case 'HIGH':
        return _CompactRiskConfig(
          color: Colors.red,
          icon: Icons.warning,
          label: 'Akaga kanini',
        );
      case 'MEDIUM':
        return _CompactRiskConfig(
          color: Colors.orange,
          icon: Icons.error_outline,
          label: 'Akaga gato',
        );
      case 'LOW':
        return _CompactRiskConfig(
          color: Colors.yellow[700]!,
          icon: Icons.info,
          label: 'Reba',
        );
      default:
        return _CompactRiskConfig(
          color: Colors.grey,
          icon: Icons.help_outline,
          label: 'Akaga',
        );
    }
  }
}

class _CompactRiskConfig {
  final Color color;
  final IconData icon;
  final String label;

  _CompactRiskConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
