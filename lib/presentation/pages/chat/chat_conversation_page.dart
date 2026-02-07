import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/chat.dart';
import '../../widgets/pressable_scale.dart';

class ChatConversationPage extends StatefulWidget {
  final ChatThread thread;

  const ChatConversationPage({super.key, required this.thread});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _inputController = TextEditingController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(widget.thread.messages);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(thread: widget.thread),
            Expanded(
              child: Container(
                color: const Color(0xFFEAF1FF),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
              ),
            ),
            _Composer(controller: _inputController, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          fromMe: true,
          sentAt: DateTime.now(),
          seen: true,
        ),
      );
      _inputController.clear();
    });
  }
}

class _ChatHeader extends StatelessWidget {
  final ChatThread thread;

  const _ChatHeader({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(thread.avatarPath),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'last seen just now',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final align = message.fromMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.fromMe ? const Color(0xFFCEF6B8) : Colors.white;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _timeLabel(message.sentAt),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file)),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Message',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onSend,
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.send, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
