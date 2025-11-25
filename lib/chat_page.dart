import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatPage extends StatefulWidget {
  final User user;
  ChatPage({required this.user});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final dbRef = FirebaseDatabase.instance.ref("messages");
  final _controller = TextEditingController();

  void sendMessage(String msg) {
    if (msg.trim().isEmpty) return;
    dbRef.push().set({
      'sender': widget.user.email,
      'message': msg,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: dbRef.orderByChild("timestamp").onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = (snapshot.data as DatabaseEvent).snapshot.value as Map?;
                if (messages == null) return Center(child: Text("No messages"));
                final msgList = messages.entries.toList();
                return ListView.builder(
                  itemCount: msgList.length,
                  itemBuilder: (context, index) {
                    final m = msgList[index].value as Map;
                    return ListTile(
                      title: Text(m['message']),
                      subtitle: Text(m['sender']),
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
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
