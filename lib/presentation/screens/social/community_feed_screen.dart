import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/remote/api_client.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _postController = TextEditingController();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, my_groups, trending

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/community/posts?filter=$_filter');
      if (mounted) {
        setState(() {
          _posts = response['posts'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.post('/community/posts', {'content': _postController.text});
      _postController.clear();
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubutumwa bwoherejwe!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _likePost(String postId, bool isLiked) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/community/posts/$postId/${isLiked ? 'unlike' : 'like'}', {});
      _loadPosts();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _commentOnPost(String postId, String comment) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/community/posts/$postId/comments', {'content': comment});
      _loadPosts();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umuryango'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          _buildCreatePost(),
          Expanded(child: _buildPostsList()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Byose', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Amatsinda yanjye', 'my_groups'),
          const SizedBox(width: 8),
          _buildFilterChip('Trending', 'trending'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filter = value);
        _loadPosts();
      },
      selectedColor: const Color(0xFF00A86B).withOpacity(0.2),
      checkmarkColor: const Color(0xFF00A86B),
    );
  }

  Widget _buildCreatePost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: 'Andika ikintu...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF00A86B)),
            onPressed: _createPost,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Nta butumwa', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) => _buildPostCard(_posts[index]),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final author = post['author'] ?? {};
    final likesCount = post['likesCount'] ?? 0;
    final commentsCount = post['commentsCount'] ?? 0;
    final isLiked = post['isLiked'] ?? false;
    final timestamp = post['createdAt'] != null ? DateTime.parse(post['createdAt']) : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: author['photoUrl'] != null ? NetworkImage(author['photoUrl']) : null,
              child: author['photoUrl'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(author['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_formatTimestamp(timestamp)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPostOptions(post),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(post['content'] ?? '', style: const TextStyle(fontSize: 15)),
          ),
          if (post['imageUrl'] != null)
            Image.network(post['imageUrl'], fit: BoxFit.cover, width: double.infinity),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                  onPressed: () => _likePost(post['id'], isLiked),
                ),
                Text('$likesCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () => _showComments(post),
                ),
                Text('$commentsCount'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _sharePost(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Menyesha'),
            onTap: () {
              Navigator.pop(context);
              // Report post
            },
          ),
          if (post['isOwner'] == true)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Siba', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Delete post
              },
            ),
        ],
      ),
    );
  }

  void _showComments(Map<String, dynamic> post) {
    final commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Ibisobanuro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: (post['comments'] as List?)?.length ?? 0,
                itemBuilder: (context, index) {
                  final comment = post['comments'][index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(comment['author']['name'] ?? ''),
                    subtitle: Text(comment['content'] ?? ''),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Andika igitekerezo...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF00A86B)),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        _commentOnPost(post['id'], commentController.text);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    // Implement share functionality
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Ubu';
    if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return DateFormat('MMM dd').format(timestamp);
  }
}
