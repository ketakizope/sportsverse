// lib/widgets/ai_bot_sheet.dart
//
// AIBotSheet — Premium Elite Curator chatbot bottom sheet.
// Role-aware quick-action chips, animated typing indicator,
// copy-on-long-press, session-expired redirect, and rate-limit guard.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/models/chat_message.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'package:sportsverse_app/providers/chatbot_provider.dart';
import 'package:sportsverse_app/theme/elite_theme.dart';

// ── Quick-action chip definitions ─────────────────────────────────────────────

const _adminChips = [
  '📊 Dashboard summary',
  '💰 Show unpaid fees',
  '📋 Active enrollments',
  '👥 Students in a batch',
];

const _coachChips = [
  '📅 My schedule today',
  '✅ Attendance today',
  '👥 My batch students',
];

const _studentChips = [
  '📅 Sessions attended',
  '💳 My fee status',
  '⏰ Next class time',
  '📊 Sessions remaining',
];

List<String> _chipsForRole(String role) {
  switch (role) {
    case 'ACADEMY_ADMIN':
      return _adminChips;
    case 'COACH':
      return _coachChips;
    case 'STUDENT':
      return _studentChips;
    default:
      return [];
  }
}

String _subtitleForRole(String role) {
  switch (role) {
    case 'ACADEMY_ADMIN':
      return 'Academy Admin Assistant';
    case 'COACH':
      return 'Coach Assistant';
    case 'STUDENT':
      return 'Student Assistant';
    default:
      return 'SportsVerse Assistant';
  }
}

// ── Main widget ───────────────────────────────────────────────────────────────

class AIBotSheet extends StatefulWidget {
  const AIBotSheet({super.key});

  @override
  State<AIBotSheet> createState() => _AIBotSheetState();
}

class _AIBotSheetState extends State<AIBotSheet> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _dotController;
  late List<Animation<double>> _dotAnimations;

  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();

    // Initialise the provider with the current user context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ChatbotProvider>().initialize(auth);
    });

    // 3-dot typing animation — staggered
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotAnimations = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _dotController,
          curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatbotProvider>().sendMessage(text).then((_) {
      _scrollToBottom();
      _checkSessionExpired();
    });
    _scrollToBottom();
  }

  void _sendChip(String chip) {
    // Strip the emoji prefix (e.g., "📊 Dashboard summary" → "Dashboard summary")
    final clean = chip.replaceAll(RegExp(r'^[\p{Emoji}\s]+', unicode: true), '').trim();
    _controller.text = clean;
    _send();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkSessionExpired() {
    final provider = context.read<ChatbotProvider>();
    if (provider.sessionExpired) {
      provider.clearError();
      if (mounted) {
        _showSessionExpiredDialog();
      }
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your login session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // close bottom sheet
              // Clear provider state and redirect to login
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            child: const Text('Log In Again'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = EliteTheme.of(context);
    final provider = context.watch<ChatbotProvider>();
    final role = provider.userRole;
    final chips = _chipsForRole(role);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.surfaceContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Bot avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.smart_toy_rounded, color: theme.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SportsVerse AI', style: theme.heading),
                        Text(
                          _subtitleForRole(role),
                          style: theme.caption.copyWith(color: theme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  // Clear button
                  if (provider.messages.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear chat',
                      icon: Icon(Icons.delete_outline, color: theme.secondaryText, size: 20),
                      onPressed: () => provider.clearMessages(),
                    ),
                  // Close
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: theme.secondaryText, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Divider(height: 24, color: theme.surfaceContainer),

            // ── Quick-action chips ───────────────────────────────────────────
            if (chips.isNotEmpty) ...[
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _QuickChip(
                    label: chips[i],
                    theme: theme,
                    onTap: () => _sendChip(chips[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Error banner ─────────────────────────────────────────────────
            if (provider.error != null)
              _ErrorBanner(
                message: provider.error!,
                theme: theme,
                onDismiss: () => provider.clearError(),
              ),

            // ── Message list ─────────────────────────────────────────────────
            Expanded(
              child: provider.messages.isEmpty
                  ? _EmptyState(theme: theme, role: role)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.messages.length) {
                          // Typing indicator
                          return _TypingIndicator(
                            dotAnimations: _dotAnimations,
                            theme: theme,
                          );
                        }
                        final msg = provider.messages[index];
                        return _MessageBubble(
                          message: msg,
                          theme: theme,
                        );
                      },
                    ),
            ),

            // ── Rate limit notice ────────────────────────────────────────────
            if (provider.isRateLimited)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Session limit reached (20 messages). Close and reopen to continue.',
                  textAlign: TextAlign.center,
                  style: theme.caption.copyWith(color: theme.secondaryText),
                ),
              ),

            // ── Input bar ────────────────────────────────────────────────────
            _InputBar(
              controller: _controller,
              theme: theme,
              isLoading: provider.isLoading,
              isDisabled: provider.isRateLimited,
              onSend: _send,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Quick Chip ────────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final EliteTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: theme.caption.copyWith(
            color: theme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.theme});

  final ChatMessage message;
  final EliteTheme theme;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bot avatar for assistant messages
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.smart_toy_rounded, color: theme.accent, size: 14),
                ),
                const SizedBox(width: 8),
              ],

              // Bubble
              Flexible(
                child: GestureDetector(
                  onLongPress: isUser
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: theme.primary,
                            ),
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? theme.primary : theme.surfaceContainerLowest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: theme.body.copyWith(
                        color: isUser ? theme.surfaceContainerLowest : theme.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 36,
              right: isUser ? 0 : 0,
            ),
            child: Text(
              timeStr,
              style: theme.caption.copyWith(
                color: theme.secondaryText,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({
    required this.dotAnimations,
    required this.theme,
  });

  final List<Animation<double>> dotAnimations;
  final EliteTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.smart_toy_rounded, color: theme.accent, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: dotAnimations[i],
                  builder: (_, __) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(
                          alpha: 0.3 + dotAnimations[i].value * 0.7,
                        ),
                        shape: BoxShape.circle,
                      ),
                      transform: Matrix4.translationValues(
                        0,
                        -4 * dotAnimations[i].value,
                        0,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.theme,
    required this.isLoading,
    required this.isDisabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final EliteTheme theme;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDisabled
                    ? theme.surfaceContainer
                    : theme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDisabled
                      ? theme.surfaceContainer
                      : theme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: !isDisabled && !isLoading,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: theme.body.copyWith(color: theme.primary),
                decoration: InputDecoration(
                  hintText: isDisabled
                      ? 'Session limit reached'
                      : 'Ask me anything…',
                  hintStyle: theme.body.copyWith(color: theme.secondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDisabled || isLoading
                  ? theme.surfaceContainer
                  : theme.primary,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.accent,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.send_rounded,
                      color: isDisabled ? theme.secondaryText : theme.accent,
                      size: 20,
                    ),
                    onPressed: isDisabled ? null : onSend,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.theme,
    required this.onDismiss,
  });

  final String message;
  final EliteTheme theme;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.errorBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.errorBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.caption.copyWith(color: theme.error),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, color: theme.error, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.role});

  final EliteTheme theme;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, color: theme.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Hi! I\'m your SportsVerse assistant.',
              style: theme.heading.copyWith(color: theme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _hintForRole(role),
              style: theme.body.copyWith(color: theme.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _hintForRole(String role) {
    switch (role) {
      case 'ACADEMY_ADMIN':
        return 'Ask me about students, fees, batches, or your academy summary.';
      case 'COACH':
        return 'Ask me about your schedule, students, or today\'s attendance.';
      case 'STUDENT':
        return 'Ask me about your attendance, fees, or upcoming classes.';
      default:
        return 'Tap a chip above or type a question to get started.';
    }
  }
}