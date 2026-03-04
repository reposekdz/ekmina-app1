import 'package:flutter/material.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: Center(
        child: Text('Group ID: $groupId'),
      ),
    );
  }
}
