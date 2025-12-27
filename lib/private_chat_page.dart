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
  late final DatabaseReference chatRef;

  @override
  void initState() {
    super.initState();
    final chatId = widget.currentUserId.compareTo(widget.friendId) < 0
        ? '${widget.currentUserId}_${widget.friendId}'
        : '${widget.friendId}_${widget.currentUserId}';
    chatRef = FirebaseDatabase.instance.ref('chats/$chatId/messages');
  }

  void sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    chatRef.push().set({
      'sender': widget.currentUserId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: chatRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet"));
                }

                final messagesMap =
                Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final messages = messagesMap.entries
                    .map((e) => Map<String, dynamic>.from(e.value))
                    .toList()
                  ..sort((a, b) => (a['timestamp'] as int)
                      .compareTo(b['timestamp'] as int));

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender'] == widget.currentUserId;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                    const InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send, color: Colors.blueAccent))
              ],
            ),
          )
        ],
      ),
    );
  }
}
