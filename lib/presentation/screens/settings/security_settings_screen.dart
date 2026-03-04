import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/error_handler.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  final String userId;
  const SecuritySettingsScreen({super.key, required this.userId});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final _storage = SecureStorageService();
  final _biometric = BiometricService();
  
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _loginNotifications = true;
  bool _transactionNotifications = true;
  bool _loading = true;
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final settings = await api.get('/users/${widget.userId}/security-settings');
      final devices = await api.get('/users/${widget.userId}/devices');
      
      if (mounted) {
        setState(() {
          _biometricEnabled = settings['biometricEnabled'] ?? false;
          _twoFactorEnabled = settings['twoFactorEnabled'] ?? false;
          _loginNotifications = settings['loginNotifications'] ?? true;
          _transactionNotifications = settings['transactionNotifications'] ?? true;
          _devices = devices['devices'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canAuth = await _biometric.canAuthenticate();
      if (!canAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric ntabwo iraboneka kuri iyi telefoni'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      final authenticated = await _biometric.authenticate();
      if (!authenticated) return;
    }
    
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/users/${widget.userId}/security-settings', {'biometricEnabled': value});
      setState(() => _biometricEnabled = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Biometric yashyizweho' : 'Biometric yavanweho'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (value) {
      await _show2FASetupDialog();
    } else {
      await _disable2FA();
    }
  }

  Future<void> _show2FASetupDialog() async {
    final phoneController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF00A86B)),
            SizedBox(width: 8),
            Text('Shyiraho 2FA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tuzakwohereza OTP kuri telefoni yawe buri gihe winjira'),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nimero ya telefoni',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
            child: const Text('Emeza'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/users/${widget.userId}/enable-2fa', {'phone': phoneController.text});
        setState(() => _twoFactorEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA yashyizweho neza'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuraho 2FA'),
        content: const Text('Uremeza ko ushaka kuraho 2FA? Ibi bizagabanya umutekano wa konti yawe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yego, kuraho'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/users/${widget.userId}/disable-2fa', {});
        setState(() => _twoFactorEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA yakuweho'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _changeWalletPIN() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hindura PIN ya Wallet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN ya kera',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN nshya',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Emeza PIN nshya',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () {
              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN ntabwo ihuje'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
            child: const Text('Hindura'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/users/${widget.userId}/change-wallet-pin', {
          'oldPin': oldPinController.text,
          'newPin': newPinController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN yahinduwe neza'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _logoutDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohoka kuri iyi telefoni'),
        content: const Text('Uremeza ko ushaka gusohoka kuri iyi telefoni?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yego, sohoka'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/users/${widget.userId}/logout-device', {'deviceId': deviceId});
        _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wasohokanywe kuri iyi telefoni'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _logoutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohoka kuri telefoni zose'),
        content: const Text('Uremeza ko ushaka gusohoka kuri telefoni zose? Uzakeneye kwinjira nanone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yego, sohoka'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/users/${widget.userId}/logout-all-devices', {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wasohokanywe kuri telefoni zose'), backgroundColor: Colors.green),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Umutekano')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Umutekano'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAuthenticationSection(),
          const SizedBox(height: 24),
          _buildNotificationsSection(),
          const SizedBox(height: 24),
          _buildDevicesSection(),
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fingerprint, color: Color(0xFF00A86B)),
                SizedBox(width: 8),
                Text('Kwinjira', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Biometric Authentication'),
              subtitle: const Text('Koresha urutoki cyangwa isura'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
              activeColor: const Color(0xFF00A86B),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Two-Factor Authentication (2FA)'),
              subtitle: const Text('Shyiraho umutekano w\'inyongera'),
              value: _twoFactorEnabled,
              onChanged: _toggle2FA,
              activeColor: const Color(0xFF00A86B),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pin, color: Color(0xFF00A86B)),
              title: const Text('Hindura PIN ya Wallet'),
              subtitle: const Text('Hindura PIN yo kwishyura'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changeWalletPIN,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF00A86B)),
              title: const Text('Hindura ijambo ryibanga'),
              subtitle: const Text('Hindura ijambo ryibanga ryo kwinjira'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/password-reset'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications, color: Color(0xFF00A86B)),
                SizedBox(width: 8),
                Text('Imenyesha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Imenyesha yo kwinjira'),
              subtitle: const Text('Menyeshwa igihe winjiye'),
              value: _loginNotifications,
              onChanged: (value) => setState(() => _loginNotifications = value),
              activeColor: const Color(0xFF00A86B),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Imenyesha y\'amafaranga'),
              subtitle: const Text('Menyeshwa igihe wakoze igikorwa'),
              value: _transactionNotifications,
              onChanged: (value) => setState(() => _transactionNotifications = value),
              activeColor: const Color(0xFF00A86B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.devices, color: Color(0xFF00A86B)),
                SizedBox(width: 8),
                Text('Telefoni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            if (_devices.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nta telefoni')))
            else
              ..._devices.map((device) => Column(
                children: [
                  ListTile(
                    leading: Icon(
                      device['deviceType'] == 'mobile' ? Icons.phone_android : Icons.computer,
                      color: const Color(0xFF00A86B),
                    ),
                    title: Text(device['deviceName'] ?? 'Unknown Device'),
                    subtitle: Text('Iheruka kwinjira: ${device['lastActive']}'),
                    trailing: device['isCurrent']
                        ? const Chip(label: Text('Iyi telefoni'), backgroundColor: Color(0xFF00A86B), labelStyle: TextStyle(color: Colors.white))
                        : IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            onPressed: () => _logoutDevice(device['id']),
                          ),
                  ),
                  if (device != _devices.last) const Divider(),
                ],
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Danger Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sohoka kuri telefoni zose'),
              subtitle: const Text('Sohoka kuri telefoni zose usigaranye iyi'),
              onTap: _logoutAllDevices,
            ),
          ],
        ),
      ),
    );
  }
}
