import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      final userId = await storage.getUserId();
      if (userId == null) return;

      final api = ref.read(apiClientProvider);
      // Assuming a generic endpoint or combining from other modules
      final response = await api.get('/documents', queryParameters: {'userId': userId});

      if (mounted) {
        setState(() {
          _documents = response.data['documents'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        // Fallback or error handling
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inyandiko n\'Impapuro', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Byose'),
            Tab(text: 'Imisanzu'),
            Tab(text: 'Inguzanyo'),
            Tab(text: 'Raporo'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDocuments),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList('ALL'),
                _buildList('RECEIPT'),
                _buildList('LOAN'),
                _buildList('REPORT'),
              ],
            ),
    );
  }

  Widget _buildList(String filterType) {
    final filtered = filterType == 'ALL'
        ? _documents
        : _documents.where((d) => d['type'] == filterType).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Nta nyandiko zabonetse', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildDocumentCard(filtered[index]),
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    final type = doc['type'] as String?;
    IconData icon;
    Color color;

    switch (type) {
      case 'RECEIPT': icon = Icons.receipt_long; color = Colors.green; break;
      case 'LOAN': icon = Icons.request_quote; color = Colors.orange; break;
      case 'REPORT': icon = Icons.analytics; color = Colors.blue; break;
      default: icon = Icons.description; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => _viewDocument(doc),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(doc['title'] ?? 'Inyandiko', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(Formatters.formatDate(DateTime.parse(doc['createdAt'])),
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.share_outlined, size: 20),
          onPressed: () => Share.share(doc['url'] ?? 'E-Kimina Document'),
        ),
      ),
    );
  }

  void _viewDocument(dynamic doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(doc['title'] ?? 'Inyandiko', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[100],
                width: double.infinity,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('PDF Preview is loading...'),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Kuramo'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Share.share(doc['url'] ?? ''),
                      icon: const Icon(Icons.share),
                      label: const Text('Sangiza'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
