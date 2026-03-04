import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _paymentMethods = [
    {'type': 'mtn', 'number': '0788123456', 'name': 'MTN MoMo', 'isDefault': true, 'icon': Icons.phone_android, 'color': Colors.yellow},
    {'type': 'airtel', 'number': '0738234567', 'name': 'Airtel Money', 'isDefault': false, 'icon': Icons.phone_iphone, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uburyo bwo kwishyura'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addPaymentMethod),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          const Text('Uburyo bwawe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF00A86B)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ongeraho uburyo bwo kwishyura kugirango ubone uburyo bworoshye bwo gukora ibikorwa',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (method['color'] as Color).withOpacity(0.2),
          child: Icon(method['icon'] as IconData, color: method['color'] as Color),
        ),
        title: Row(
          children: [
            Text(method['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
            if (method['isDefault']) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Default', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        subtitle: Text(method['number']),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!method['isDefault'])
              const PopupMenuItem(value: 'default', child: Text('Shyira nk\'ibanze')),
            const PopupMenuItem(value: 'edit', child: Text('Hindura')),
            const PopupMenuItem(value: 'delete', child: Text('Siba', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (value) => _handleAction(value as String, method),
        ),
      ),
    );
  }

  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ongeraho uburyo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.yellow, child: Icon(Icons.phone_android, color: Colors.black)),
                title: const Text('MTN MoMo'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMTNDialog();
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.phone_iphone, color: Colors.white)),
                title: const Text('Airtel Money'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showAddAirtelDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMTNDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ongeraho MTN MoMo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nomero ya telefoni',
            hintText: '078XXXXXXX',
            prefixText: '+250 ',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _paymentMethods.add({
                  'type': 'mtn',
                  'number': controller.text,
                  'name': 'MTN MoMo',
                  'isDefault': false,
                  'icon': Icons.phone_android,
                  'color': Colors.yellow,
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('MTN MoMo yongeweho!')),
              );
            },
            child: const Text('Ongeraho'),
          ),
        ],
      ),
    );
  }

  void _showAddAirtelDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ongeraho Airtel Money'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nomero ya telefoni',
            hintText: '073XXXXXXX',
            prefixText: '+250 ',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _paymentMethods.add({
                  'type': 'airtel',
                  'number': controller.text,
                  'name': 'Airtel Money',
                  'isDefault': false,
                  'icon': Icons.phone_iphone,
                  'color': Colors.red,
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Airtel Money yongeweho!')),
              );
            },
            child: const Text('Ongeraho'),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> method) {
    switch (action) {
      case 'default':
        setState(() {
          for (var m in _paymentMethods) {
            m['isDefault'] = false;
          }
          method['isDefault'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uburyo bwashyizwe nk\'ibanze')),
        );
        break;
      case 'edit':
        _showAddMTNDialog();
        break;
      case 'delete':
        setState(() {
          _paymentMethods.remove(method);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uburyo bwasibwe')),
        );
        break;
    }
  }
}
