import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const String _messagesKey = 'chat_messages';
  static const String _lastActivityKey = 'last_activity';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveMessages(List<Message> messages) async {
    final messagesJson = messages.map((m) => m.toJson()).toList();
    await _prefs?.setString(_messagesKey, jsonEncode(messagesJson));
    await _updateLastActivity();
  }

  static Future<List<Message>> loadMessages() async {
    final messagesString = _prefs?.getString(_messagesKey);
    if (messagesString == null) return [];

    try {
      final messagesList = jsonDecode(messagesString) as List;
      return messagesList.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearMessages() async {
    await _prefs?.remove(_messagesKey);
    await _prefs?.remove(_lastActivityKey);
  }

  static Future<void> _updateLastActivity() async {
    await _prefs?.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> shouldResetConversation() async {
    final lastActivity = _prefs?.getInt(_lastActivityKey);
    if (lastActivity == null) return false;

    final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
    final hoursSinceLastActivity = DateTime.now().difference(lastActivityTime).inHours;
    
    return hoursSinceLastActivity >= 1;
  }
}
