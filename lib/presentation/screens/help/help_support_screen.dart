import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {'q': 'Nigute nkora ikimina?', 'a': 'Kanda kuri "Kora itsinda" hanyuma uzuza amakuru yose akenewe. Uzishyura 2,000 RWF kugirango ukomeze.'},
    {'q': 'Nigute nsaba inguzanyo?', 'a': 'Injira mu kimina, kanda kuri "Inguzanyo" hanyuma uzuza amafaranga ukeneye n\'impamvu. Uzakenera abamenyesha 2-3.'},
    {'q': 'Nigute nshyira amafaranga?', 'a': 'Kanda kuri "Wallet" hanyuma uhitemo "Shyiramo". Hitamo uburyo bwo kwishyura (MTN/Airtel) hanyuma ukomeze.'},
    {'q': 'Ibihano bigenda bite?', 'a': 'Niba utishyuye ku gihe, uzahabwa igihano nk\'uko byateganijwe n\'ikimina. Ibihano bishobora kuba amafaranga cyangwa ijanisha.'},
    {'q': 'Nigute ninjira mu kimina?', 'a': 'Shakisha ikimina mu matsinda rusange cyangwa ukoreshe code y\'ubutumire. Uzishyura amafaranga yo kwinjira niba ari ngombwa.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubufasha & Inkunga')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildFAQSection(),
          const SizedBox(height: 24),
          _buildContactSection(),
          const SizedBox(height: 24),
          _buildResourcesSection(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ibikorwa byihuse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionButton(Icons.chat, 'Chat', Colors.blue, _openChat)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton(Icons.call, 'Hamagara', Colors.green, _makeCall)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionButton(Icons.email, 'Email', Colors.orange, _sendEmail)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton(Icons.bug_report, 'Raporo', Colors.red, _reportBug)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ibibazo bikunze kubazwa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._faqs.map((faq) => _buildFAQItem(faq['q']!, faq['a']!)),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Twandikire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildContactItem(Icons.phone, '+250 788 123 456', _makeCall),
            _buildContactItem(Icons.email, 'support@ekimina.rw', _sendEmail),
            _buildContactItem(Icons.language, 'www.ekimina.rw', _openWebsite),
            _buildContactItem(Icons.location_on, 'Kigali, Rwanda', _openMap),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF00A86B)),
      ),
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildResourcesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ibindi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.video_library, color: Color(0xFF00A86B)),
              title: const Text('Video tutorials'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Color(0xFF00A86B)),
              title: const Text('Amabwiriza'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.forum, color: Color(0xFF00A86B)),
              title: const Text('Umuryango'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Chat na support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    ListTile(
                      leading: CircleAvatar(child: Icon(Icons.support_agent)),
                      title: Text('Support Team'),
                      subtitle: Text('Mwaramutse! Dufite iki twabafasha?'),
                    ),
                  ],
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Andika ubutumwa...',
                  suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {}),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makeCall() async {
    final uri = Uri.parse('tel:+250788123456');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendEmail() async {
    final uri = Uri.parse('mailto:support@ekimina.rw');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWebsite() async {
    final uri = Uri.parse('https://www.ekimina.rw');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openMap() async {
    final uri = Uri.parse('https://maps.google.com/?q=Kigali,Rwanda');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menyesha ikibazo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Umutwe', hintText: 'Sobanura ikibazo mu magambo make'),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Ibisobanuro', hintText: 'Sobanura ikibazo mu buryo burambuye'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Raporo yoherejwe! Tuzakugarukaho vuba.')),
              );
            },
            child: const Text('Ohereza'),
          ),
        ],
      ),
    );
  }
}
