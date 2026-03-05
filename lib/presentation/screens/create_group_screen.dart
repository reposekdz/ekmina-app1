import 'package:flutter/material.dart';
import '../../core/utils/rwanda_location.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;
  String? _selectedCell;
  String? _selectedVillage;
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shareValueController = TextEditingController();
  final _joinFeeController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _interestController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shareValueController.dispose();
    _joinFeeController.dispose();
    _penaltyController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Basic Info'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Choose a unique name for your group',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Location'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: RwandaLocation.getProvinces().map((province) {
                    return DropdownMenuItem(value: province, child: Text(province));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null;
                      _selectedSector = null;
                      _selectedCell = null;
                      _selectedVillage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedProvince != null)
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: RwandaLocation.getDistricts(_selectedProvince!).map((district) {
                      return DropdownMenuItem(value: district, child: Text(district));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                        _selectedSector = null;
                        _selectedCell = null;
                        _selectedVillage = null;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                if (_selectedDistrict != null)
                  DropdownButtonFormField<String>(
                    value: _selectedSector,
                    decoration: const InputDecoration(
                      labelText: 'Sector',
                      prefixIcon: Icon(Icons.map),
                    ),
                    items: RwandaLocation.getSectors(_selectedProvince!, _selectedDistrict!).map((sector) {
                      return DropdownMenuItem(value: sector, child: Text(sector));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSector = value;
                        _selectedCell = null;
                        _selectedVillage = null;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                if (_selectedSector != null)
                  DropdownButtonFormField<String>(
                    value: _selectedCell,
                    decoration: const InputDecoration(
                      labelText: 'Cell',
                      prefixIcon: Icon(Icons.place),
                    ),
                    items: RwandaLocation.getCells(_selectedProvince!, _selectedDistrict!, _selectedSector!).map((cell) {
                      return DropdownMenuItem(value: cell, child: Text(cell));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCell = value;
                        _selectedVillage = null;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                if (_selectedCell != null)
                  DropdownButtonFormField<String>(
                    value: _selectedVillage,
                    decoration: const InputDecoration(
                      labelText: 'Village',
                      prefixIcon: Icon(Icons.home),
                    ),
                    items: RwandaLocation.getVillages(_selectedProvince!, _selectedDistrict!, _selectedSector!, _selectedCell!).map((village) {
                      return DropdownMenuItem(value: village, child: Text(village));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedVillage = value);
                    },
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Financial Rules'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                TextFormField(
                  controller: _shareValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Share Value (RWF)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _joinFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Join Fee (RWF)',
                    prefixIcon: Icon(Icons.payment),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _penaltyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Penalty Amount (RWF)',
                    prefixIcon: Icon(Icons.warning),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _interestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Interest Rate (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter group name'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedProvince == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select location'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_shareValueController.text.isEmpty || _interestController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all financial rules'), backgroundColor: Colors.red),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF00A86B), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('Group Created!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your group "${_nameController.text}" has been created successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
