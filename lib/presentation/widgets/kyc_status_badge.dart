import 'package:flutter/material.dart';

class KYCStatusBadge extends StatelessWidget {
  final String status;
  final bool showLabel;
  final double size;

  const KYCStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    if (!showLabel) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          config.icon,
          size: size * 0.6,
          color: config.color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED':
        return _StatusConfig(
          color: Colors.green,
          icon: Icons.verified,
          label: 'Byemejwe',
        );
      case 'PENDING':
      case 'SUBMITTED':
        return _StatusConfig(
          color: Colors.orange,
          icon: Icons.pending,
          label: 'Bitegereje',
        );
      case 'REJECTED':
      case 'FAILED':
        return _StatusConfig(
          color: Colors.red,
          icon: Icons.cancel,
          label: 'Byanze',
        );
      case 'NOT_STARTED':
      case 'INCOMPLETE':
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.info,
          label: 'Ntabwo byatangiye',
        );
      case 'UNDER_REVIEW':
        return _StatusConfig(
          color: Colors.blue,
          icon: Icons.rate_review,
          label: 'Birasuzumwa',
        );
      default:
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.help,
          label: status,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

// Animated version with pulse effect
class AnimatedKYCStatusBadge extends StatefulWidget {
  final String status;
  final bool showLabel;
  final double size;

  const AnimatedKYCStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  State<AnimatedKYCStatusBadge> createState() => _AnimatedKYCStatusBadgeState();
}

class _AnimatedKYCStatusBadgeState extends State<AnimatedKYCStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.status.toUpperCase() == 'PENDING' ||
        widget.status.toUpperCase() == 'UNDER_REVIEW') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: KYCStatusBadge(
        status: widget.status,
        showLabel: widget.showLabel,
        size: widget.size,
      ),
    );
  }
}
