import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AddMemberScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  
  const AddMemberScreen({super.key, required this.groupId, required this.userId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _phoneController = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  bool _loading = false;
  String _role = 'MEMBER';

  Future<void> _addMember() async {
    if (_phoneController.text.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final userResponse = await _dio.get('/users/search', queryParameters: {'phone': _phoneController.text});
      
      if (userResponse.data['user'] == null) {
        throw Exception('Uyu mukoresha ntabwo ahari');
      }

      final response = await _dio.put('/groups/${widget.groupId}/manage', data: {
        'userId': widget.userId,
        'action': 'add_member',
        'data': {'memberId': userResponse.data['user']['id'], 'role': _role}
      });

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Umunyamuryango yongeweho neza!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ongeraho Umunyamuryango')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nimero ya telefoni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '+250 788 123 456',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Uruhare', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile(
              title: const Text('Umunyamuryango'),
              value: 'MEMBER',
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
            RadioListTile(
              title: const Text('Umuyobozi'),
              value: 'ADMIN',
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _addMember,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Ongeraho', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
