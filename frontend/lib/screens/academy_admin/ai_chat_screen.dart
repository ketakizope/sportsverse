// lib/screens/academy_admin/ai_chat_screen.dart
//
// Legacy screen stub — redirects to the new AIBotSheet bottom sheet.
// This file is kept for backwards compatibility in case it is referenced
// from old navigation routes; direct users to the new chatbot sheet.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'package:sportsverse_app/providers/chatbot_provider.dart';
import 'package:sportsverse_app/widgets/ai_bot_sheet.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately open the new chatbot sheet and pop this route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ChatbotProvider>().initialize(auth);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => const AIBotSheet(),
      ).then((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}