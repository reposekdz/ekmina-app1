import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      setState(() {
        _canCheckBiometrics = canCheck;
        _availableBiometrics = available;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Emeza umwirondoro wawe',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        setState(() => _isEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrics yashyizweho neza!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            if (_canCheckBiometrics) ...[
              _buildAvailableBiometrics(),
              const SizedBox(height: 24),
              _buildSecurityFeatures(),
              const SizedBox(height: 24),
              _buildSetupButton(),
            ] else
              _buildNotAvailableCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            _isEnabled ? Icons.fingerprint : Icons.security,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            _isEnabled ? 'Biometrics yashyizweho' : 'Shyiraho Biometric Security',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isEnabled
                ? 'Konti yawe ifite umutekano ukomeye'
                : 'Komeza umutekano w\'amafaranga yawe',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableBiometrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uburyo bwo kwemeza', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._availableBiometrics.map((type) {
              IconData icon;
              String label;
              switch (type) {
                case BiometricType.face:
                  icon = Icons.face;
                  label = 'Face ID';
                  break;
                case BiometricType.fingerprint:
                  icon = Icons.fingerprint;
                  label = 'Fingerprint';
                  break;
                case BiometricType.iris:
                  icon = Icons.remove_red_eye;
                  label = 'Iris Scan';
                  break;
                default:
                  icon = Icons.security;
                  label = 'Biometric';
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
                  child: Icon(icon, color: const Color(0xFF00A86B)),
                ),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.check_circle, color: _isEnabled ? Colors.green : Colors.grey),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeatures() {
    final features = [
      {'icon': Icons.lock, 'title': 'Umutekano ukomeye', 'desc': 'Ntawushobora kwinjira mu konti yawe'},
      {'icon': Icons.speed, 'title': 'Byihuse', 'desc': 'Injira vuba mu konti yawe'},
      {'icon': Icons.privacy_tip, 'title': 'Ibanga', 'desc': 'Amakuru yawe aracyungwa neza'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inyungu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
                    child: Icon(feature['icon'] as IconData, color: const Color(0xFF00A86B), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(feature['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(feature['desc'] as String, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isEnabled ? null : _authenticate,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(_isEnabled ? 'Yashyizweho' : 'Shyiraho Biometrics'),
      ),
    );
  }

  Widget _buildNotAvailableCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange[700]),
            const SizedBox(height: 16),
            const Text(
              'Biometrics ntiboneka',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Telefoni yawe ntiyemera biometric authentication. Koresha PIN gusa.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Subira inyuma'),
            ),
          ],
        ),
      ),
    );
  }
}
