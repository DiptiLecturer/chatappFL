import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'private_chat_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");

  void logout() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout")),
          ],
        ));
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: usersRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No users found"));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final users = data.entries
              .where((e) => e.key != currentUser!.uid)
              .map((e) => Map<String, dynamic>.from(e.value))
              .toList();

          if (users.isEmpty) return const Center(child: Text("No friends found"));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user['username']),
                subtitle: Text(user['email']),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PrivateChatPage(
                            currentUserId: currentUser!.uid,
                            friendId: user['uid'],
                            friendName: user['username'],
                          )));
                },
              );
            },
          );
        },
      ),
    );
  }
}
