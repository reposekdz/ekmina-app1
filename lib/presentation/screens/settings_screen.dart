import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  String _selectedCurrency = 'RWF';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Account', [
            _buildListTile(Icons.person_outline, 'Personal Information', '', () => _showPersonalInfoSheet()),
            _buildListTile(Icons.lock_outline, 'Change PIN', '', () => _showChangePinSheet()),
            _buildListTile(Icons.phone_android, 'Change Phone Number', '', () => _showChangePhoneSheet()),
          ]),
          const SizedBox(height: 16),
          _buildSection('Security', [
            _buildSwitchTile(Icons.fingerprint, 'Biometric Authentication', 'Use fingerprint or face ID', _biometricEnabled, (value) {
              setState(() => _biometricEnabled = value);
              HapticFeedback.selectionClick();
            }),
            _buildListTile(Icons.security, 'Two-Factor Authentication', 'Not enabled', () => _showTwoFactorSheet()),
            _buildListTile(Icons.devices, 'Active Sessions', '2 devices', () => _showActiveSessionsSheet()),
          ]),
          const SizedBox(height: 16),
          _buildSection('Notifications', [
            _buildSwitchTile(Icons.notifications_outlined, 'Push Notifications', 'Receive push notifications', _pushNotifications, (value) {
              setState(() => _pushNotifications = value);
              HapticFeedback.selectionClick();
            }),
            _buildSwitchTile(Icons.email_outlined, 'Email Notifications', 'Receive email updates', _emailNotifications, (value) {
              setState(() => _emailNotifications = value);
              HapticFeedback.selectionClick();
            }),
            _buildSwitchTile(Icons.sms_outlined, 'SMS Notifications', 'Receive SMS alerts', _smsNotifications, (value) {
              setState(() => _smsNotifications = value);
              HapticFeedback.selectionClick();
            }),
          ]),
          const SizedBox(height: 16),
          _buildSection('Preferences', [
            _buildListTile(Icons.language, 'Language', _selectedLanguage, () => _showLanguageSheet()),
            _buildListTile(Icons.dark_mode_outlined, 'Theme', _selectedTheme, () => _showThemeSheet()),
            _buildListTile(Icons.attach_money, 'Currency', _selectedCurrency, () => _showCurrencySheet()),
          ]),
          const SizedBox(height: 16),
          _buildSection('Support', [
            _buildListTile(Icons.help_outline, 'Help Center', '', () => _showHelpCenter()),
            _buildListTile(Icons.chat_bubble_outline, 'Contact Support', '', () => _showContactSupport()),
            _buildListTile(Icons.bug_report_outlined, 'Report a Problem', '', () => _showReportProblem()),
            _buildListTile(Icons.star_outline, 'Rate App', '', () => _showRateApp()),
          ]),
          const SizedBox(height: 16),
          _buildSection('Legal', [
            _buildListTile(Icons.description_outlined, 'Terms of Service', '', () => _showTerms()),
            _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', '', () => _showPrivacy()),
            _buildListTile(Icons.gavel_outlined, 'Licenses', '', () => _showLicenses()),
          ]),
          const SizedBox(height: 16),
          _buildSection('About', [
            _buildListTile(Icons.info_outline, 'App Version', '1.0.0', null),
            _buildListTile(Icons.update, 'Check for Updates', '', () => _checkUpdates()),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: _showDeleteAccountDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Delete Account'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, String trailing, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A86B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(color: Colors.grey)),
          if (onTap != null) const SizedBox(width: 8),
          if (onTap != null) const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF00A86B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: value,
      activeColor: const Color(0xFF00A86B),
      onChanged: onChanged,
    );
  }

  void _showPersonalInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              const TextField(decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'National ID', prefixIcon: Icon(Icons.badge))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePinSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change PIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              const TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(labelText: 'Current PIN', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(labelText: 'New PIN', prefixIcon: Icon(Icons.lock_open)),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(labelText: 'Confirm New PIN', prefixIcon: Icon(Icons.lock_open)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Change PIN')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePhoneSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change Phone Number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'New Phone Number', prefixIcon: Icon(Icons.phone), hintText: '+250 788 123 456'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Send Verification Code')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTwoFactorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 64, color: Color(0xFF00A86B)),
              const SizedBox(height: 16),
              const Text('Two-Factor Authentication', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Add an extra layer of security to your account', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Enable 2FA')),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveSessionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildSessionItem('Samsung Galaxy S21', 'Kigali, Rwanda', 'Active now', true),
              const SizedBox(height: 12),
              _buildSessionItem('iPhone 13 Pro', 'Kigali, Rwanda', '2 hours ago', false),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: const Text('Log Out All Devices'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(String device, String location, String time, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrent ? const Color(0xFF00A86B) : Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, color: isCurrent ? const Color(0xFF00A86B) : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$location • $time', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (isCurrent) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF00A86B), borderRadius: BorderRadius.circular(8)),
            child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildLanguageOption('English', 'en'),
              _buildLanguageOption('Kinyarwanda', 'rw'),
              _buildLanguageOption('Français', 'fr'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String code) {
    final isSelected = _selectedLanguage == language;
    return ListTile(
      title: Text(language, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00A86B)) : null,
      onTap: () {
        setState(() => _selectedLanguage = language);
        Navigator.pop(context);
      },
    );
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Theme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildThemeOption('Light', Icons.light_mode),
              _buildThemeOption('Dark', Icons.dark_mode),
              _buildThemeOption('System', Icons.settings_brightness),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, IconData icon) {
    final isSelected = _selectedTheme == theme;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF00A86B) : Colors.grey),
      title: Text(theme, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00A86B)) : null,
      onTap: () {
        setState(() => _selectedTheme = theme);
        Navigator.pop(context);
      },
    );
  }

  void _showCurrencySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Currency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildCurrencyOption('RWF', 'Rwandan Franc'),
              _buildCurrencyOption('USD', 'US Dollar'),
              _buildCurrencyOption('EUR', 'Euro'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    final isSelected = _selectedCurrency == code;
    return ListTile(
      title: Text('$code - $name', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00A86B)) : null,
      onTap: () {
        setState(() => _selectedCurrency = code);
        Navigator.pop(context);
      },
    );
  }

  void _showHelpCenter() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
  }

  void _showContactSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, size: 64, color: Color(0xFF00A86B)),
              const SizedBox(height: 16),
              const Text('Contact Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Email: support@ekimina.rw', textAlign: TextAlign.center),
              const Text('Phone: +250 788 123 456', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportProblem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report a Problem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Describe the problem',
                  hintText: 'Tell us what went wrong...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Problem report submitted')),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rate E-Kimina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate your experience?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                icon: const Icon(Icons.star, color: Color(0xFFFFB800)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thanks for rating ${index + 1} stars!')),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Terms of Service')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text('Terms of Service content would go here...'),
          ),
        ),
      ),
    );
  }

  void _showPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Privacy Policy')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text('Privacy Policy content would go here...'),
          ),
        ),
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(context: context);
  }

  void _checkUpdates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Color(0xFF00A86B)),
            const SizedBox(height: 16),
            const Text('You\'re up to date!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You have the latest version of E-Kimina'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone. All your data will be permanently deleted:'),
            const SizedBox(height: 12),
            const Text('• All group memberships'),
            const Text('• Transaction history'),
            const Text('• Wallet balance'),
            const Text('• Personal information'),
            const SizedBox(height: 12),
            const Text('Are you sure you want to continue?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Enter PIN to Confirm'),
                  content: const TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      hintText: 'Enter your 4-digit PIN',
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deletion request submitted')),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Color(0xFF00A86B), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Find answers to common questions', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFAQItem('How do I create a group?', 'Go to Groups tab and tap the + button. Fill in the group details including name, location, and financial rules. You need to have sufficient balance in your wallet to create a group.'),
          _buildFAQItem('How do I apply for a loan?', 'Navigate to your group and tap Request Loan. Select the loan amount, duration, and choose guarantors. Your loan eligibility is based on your shares in the group.'),
          _buildFAQItem('How do I deposit money?', 'Go to Wallet and tap Deposit. Enter the amount and select your payment method (MTN MoMo or Airtel Money). Follow the prompts to complete the transaction.'),
          _buildFAQItem('What are guarantors?', 'Guarantors are group members who vouch for your loan. They agree to help repay the loan if you are unable to. Most groups require 2-3 guarantors for loan approval.'),
          _buildFAQItem('How do shares work?', 'Shares represent your ownership in the group. Each share has a fixed value set by the group. Your total shares determine your loan eligibility and dividend distribution.'),
          _buildFAQItem('What happens if I miss a payment?', 'Missing a payment may result in penalties as defined by your group rules. It can also affect your ability to request future loans. Contact your group admin if you anticipate payment difficulties.'),
          _buildFAQItem('How do I invite members to my group?', 'Go to your group details, tap the menu icon, and select "Invite Members". You can share an invitation link or code with potential members.'),
          _buildFAQItem('Can I be in multiple groups?', 'Yes! You can join multiple groups. Each group operates independently with its own rules, shares, and financial activities.'),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer, style: TextStyle(color: Colors.grey[700], height: 1.5)),
          ),
        ],
      ),
    );
  }
}
