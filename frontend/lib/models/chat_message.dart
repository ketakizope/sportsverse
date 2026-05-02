// lib/models/chat_message.dart
//
// Immutable chat message model for the SportsVerse AI chatbot.
// Supports JSON serialisation for shared_preferences persistence.

import 'package:flutter/foundation.dart';

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => role == ChatRole.user;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience constructors
  factory ChatMessage.fromUser(String text) => ChatMessage(
        role: ChatRole.user,
        text: text,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.fromAssistant(String text) => ChatMessage(
        role: ChatRole.assistant,
        text: text,
        timestamp: DateTime.now(),
      );
}
