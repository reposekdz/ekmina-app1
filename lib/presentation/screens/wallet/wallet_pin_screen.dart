import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/remote/api_client.dart';

class WalletPinScreen extends StatefulWidget {
  final String mode; // 'set', 'change', 'verify'
  final Function(String)? onPinVerified;

  const WalletPinScreen({
    Key? key,
    this.mode = 'set',
    this.onPinVerified,
  }) : super(key: key);

  @override
  State<WalletPinScreen> createState() => _WalletPinScreenState();
}

class _WalletPinScreenState extends State<WalletPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _oldPinController = TextEditingController();
  final _walletService = WalletService(ApiClient());
  final _biometricService = BiometricService();
  
  bool _isLoading = false;
  bool _showConfirm = false;
  bool _biometricAvailable = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isAvailable();
    setState(() => _biometricAvailable = available);
  }

  Future<void> _handleBiometric() async {
    try {
      final authenticated = await _biometricService.authenticate('Emeza ko uri wowe');
      if (authenticated && widget.onPinVerified != null) {
        widget.onPinVerified!('biometric');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = 'Biometric authentication failed');
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _error = '';
      _isLoading = true;
    });

    try {
      if (widget.mode == 'set') {
        if (!_showConfirm) {
          if (_pinController.text.length == 4) {
            setState(() => _showConfirm = true);
            _isLoading = false;
            return;
          }
        } else {
          if (_pinController.text != _confirmPinController.text) {
            throw Exception('PIN ntabwo zihuye');
          }
          await _walletService.setPin(_pinController.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN yashyizweho neza')),
            );
            Navigator.pop(context, true);
          }
        }
      } else if (widget.mode == 'change') {
        if (_oldPinController.text.isEmpty) {
          throw Exception('Shyiramo PIN yawe ya kera');
        }
        if (_pinController.text != _confirmPinController.text) {
          throw Exception('PIN nshya ntabwo zihuye');
        }
        await _walletService.setPin(_pinController.text, oldPin: _oldPinController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN yahinduwe neza')),
          );
          Navigator.pop(context, true);
        }
      } else if (widget.mode == 'verify') {
        if (_pinController.text.length == 4) {
          if (widget.onPinVerified != null) {
            widget.onPinVerified!(_pinController.text);
          }
          Navigator.pop(context, _pinController.text);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPinDots(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < length ? Colors.blue : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      children: [
        ...List.generate(9, (index) {
          final number = index + 1;
          return _buildNumberButton(number.toString());
        }),
        if (_biometricAvailable && widget.mode == 'verify')
          _buildBiometricButton()
        else
          const SizedBox(),
        _buildNumberButton('0'),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () {
        if (_showConfirm) {
          if (_confirmPinController.text.length < 4) {
            setState(() {
              _confirmPinController.text += number;
              if (_confirmPinController.text.length == 4) {
                _handleSubmit();
              }
            });
          }
        } else {
          if (_pinController.text.length < 4) {
            setState(() {
              _pinController.text += number;
              if (_pinController.text.length == 4 && widget.mode == 'verify') {
                _handleSubmit();
              }
            });
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: () {
        setState(() {
          if (_showConfirm && _confirmPinController.text.isNotEmpty) {
            _confirmPinController.text = _confirmPinController.text.substring(0, _confirmPinController.text.length - 1);
          } else if (_pinController.text.isNotEmpty) {
            _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 28),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return InkWell(
      onTap: _handleBiometric,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.fingerprint, size: 32, color: Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Shyiraho PIN';
    String subtitle = 'Shyiramo imibare 4 kugirango ufunge wallet yawe';

    if (widget.mode == 'change') {
      title = 'Hindura PIN';
      subtitle = 'Shyiramo PIN nshya';
    } else if (widget.mode == 'verify') {
      title = 'Emeza PIN';
      subtitle = 'Shyiramo PIN yawe kugirango ukomeze';
    } else if (_showConfirm) {
      title = 'Emeza PIN';
      subtitle = 'Ongera ushyiremo PIN yawe';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.blue[700],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              if (widget.mode == 'change' && !_showConfirm) ...[
                TextField(
                  controller: _oldPinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN ya kera',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
              ],
              _buildPinDots(_showConfirm ? _confirmPinController.text.length : _pinController.text.length),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              Expanded(child: _buildNumberPad()),
              if (_isLoading)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _oldPinController.dispose();
    super.dispose();
  }
}
