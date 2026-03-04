import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/kyc_status_badge.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  
  String _searchType = 'all'; // all, groups, users, transactions
  List<dynamic> _results = [];
  bool _isSearching = false;
  bool _showFilters = false;
  
  // Filters
  String _groupType = 'all'; // all, public, private
  String _transactionType = 'all'; // all, deposit, withdrawal, transfer
  DateTimeRange? _dateRange;
  RangeValues _amountRange = const RangeValues(0, 5000000);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _searchType = ['all', 'groups', 'users', 'transactions'][_tabController.index];
          _results = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/search', {
        'query': query,
        'type': _searchType,
        'filters': {
          'groupType': _groupType,
          'transactionType': _transactionType,
          'dateRange': _dateRange != null ? {
            'start': _dateRange!.start.toIso8601String(),
            'end': _dateRange!.end.toIso8601String(),
          } : null,
          'amountRange': {
            'min': _amountRange.start,
            'max': _amountRange.end,
          },
        },
      });

      if (mounted) {
        setState(() {
          _results = response['results'] ?? [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shakisha'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Byose'),
            Tab(icon: Icon(Icons.groups), text: 'Amatsinda'),
            Tab(icon: Icon(Icons.people), text: 'Abantu'),
            Tab(icon: Icon(Icons.receipt), text: 'Ibikorwa'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFilters(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _getSearchHint(),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00A86B)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _results = []);
                      },
                    ),
                  IconButton(
                    icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _performSearch(value);
              } else if (value.isEmpty) {
                setState(() => _results = []);
              }
            },
          ),
          const SizedBox(height: 8),
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_searchType == 'groups') ...[
            _buildFilterChip('Byose', _groupType == 'all', () => setState(() => _groupType = 'all')),
            _buildFilterChip('Rusange', _groupType == 'public', () => setState(() => _groupType = 'public')),
            _buildFilterChip('Byihariye', _groupType == 'private', () => setState(() => _groupType = 'private')),
          ],
          if (_searchType == 'transactions') ...[
            _buildFilterChip('Byose', _transactionType == 'all', () => setState(() => _transactionType = 'all')),
            _buildFilterChip('Kwinjiza', _transactionType == 'deposit', () => setState(() => _transactionType = 'deposit')),
            _buildFilterChip('Gusohora', _transactionType == 'withdrawal', () => setState(() => _transactionType = 'withdrawal')),
            _buildFilterChip('Kohereza', _transactionType == 'transfer', () => setState(() => _transactionType = 'transfer')),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          onTap();
          if (_searchController.text.isNotEmpty) _performSearch(_searchController.text);
        },
        selectedColor: const Color(0xFF00A86B).withOpacity(0.2),
        checkmarkColor: const Color(0xFF00A86B),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          if (_searchType == 'transactions') ...[
            const Text('Amafaranga', style: TextStyle(fontSize: 14)),
            RangeSlider(
              values: _amountRange,
              min: 0,
              max: 5000000,
              divisions: 100,
              labels: RangeLabels(
                Formatters.formatCurrency(_amountRange.start),
                Formatters.formatCurrency(_amountRange.end),
              ),
              onChanged: (values) => setState(() => _amountRange = values),
              onChangeEnd: (values) {
                if (_searchController.text.isNotEmpty) _performSearch(_searchController.text);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Formatters.formatCurrency(_amountRange.start), style: const TextStyle(fontSize: 12)),
                Text(Formatters.formatCurrency(_amountRange.end), style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateRange,
                );
                if (picked != null) {
                  setState(() => _dateRange = picked);
                  if (_searchController.text.isNotEmpty) _performSearch(_searchController.text);
                }
              },
              icon: const Icon(Icons.date_range),
              label: Text(_dateRange == null ? 'Hitamo itariki' : '${Formatters.formatDate(_dateRange!.start)} - ${Formatters.formatDate(_dateRange!.end)}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Tangira gushakisha', 'Andika ijambo ushaka gushakisha');
    }

    if (_results.isEmpty) {
      return _buildEmptyState('Nta bisubizo', 'Nta kintu cyabonetse');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final type = result['type'] ?? _searchType;
        
        switch (type) {
          case 'group':
            return _buildGroupResult(result);
          case 'user':
            return _buildUserResult(result);
          case 'transaction':
            return TransactionCard(transaction: result);
          default:
            return _buildGenericResult(result);
        }
      },
    );
  }

  Widget _buildGroupResult(Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
          child: const Icon(Icons.groups, color: Color(0xFF00A86B)),
        ),
        title: Text(group['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${group['memberCount'] ?? 0} abanyamuryango'),
            if (group['isPublic'] == true)
              const Text('Rusange', style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Navigate to group details
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
          child: const Text('Reba'),
        ),
      ),
    );
  }

  Widget _buildUserResult(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
          child: user['photoUrl'] == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['phone'] ?? ''),
            if (user['kycStatus'] != null)
              KYCStatusBadge(status: user['kycStatus'], showLabel: true),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // Navigate to user profile
          },
        ),
      ),
    );
  }

  Widget _buildGenericResult(Map<String, dynamic> result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(result['title'] ?? ''),
        subtitle: Text(result['description'] ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Handle tap
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'groups':
        return 'Shakisha amatsinda...';
      case 'users':
        return 'Shakisha abantu...';
      case 'transactions':
        return 'Shakisha ibikorwa...';
      default:
        return 'Shakisha...';
    }
  }
}
