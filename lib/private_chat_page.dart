import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PrivateChatPage extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const PrivateChatPage({
    super.key,
    required this.currentUserId,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DatabaseReference chatRef;
  late final DatabaseReference typingRef;
  Timer? _typingTimer;

  final List<String> availableReactions = ['❤️', '😂', '👍', '😮', '😢', '👏'];
  bool isFriendTyping = false;

  @override
  void initState() {
    super.initState();
    final chatId = widget.currentUserId.compareTo(widget.friendId) < 0
        ? '${widget.currentUserId}_${widget.friendId}'
        : '${widget.friendId}_${widget.currentUserId}';
    chatRef = FirebaseDatabase.instance.ref('chats/$chatId/messages');

    typingRef = FirebaseDatabase.instance.ref('typingStatus/$chatId');
    typingRef.child(widget.friendId).onValue.listen((event) {
      setState(() {
        isFriendTyping = (event.snapshot.value ?? false) as bool;
      });
    });
  }

  void sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    chatRef.push().set({
      'sender': widget.currentUserId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'reactions': [],
    });

    _messageController.clear();
    setTyping(false);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void toggleReaction(String messageId, List<dynamic> reactions, String reaction) {
    List<dynamic> updatedReactions = List.from(reactions);
    if (updatedReactions.contains(reaction)) {
      updatedReactions.remove(reaction);
    } else {
      updatedReactions.add(reaction);
    }
    chatRef.child(messageId).update({'reactions': updatedReactions});
  }

  void showReactionPicker(String messageId, List<dynamic> reactions) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: availableReactions.map((reaction) {
                final isSelected = reactions.contains(reaction);
                return GestureDetector(
                  onTap: () {
                    toggleReaction(messageId, reactions, reaction);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.green[200] : Colors.green[50],
                    ),
                    child: Text(
                      reaction,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void setTyping(bool typing) {
    typingRef.child(widget.currentUserId).set(typing);
  }

  void onMessageChanged(String text) {
    setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      setTyping(false);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    setTyping(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.friendName),
            if (isFriendTyping)
              const Text(
                "Typing...",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<DatabaseEvent>(
        stream: chatRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No messages yet"));
          }

          final messagesMap =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final messages = messagesMap.entries
              .map((e) {
            final data = Map<String, dynamic>.from(e.value);
            data['id'] = e.key;
            data['reactions'] = data['reactions'] ?? [];
            return data;
          })
              .toList()
            ..sort((a, b) =>
                (a['timestamp'] as int).compareTo(b['timestamp'] as int));

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[messages.length - 1 - index];
              final isMe = msg['sender'] == widget.currentUserId;
              final reactions = List<dynamic>.from(msg['reactions']);

              return GestureDetector(
                onLongPress: () => showReactionPicker(msg['id'], reactions),
                child: Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[700] : Colors.green[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (reactions.isNotEmpty || msg['timestamp'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (reactions.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    children: reactions
                                        .map((r) => Text(
                                      r,
                                      style: const TextStyle(fontSize: 18),
                                    ))
                                        .toList(),
                                  ),
                                if (reactions.isNotEmpty) const SizedBox(width: 6),
                                Text(
                                  formatTimestamp(msg['timestamp']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                    isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            color: Colors.green[100],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: onMessageChanged,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
