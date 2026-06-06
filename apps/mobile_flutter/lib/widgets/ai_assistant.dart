import 'package:flutter/material.dart';

import '../models/detective_insight.dart';
import '../services/api_service.dart';
import '../services/detective_service.dart';

const _bg = Color(0xFF070B13);
const _surface = Color(0xFF0F1624);
const _surfaceAlt = Color(0xFF121B2C);
const _border = Color(0xFF243047);
const _primaryText = Color(0xFFF5F7FB);
const _secondaryText = Color(0xFF94A3B8);
const _accent = Color(0xFF5B8DEF);
const _violet = Color(0xFF8B5CF6);

/// Floating "chat head" that opens the AI health assistant.
class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAiAssistant(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [_accent, _violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
      ),
    );
  }
}

Future<void> showAiAssistant(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AiAssistantSheet(),
  );
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool loading;
  _ChatMessage(this.text, {this.isUser = false, this.loading = false});
}

class _AiAssistantSheet extends StatefulWidget {
  const _AiAssistantSheet();

  @override
  State<_AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<_AiAssistantSheet> {
  final DetectiveService _detective = DetectiveService();
  final ApiService _api = ApiService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      "Hi! I'm your health assistant. Here's a quick read on your week — "
      'ask me anything about your sleep, activity, or vitals.',
    ),
  ];
  bool _sending = false;

  static const _suggestions = [
    'How was my sleep this week?',
    'How active have I been?',
    'Any concerning trends?',
  ];

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInsight() async {
    setState(() => _messages.add(_ChatMessage('', loading: true)));
    _scrollToBottom();
    try {
      final userId = await _api.ensureActiveUserId();
      String text;
      if (userId == null) {
        text = 'Sign in to see your personalized insight.';
      } else {
        final DetectiveInsight insight =
            await _detective.generateInsight(userId: userId, daysBack: 7);
        text = insight.isValid
            ? '${insight.title}\n\n${insight.description}\n\n💡 ${insight.finding}'
            : 'Log a bit more health data and I can spot patterns for you.';
      }
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.loading);
          _messages.add(_ChatMessage(text));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.loading));
      }
    } finally {
      _scrollToBottom();
    }
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(_ChatMessage(question, isUser: true));
      _messages.add(_ChatMessage('', loading: true));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();
    try {
      final userId = await _api.ensureActiveUserId();
      final answer = userId == null
          ? 'Please sign in to ask about your health data.'
          : await _detective.askQuestion(userId: userId, question: question);
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.loading);
          _messages.add(_ChatMessage(answer));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.loading);
          _messages
              .add(_ChatMessage("Sorry, I couldn't answer that right now."));
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.82;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: _border),
            left: BorderSide(color: _border),
            right: BorderSide(color: _border),
          ),
        ),
        child: Column(
          children: [
            _header(),
            Expanded(child: _messageList()),
            if (_messages.where((m) => m.isUser).isEmpty) _suggestionsRow(),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_accent, _violet]),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health AI',
                    style: TextStyle(
                        color: _primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text('Powered by Claude',
                    style: TextStyle(color: _secondaryText, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _secondaryText),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(_ChatMessage m) {
    if (m.loading) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
          ),
        ),
      );
    }
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: m.isUser ? _accent : _surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isUser ? 16 : 4),
            bottomRight: Radius.circular(m.isUser ? 4 : 16),
          ),
          border: m.isUser ? null : Border.all(color: _border),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.isUser ? Colors.white : _primaryText,
            height: 1.35,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _suggestionsRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _send(s),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child:
                  Text(s, style: const TextStyle(color: _accent, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                style: const TextStyle(color: _primaryText),
                decoration: InputDecoration(
                  hintText: 'Ask about your health…',
                  hintStyle: const TextStyle(color: _secondaryText),
                  filled: true,
                  fillColor: _surface,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : () => _send(_controller.text),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_accent, _violet]),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
