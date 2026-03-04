import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/biometric_service.dart';

class PINInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final String? title;
  final String? subtitle;
  final bool showBiometric;
  final VoidCallback? onBiometricPressed;
  final bool obscureText;

  const PINInputWidget({
    super.key,
    required this.onCompleted,
    this.title,
    this.subtitle,
    this.showBiometric = true,
    this.onBiometricPressed,
    this.obscureText = true,
  });

  @override
  State<PINInputWidget> createState() => _PINInputWidgetState();
}

class _PINInputWidgetState extends State<PINInputWidget> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  final _biometric = BiometricService();
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _focusNodes[0].requestFocus();
  }

  Future<void> _checkBiometric() async {
    final canAuth = await _biometric.canAuthenticate();
    if (mounted) {
      setState(() => _canUseBiometric = canAuth);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final pin = _controllers.map((c) => c.text).join();
        if (pin.length == 4) {
          widget.onCompleted(pin);
        }
      }
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _handleBiometric() async {
    if (widget.onBiometricPressed != null) {
      widget.onBiometricPressed!();
    } else {
      final authenticated = await _biometric.authenticate();
      if (authenticated) {
        // Simulate PIN entry
        widget.onCompleted('BIOMETRIC');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: widget.obscureText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00A86B),
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onChanged(value, index),
                onTap: () {
                  _controllers[index].selection = TextSelection.fromPosition(
                    TextPosition(offset: _controllers[index].text.length),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear),
              label: const Text('Siba'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            if (widget.showBiometric && _canUseBiometric) ...[
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _handleBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Biometric'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00A86B),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Dialog version
class PINInputDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBiometric;
  final Function(String) onCompleted;

  const PINInputDialog({
    super.key,
    this.title,
    this.subtitle,
    this.showBiometric = true,
    required this.onCompleted,
  });

  static Future<String?> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    bool showBiometric = true,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PINInputDialog(
        title: title,
        subtitle: subtitle,
        showBiometric: showBiometric,
        onCompleted: (pin) => Navigator.pop(context, pin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PINInputWidget(
              title: title ?? 'Shyiramo PIN',
              subtitle: subtitle ?? 'Shyiramo PIN yawe yo kwishyura',
              showBiometric: showBiometric,
              onCompleted: onCompleted,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hagarika'),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet version
class PINInputBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBiometric;
  final Function(String) onCompleted;

  const PINInputBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    this.showBiometric = true,
    required this.onCompleted,
  });

  static Future<String?> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    bool showBiometric = true,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PINInputBottomSheet(
        title: title,
        subtitle: subtitle,
        showBiometric: showBiometric,
        onCompleted: (pin) => Navigator.pop(context, pin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          PINInputWidget(
            title: title ?? 'Shyiramo PIN',
            subtitle: subtitle ?? 'Shyiramo PIN yawe yo kwishyura',
            showBiometric: showBiometric,
            onCompleted: onCompleted,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
