import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  String _gender = 'MALE';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _dobController = TextEditingController(text: widget.user['dateOfBirth']);
    _gender = widget.user['gender'] ?? 'MALE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/users/${widget.user['id']}', {
        'name': _nameController.text,
        'email': _emailController.text,
        'dateOfBirth': _dobController.text,
        'gender': _gender,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil yahinduwe!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hindura profil'), actions: [
        TextButton(onPressed: _isLoading ? null : _saveProfile, child: const Text('Bika', style: TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold))),
      ]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Amazina', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Shyiramo amazina' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dobController,
              decoration: const InputDecoration(labelText: 'Itariki y\'amavuko', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
                if (date != null) _dobController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Igitsina', prefixIcon: Icon(Icons.wc), border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Gabo')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Gore')),
                DropdownMenuItem(value: 'OTHER', child: Text('Ikindi')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ],
        ),
      ),
    );
  }
}
