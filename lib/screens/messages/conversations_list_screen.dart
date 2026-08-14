import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final myId = supabase.auth.currentUser!.id;

      final result = await supabase
          .from('conversations')
          .select(
            '*, '
            'p1:profiles!conversations_participant_one_id_fkey(id, full_name), '
            'p2:profiles!conversations_participant_two_id_fkey(id, full_name)',
          )
          .or('participant_one_id.eq.$myId,participant_two_id.eq.$myId')
          .order('last_message_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load messages: $e')),
      );
    }
  }

  Map<String, dynamic>? _otherParty(Map<String, dynamic> conversation) {
    final myId = supabase.auth.currentUser!.id;
    final p1 = conversation['p1'];
    final p2 = conversation['p2'];
    if (p1 == null || p2 == null) return null;
    return p1['id'] == myId ? p2 : p1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _conversations.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No conversations yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, i) {
                        final conversation = _conversations[i];
                        final other = _otherParty(conversation);

                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(other?['full_name'] ?? 'Unknown'),
                          subtitle: Text(
                            conversation['last_message'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: conversation['last_message_at'] != null
                              ? Text(
                                  DateFormat('MMM d').format(
                                    DateTime.parse(conversation['last_message_at']),
                                  ),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                )
                              : null,
                          onTap: () {
                            context.push('/chat', extra: {
                              'conversationId': conversation['id'],
                              'otherPartyName': other?['full_name'] ?? 'Unknown',
                            });
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
