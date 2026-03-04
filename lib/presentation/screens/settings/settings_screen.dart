import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Igenamiterere')),
      body: ListView(
        children: [
          _buildSection('Isura', [
            ListTile(
              leading: const Icon(Icons.brightness_6, color: AppTheme.primaryGreen),
              title: const Text('Isura'),
              subtitle: Text(themeMode == ThemeMode.light ? 'Yera' : themeMode == ThemeMode.dark ? 'Yijimye' : 'Sisitemu'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showThemeDialog(context, ref),
            ),
          ]),
          _buildSection('Ururimi', [
            ListTile(
              leading: const Icon(Icons.language, color: AppTheme.primaryGreen),
              title: const Text('Ururimi'),
              subtitle: Text(language == 'rw' ? 'Kinyarwanda' : language == 'en' ? 'English' : 'Français'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, ref),
            ),
          ]),
          _buildSection('Ubutumwa', [
            SwitchListTile(
              secondary: const Icon(Icons.notifications, color: AppTheme.primaryGreen),
              title: const Text('Ubutumwa'),
              subtitle: const Text('Emera ubutumwa'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration, color: AppTheme.primaryGreen),
              title: const Text('Kunyeganyega'),
              subtitle: const Text('Emera kunyeganyega'),
              value: true,
              onChanged: (value) {},
            ),
          ]),
          _buildSection('Umutekano', [
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppTheme.primaryGreen),
              title: const Text('Intoki/Isura'),
              subtitle: const Text('Koresha intoki cyangwa isura'),
              value: false,
              onChanged: (value) {},
            ),
          ]),
          _buildSection('Amakuru', [
            ListTile(
              leading: const Icon(Icons.info, color: AppTheme.primaryGreen),
              title: const Text('Verisiyo'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.policy, color: AppTheme.primaryGreen),
              title: const Text('Amategeko'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryGreen),
              title: const Text('Ibanga'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
        ...children,
      ],
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hitamo isura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Yera'),
              leading: Radio<ThemeMode>(value: ThemeMode.light, groupValue: ref.read(themeProvider), onChanged: (value) {
                ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                Navigator.pop(context);
              }),
            ),
            ListTile(
              title: const Text('Yijimye'),
              leading: Radio<ThemeMode>(value: ThemeMode.dark, groupValue: ref.read(themeProvider), onChanged: (value) {
                ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                Navigator.pop(context);
              }),
            ),
            ListTile(
              title: const Text('Sisitemu'),
              leading: Radio<ThemeMode>(value: ThemeMode.system, groupValue: ref.read(themeProvider), onChanged: (value) {
                ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                Navigator.pop(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hitamo ururimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Kinyarwanda'),
              leading: Radio<String>(value: 'rw', groupValue: ref.read(languageProvider), onChanged: (value) {
                ref.read(languageProvider.notifier).setLanguage('rw');
                Navigator.pop(context);
              }),
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(value: 'en', groupValue: ref.read(languageProvider), onChanged: (value) {
                ref.read(languageProvider.notifier).setLanguage('en');
                Navigator.pop(context);
              }),
            ),
            ListTile(
              title: const Text('Français'),
              leading: Radio<String>(value: 'fr', groupValue: ref.read(languageProvider), onChanged: (value) {
                ref.read(languageProvider.notifier).setLanguage('fr');
                Navigator.pop(context);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
