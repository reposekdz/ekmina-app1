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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group created successfully!')),
    );
    Navigator.pop(context);
  }
}
