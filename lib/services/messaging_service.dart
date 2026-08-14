import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  static final _supabase = Supabase.instance.client;

  /// Finds an existing conversation between the two users, or creates one.
  static Future<String> getOrCreateConversation({
    required String otherUserId,
    String? maintenanceRequestId,
  }) async {
    final myId = _supabase.auth.currentUser!.id;

    final existing = await _supabase
        .from('conversations')
        .select('id')
        .or(
          'and(participant_one_id.eq.$myId,participant_two_id.eq.$otherUserId),'
          'and(participant_one_id.eq.$otherUserId,participant_two_id.eq.$myId)',
        )
        .maybeSingle();

    if (existing != null) return existing['id'];

    final created = await _supabase
        .from('conversations')
        .insert({
          'participant_one_id': myId,
          'participant_two_id': otherUserId,
          'maintenance_request_id': maintenanceRequestId,
        })
        .select('id')
        .single();

    return created['id'];
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final myId = _supabase.auth.currentUser!.id;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'content': content,
    });

    await _supabase
        .from('conversations')
        .update({
          'last_message': content,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }
}
